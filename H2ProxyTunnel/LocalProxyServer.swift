import Foundation
import Network

class LocalProxyServer {
    private let listenPort: UInt16
    private let remoteHost: String
    private let remotePort: UInt16
    private let proto: ProxyProtocol
    private let username: String?
    private let password: String?
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.h2proxy.localproxy", qos: .userInitiated)
    private var connections: [UUID: ClientConnection] = []
    var onBytesTransferred: ((Int64, Int64) -> Void)?

    init(listenPort: UInt16, remoteHost: String, remotePort: UInt16, proto: ProxyProtocol, username: String?, password: String?) {
        self.listenPort = listenPort
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.proto = proto
        self.username = username
        self.password = password
    }

    func start(completion: @escaping (Error?) -> Void) {
        do {
            let params = NWParameters.tcp
            params.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: listenPort)!)
            listener = try NWListener(using: params)
        } catch {
            completion(error)
            return
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                completion(nil)
            case .failed(let error):
                completion(error)
            default:
                break
            }
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener?.start(queue: queue)
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for conn in connections.values {
            conn.cancel()
        }
        connections.removeAll()
    }

    private func handleNewConnection(_ clientConn: NWConnection) {
        let id = UUID()
        let conn = ClientConnection(
            id: id,
            client: clientConn,
            remoteHost: remoteHost,
            remotePort: remotePort,
            proto: proto,
            username: username,
            password: password,
            queue: queue
        )
        conn.onBytesTransferred = { [weak self] up, down in
            self?.onBytesTransferred?(up, down)
        }
        conn.onClose = { [weak self] in
            self?.connections.removeValue(forKey: id)
        }
        connections[id] = conn
        conn.start()
    }
}

class ClientConnection {
    let id: UUID
    private let client: NWConnection
    private var remote: NWConnection?
    private let remoteHost: String
    private let remotePort: UInt16
    private let proto: ProxyProtocol
    private let username: String?
    private let password: String?
    private let queue: DispatchQueue
    private var isCancelled = false
    var onBytesTransferred: ((Int64, Int64) -> Void)?
    var onClose: (() -> Void)?

    init(id: UUID, client: NWConnection, remoteHost: String, remotePort: UInt16,
         proto: ProxyProtocol, username: String?, password: String?, queue: DispatchQueue) {
        self.id = id
        self.client = client
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.proto = proto
        self.username = username
        self.password = password
        self.queue = queue
    }

    func start() {
        client.stateUpdateHandler = { [weak self] state in
            if case .failed = state { self?.cancel() }
        }
        client.start(queue: queue)
        readClientRequest()
    }

