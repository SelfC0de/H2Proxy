import Foundation
import Network

enum ProxyProtocol: String, Codable, CaseIterable {
    case http = "HTTP/HTTPS"
    case socks5 = "SOCKS5"
    case h2 = "HTTP/2 Tunnel"
}

class ProxyConnection {
    private let host: String
    private let port: UInt16
    private let proto: ProxyProtocol
    private let username: String?
    private let password: String?
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.h2proxy.tunnel.connection")

    init(host: String, port: UInt16, protocol proto: ProxyProtocol, username: String?, password: String?) {
        self.host = host
        self.port = port
        self.proto = proto
        self.username = username
        self.password = password
    }

    func connect(completion: @escaping (Error?) -> Void) {
        let tlsOptions: NWProtocolTLS.Options?
        if proto == .h2 {
            let tls = NWProtocolTLS.Options()
            sec_protocol_options_add_tls_application_protocol(tls.securityProtocolOptions, "h2")
            tlsOptions = tls
        } else {
            tlsOptions = nil
        }

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveInterval = 30

        let params: NWParameters
        if let tls = tlsOptions {
            params = NWParameters(tls: tls, tcp: tcpOptions)
        } else {
            params = NWParameters(tls: nil, tcp: tcpOptions)
        }

        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        connection = NWConnection(to: endpoint, using: params)

        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.performHandshake(completion: completion)
            case .failed(let error):
                completion(error)
            case .cancelled:
                break
            default:
                break
            }
        }

        connection?.start(queue: queue)
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
    }

    func sendPacket(_ data: Data, protocolFamily: NSNumber) {
        guard let connection = connection else { return }

        switch proto {
        case .h2:
            sendH2Frame(data: data, connection: connection)
        case .socks5:
            connection.send(content: data, completion: .contentProcessed { _ in })
        case .http:
            connection.send(content: data, completion: .contentProcessed { _ in })
        }
    }

    // MARK: - Handshake

    private func performHandshake(completion: @escaping (Error?) -> Void) {
        switch proto {
        case .socks5:
            socks5Handshake(completion: completion)
        case .http:
            completion(nil)
        case .h2:
            h2Handshake(completion: completion)
        }
    }

    // MARK: - SOCKS5

    private func socks5Handshake(completion: @escaping (Error?) -> Void) {
        let hasAuth = username != nil && password != nil
        var greeting = Data([0x05]) // VER
        if hasAuth {
            greeting.append(contentsOf: [0x02, 0x00, 0x02]) // 2 methods: no auth + user/pass
        } else {
            greeting.append(contentsOf: [0x01, 0x00]) // 1 method: no auth
        }

        connection?.send(content: greeting, completion: .contentProcessed { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            self?.connection?.receive(minimumIncompleteLength: 2, maximumLength: 2) { data, _, _, error in
                if let error = error {
                    completion(error)
                    return
                }
                guard let data = data, data.count == 2 else {
                    completion(self?.makeError("Invalid SOCKS5 greeting response"))
                    return
                }
                if data[1] == 0x02, hasAuth {
                    self?.socks5Auth(completion: completion)
                } else if data[1] == 0x00 {
                    completion(nil)
                } else {
                    completion(self?.makeError("SOCKS5 auth method not supported"))
                }
            }
        })
    }

    private func socks5Auth(completion: @escaping (Error?) -> Void) {
        guard let user = username, let pass = password else {
            completion(makeError("Credentials required"))
            return
        }
        var auth = Data([0x01])
        let userBytes = Data(user.utf8)
        auth.append(UInt8(userBytes.count))
        auth.append(userBytes)
        let passBytes = Data(pass.utf8)
        auth.append(UInt8(passBytes.count))
        auth.append(passBytes)

        connection?.send(content: auth, completion: .contentProcessed { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            self?.connection?.receive(minimumIncompleteLength: 2, maximumLength: 2) { data, _, _, error in
                if let error = error {
                    completion(error)
                    return
                }
                guard let data = data, data.count == 2, data[1] == 0x00 else {
                    completion(self?.makeError("SOCKS5 authentication failed"))
                    return
                }
                completion(nil)
            }
        })
    }

    // MARK: - HTTP/2

    private func h2Handshake(completion: @escaping (Error?) -> Void) {
        let preface = "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n"
        var settingsFrame = Data()
        // SETTINGS frame: length=0, type=0x04, flags=0, stream=0
        settingsFrame.append(contentsOf: [0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00])

        var handshake = Data(preface.utf8)
        handshake.append(settingsFrame)

        connection?.send(content: handshake, completion: .contentProcessed { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            self?.connection?.receive(minimumIncompleteLength: 9, maximumLength: 256) { data, _, _, error in
                if let error = error {
                    completion(error)
                    return
                }
                completion(nil)
                self?.startReceiving()
            }
        })
    }

    private func sendH2Frame(data: Data, connection: NWConnection) {
        let length = UInt32(data.count)
        var frame = Data()
        frame.append(UInt8((length >> 16) & 0xFF))
        frame.append(UInt8((length >> 8) & 0xFF))
        frame.append(UInt8(length & 0xFF))
        frame.append(0x00) // DATA frame
        frame.append(0x00) // no flags
        frame.append(contentsOf: [0x00, 0x00, 0x00, 0x01]) // stream 1
        frame.append(data)
        connection.send(content: frame, completion: .contentProcessed { _ in })
    }

    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                // Process received data from proxy
                _ = data
            }
            if !isComplete && error == nil {
                self?.startReceiving()
            }
        }
    }

    private func makeError(_ message: String) -> NSError {
        NSError(domain: "H2Proxy", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
