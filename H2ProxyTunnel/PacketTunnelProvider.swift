import NetworkExtension
import Network

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var proxyServer: LocalProxyServer?
    private var tunnelInterface: TunnelInterface?
    private var remoteHost: String = ""
    private var remotePort: UInt16 = 0
    private var proto: ProxyProtocol = .http
    private var username: String?
    private var password: String?
    private let sharedDefaults = UserDefaults(suiteName: "group.com.h2proxy.app")

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let config = protocolConfiguration as? NETunnelProviderProtocol,
              let conf = config.providerConfiguration,
              let host = conf["host"] as? String,
              let port = conf["port"] as? Int,
              let protoStr = conf["protocol"] as? String else {
            completionHandler(makeError("Invalid configuration"))
            return
        }

        remoteHost = host
        remotePort = UInt16(port)
        username = conf["username"] as? String
        password = conf["password"] as? String

        switch protoStr {
        case ProxyProtocol.socks5.rawValue: proto = .socks5
        case ProxyProtocol.http.rawValue: proto = .http
        default: proto = .h2
        }

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: host)

        let ipv4 = NEIPv4Settings(addresses: ["10.8.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        ipv4.excludedRoutes = [
            NEIPv4Route(destinationAddress: host, subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "10.8.0.0", subnetMask: "255.255.255.0")
        ]
        settings.ipv4Settings = ipv4

        let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dns.matchDomains = [""]
        settings.dnsSettings = dns

        settings.mtu = 1400

        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: 8830)
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: 8830)
        proxySettings.matchDomains = [""]
        settings.proxySettings = proxySettings

        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                completionHandler(error)
                return
            }
            self?.startLocalProxy(completionHandler: completionHandler)
        }
    }

    private func startLocalProxy(completionHandler: @escaping (Error?) -> Void) {
        proxyServer = LocalProxyServer(
            listenPort: 8830,
            remoteHost: remoteHost,
            remotePort: remotePort,
            proto: proto,
            username: username,
            password: password
        )
        proxyServer?.onBytesTransferred = { [weak self] up, down in
            self?.updateStats(up: up, down: down)
        }
        proxyServer?.start { error in
            completionHandler(error)
        }
        startPacketForwarding()
    }

    private func startPacketForwarding() {
        tunnelInterface = TunnelInterface(packetFlow: packetFlow)
        tunnelInterface?.startHandling()
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        tunnelInterface?.stop()
        proxyServer?.stop()
        proxyServer = nil
        tunnelInterface = nil
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let message = String(data: messageData, encoding: .utf8) {
            if message == "getStats" {
                let up = sharedDefaults?.integer(forKey: "bytesUp") ?? 0
                let down = sharedDefaults?.integer(forKey: "bytesDown") ?? 0
                let response = "\(up),\(down)".data(using: .utf8)
                completionHandler?(response)
                return
            }
        }
        completionHandler?(nil)
    }

    private func updateStats(up: Int64, down: Int64) {
        let currentUp = Int64(sharedDefaults?.integer(forKey: "bytesUp") ?? 0)
        let currentDown = Int64(sharedDefaults?.integer(forKey: "bytesDown") ?? 0)
        sharedDefaults?.set(Int(currentUp + up), forKey: "bytesUp")
        sharedDefaults?.set(Int(currentDown + down), forKey: "bytesDown")
    }

    private func makeError(_ msg: String) -> NSError {
        NSError(domain: "H2ProxyTunnel", code: -1, userInfo: [NSLocalizedDescriptionKey: msg])
    }
}