    func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        client.cancel()
        remote?.cancel()
        onClose?()
    }

    // MARK: - Read initial HTTP request from system proxy

    private func readClientRequest() {
        client.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, error in
            guard let self = self, !self.isCancelled else { return }
            guard let data = data, !data.isEmpty else {
                self.cancel()
                return
            }
            self.onBytesTransferred?(Int64(data.count), 0)
            self.handleHTTPRequest(data)
        }
    }

    private func handleHTTPRequest(_ data: Data) {
        guard let requestStr = String(data: data, encoding: .utf8) else {
            cancel()
            return
        }

        let lines = requestStr.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else { cancel(); return }
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 3 else { cancel(); return }

        let method = parts[0]
        let target = parts[1]

        if method == "CONNECT" {
            handleCONNECT(target: target, originalRequest: data)
        } else {
            handlePlainHTTP(originalRequest: data, method: method, target: target)
        }
    }

    // MARK: - CONNECT (HTTPS tunneling)

    private func handleCONNECT(target: String, originalRequest: Data) {
        let hostPort = parseHostPort(target, defaultPort: 443)

        connectToRemoteProxy { [weak self] error in
            guard let self = self, error == nil else {
                self?.cancel()
                return
            }

            switch self.proto {
            case .socks5:
                self.socks5Connect(host: hostPort.host, port: hostPort.port) { error in
                    if error != nil { self.cancel(); return }
                    self.sendCONNECTResponse()
                    self.startBidirectionalRelay()
                }
            case .http:
                self.httpCONNECT(host: hostPort.host, port: hostPort.port) { error in
                    if error != nil { self.cancel(); return }
                    self.sendCONNECTResponse()
                    self.startBidirectionalRelay()
                }
            case .h2:
                self.h2Connect(host: hostPort.host, port: hostPort.port) { error in
                    if error != nil { self.cancel(); return }
                    self.sendCONNECTResponse()
                    self.startBidirectionalH2Relay()
                }
            }
        }
    }

    private func sendCONNECTResponse() {
        let response = "HTTP/1.1 200 Connection Established\r\n\r\n"
        client.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in })
    }

    // MARK: - Plain HTTP proxying

    private func handlePlainHTTP(originalRequest: Data, method: String, target: String) {
        var targetHost = remoteHost
        var targetPort = remotePort

        if target.hasPrefix("http://") {
            if let url = URL(string: target) {
                targetHost = url.host ?? remoteHost
                targetPort = UInt16(url.port ?? 80)
            }
        }

        connectToRemoteProxy { [weak self] error in
            guard let self = self, error == nil else {
                self?.cancel()
                return
            }

            switch self.proto {
            case .socks5:
                self.socks5Connect(host: targetHost, port: targetPort) { error in
                    if error != nil { self.cancel(); return }
                    self.sendToRemote(originalRequest)
                    self.startBidirectionalRelay()
                }
            case .http:
                self.sendToRemote(originalRequest)
                self.startBidirectionalRelay()
            case .h2:
                self.h2Connect(host: targetHost, port: targetPort) { error in
                    if error != nil { self.cancel(); return }
                    self.sendH2Data(originalRequest)
                    self.startBidirectionalH2Relay()
                }
            }
        }
    }

    // MARK: - Connect to remote proxy server

    private func connectToRemoteProxy(completion: @escaping (Error?) -> Void) {
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveInterval = 30
        tcpOptions.connectionTimeout = 10

        let params: NWParameters
        if proto == .h2 {
            let tls = NWProtocolTLS.Options()
            sec_protocol_options_add_tls_application_protocol(tls.securityProtocolOptions, "h2")
            params = NWParameters(tls: tls, tcp: tcpOptions)
        } else {
            params = NWParameters(tls: nil, tcp: tcpOptions)
        }

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(remoteHost),
            port: NWEndpoint.Port(rawValue: remotePort)!
        )
        let conn = NWConnection(to: endpoint, using: params)
        self.remote = conn

        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                completion(nil)
            case .failed(let error):
                completion(error)
            default:
                break
            }
        }
        conn.start(queue: queue)
    }

    // MARK: - SOCKS5

    private func socks5Connect(host: String, port: UInt16, completion: @escaping (Error?) -> Void) {
        let hasAuth = username != nil && password != nil

        var greeting = Data([0x05])
        if hasAuth {
            greeting.append(contentsOf: [0x02, 0x00, 0x02])
        } else {
            greeting.append(contentsOf: [0x01, 0x00])
        }

        remote?.send(content: greeting, completion: .contentProcessed { [weak self] error in
            guard error == nil else { completion(error); return }
            self?.remote?.receive(minimumIncompleteLength: 2, maximumLength: 2) { data, _, _, error in
                guard let data = data, data.count == 2, error == nil else {
                    completion(error ?? self?.makeError("SOCKS5 greeting failed"))
                    return
                }
                if data[1] == 0x02, hasAuth {
                    self?.socks5Auth { error in
                        guard error == nil else { completion(error); return }
                        self?.socks5Request(host: host, port: port, completion: completion)
                    }
                } else if data[1] == 0x00 {
                    self?.socks5Request(host: host, port: port, completion: completion)
                } else {
                    completion(self?.makeError("SOCKS5 auth not supported"))
                }
            }
        })
    }

    private func socks5Auth(completion: @escaping (Error?) -> Void) {
        guard let user = username, let pass = password else {
            completion(makeError("No credentials")); return
        }
        var auth = Data([0x01])
        let u = Data(user.utf8)
        auth.append(UInt8(u.count))
        auth.append(u)
        let p = Data(pass.utf8)
        auth.append(UInt8(p.count))
        auth.append(p)

        remote?.send(content: auth, completion: .contentProcessed { [weak self] error in
            guard error == nil else { completion(error); return }
            self?.remote?.receive(minimumIncompleteLength: 2, maximumLength: 2) { data, _, _, error in
                guard let data = data, data.count == 2, data[1] == 0x00 else {
                    completion(self?.makeError("SOCKS5 auth failed"))
                    return
                }
                completion(nil)
            }
        })
    }

    private func socks5Request(host: String, port: UInt16, completion: @escaping (Error?) -> Void) {
        var req = Data([0x05, 0x01, 0x00, 0x03])
        let hostBytes = Data(host.utf8)
        req.append(UInt8(hostBytes.count))
        req.append(hostBytes)
        req.append(UInt8(port >> 8))
        req.append(UInt8(port & 0xFF))

        remote?.send(content: req, completion: .contentProcessed { [weak self] error in
            guard error == nil else { completion(error); return }
            self?.remote?.receive(minimumIncompleteLength: 4, maximumLength: 512) { data, _, _, error in
                guard let data = data, data.count >= 4, error == nil else {
                    completion(error ?? self?.makeError("SOCKS5 connect failed"))
                    return
                }
                if data[1] == 0x00 {
                    completion(nil)
                } else {
                    let codes = ["", "General failure", "Connection not allowed", "Network unreachable",
                                 "Host unreachable", "Connection refused", "TTL expired",
                                 "Command not supported", "Address type not supported"]
                    let code = Int(data[1])
                    let msg = code < codes.count ? codes[code] : "Unknown error \(code)"
                    completion(self?.makeError("SOCKS5: \(msg)"))
                }
            }
        })
    }

    // MARK: - HTTP CONNECT

    private func httpCONNECT(host: String, port: UInt16, completion: @escaping (Error?) -> Void) {
        var request = "CONNECT \(host):\(port) HTTP/1.1\r\nHost: \(host):\(port)\r\n"
        if let user = username, let pass = password {
            let cred = Data("\(user):\(pass)".utf8).base64EncodedString()
            request += "Proxy-Authorization: Basic \(cred)\r\n"
        }
        request += "\r\n"

        remote?.send(content: request.data(using: .utf8), completion: .contentProcessed { [weak self] error in
            guard error == nil else { completion(error); return }
            self?.remote?.receive(minimumIncompleteLength: 12, maximumLength: 4096) { data, _, _, error in
                guard let data = data, error == nil,
                      let response = String(data: data, encoding: .utf8) else {
                    completion(error ?? self?.makeError("HTTP CONNECT failed"))
                    return
                }
                if response.contains("200") {
                    completion(nil)
                } else {
                    completion(self?.makeError("HTTP CONNECT rejected: \(response.prefix(64))"))
                }
            }
        })
    }

    // MARK: - HTTP/2

    private func h2Connect(host: String, port: UInt16, completion: @escaping (Error?) -> Void) {
        let preface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"

        var settingsFrame = Data()
        settingsFrame.append(contentsOf: [0x00, 0x00, 0x00])
        settingsFrame.append(0x04) // SETTINGS
        settingsFrame.append(0x00) // no flags
        settingsFrame.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // stream 0

        var handshake = Data(preface.utf8)
        handshake.append(settingsFrame)

        remote?.send(content: handshake, completion: .contentProcessed { [weak self] error in
            guard error == nil else { completion(error); return }
            self?.remote?.receive(minimumIncompleteLength: 9, maximumLength: 512) { data, _, _, error in
                guard data != nil, error == nil else {
                    completion(error ?? self?.makeError("H2 handshake failed"))
                    return
                }
                // Send SETTINGS ACK
                var ack = Data([0x00, 0x00, 0x00, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00])
                self?.remote?.send(content: ack, completion: .contentProcessed { _ in })
                completion(nil)
            }
        })
    }

    private func sendH2Data(_ data: Data) {
        guard let remote = remote else { return }
        var frame = Data()
        let length = UInt32(data.count)
        frame.append(UInt8((length >> 16) & 0xFF))
        frame.append(UInt8((length >> 8) & 0xFF))
        frame.append(UInt8(length & 0xFF))
        frame.append(0x00) // DATA
        frame.append(0x00) // no flags
        frame.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // stream 1
        frame.append(data)
        remote.send(content: frame, completion: .contentProcessed { _ in })
    }

    // MARK: - Bidirectional relay

    private func startBidirectionalRelay() {
        relayClientToRemote()
        relayRemoteToClient()
    }

    private func relayClientToRemote() {
        guard !isCancelled else { return }
        client.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, !self.isCancelled else { return }
            if let data = data, !data.isEmpty {
                self.onBytesTransferred?(Int64(data.count), 0)
                self.sendToRemote(data)
            }
            if isComplete || error != nil {
                self.remote?.send(content: nil, contentContext: .finalMessage, isComplete: true, completion: .contentProcessed { _ in })
                return
            }
            self.relayClientToRemote()
        }
    }

    private func relayRemoteToClient() {
        guard !isCancelled else { return }
        remote?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, !self.isCancelled else { return }
            if let data = data, !data.isEmpty {
                self.onBytesTransferred?(0, Int64(data.count))
                self.sendToClient(data)
            }
            if isComplete || error != nil {
                self.cancel()
                return
            }
            self.relayRemoteToClient()
        }
    }

    // MARK: - H2 relay

    private func startBidirectionalH2Relay() {
        relayClientToH2Remote()
        relayH2RemoteToClient()
    }

    private func relayClientToH2Remote() {
        guard !isCancelled else { return }
        client.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, !self.isCancelled else { return }
            if let data = data, !data.isEmpty {
                self.onBytesTransferred?(Int64(data.count), 0)
                self.sendH2Data(data)
            }
            if isComplete || error != nil { return }
            self.relayClientToH2Remote()
        }
    }

    private func relayH2RemoteToClient() {
        guard !isCancelled else { return }
        remote?.receive(minimumIncompleteLength: 9, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, !self.isCancelled else { return }
            if let data = data, data.count >= 9 {
                let payload = self.extractH2Payload(data)
                if !payload.isEmpty {
                    self.onBytesTransferred?(0, Int64(payload.count))
                    self.sendToClient(payload)
                }
            }
            if isComplete || error != nil {
                self.cancel()
                return
            }
            self.relayH2RemoteToClient()
        }
    }

    private func extractH2Payload(_ frameData: Data) -> Data {
        guard frameData.count >= 9 else { return Data() }
        let length = (Int(frameData[0]) << 16) | (Int(frameData[1]) << 8) | Int(frameData[2])
        let type = frameData[3]
        // Only extract DATA frames (type 0)
        if type == 0x00 && frameData.count >= 9 + length {
            return frameData.subdata(in: 9..<(9 + length))
        }
        return Data()
    }

    // MARK: - Send helpers

    private func sendToRemote(_ data: Data) {
        remote?.send(content: data, completion: .contentProcessed { [weak self] error in
            if error != nil { self?.cancel() }
        })
    }

    private func sendToClient(_ data: Data) {
        client.send(content: data, completion: .contentProcessed { [weak self] error in
            if error != nil { self?.cancel() }
        })
    }

    private func parseHostPort(_ target: String, defaultPort: UInt16) -> (host: String, port: UInt16) {
        let parts = target.components(separatedBy: ":")
        if parts.count == 2, let p = UInt16(parts[1]) {
            return (parts[0], p)
        }
        return (target, defaultPort)
    }

    private func makeError(_ msg: String) -> NSError {
        NSError(domain: "H2ProxyTunnel", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}
