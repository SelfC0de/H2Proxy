import NetworkExtension
import Network

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var proxyConnection: ProxyConnection?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard let config = protocolConfiguration as? NETunnelProviderProtocol,
              let conf = config.providerConfiguration,
              let host = conf["host"] as? String,
              let port = conf["port"] as? Int,
              let protoStr = conf["protocol"] as? String else {
            completionHandler(NSError(domain: "H2Proxy", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid configuration"]))
            return
        }

        let username = conf["username"] as? String
        let password = conf["password"] as? String

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: host)

        let ipv4 = NEIPv4Settings(addresses: ["10.8.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        ipv4.excludedRoutes = [NEIPv4Route(destinationAddress: host, subnetMask: "255.255.255.255")]
        settings.ipv4Settings = ipv4

        let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        settings.dnsSettings = dns

        settings.mtu = 1500

        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error = error {
                completionHandler(error)
                return
            }

            let proxyProto: ProxyProtocol
            switch protoStr {
            case ProxyProtocol.socks5.rawValue: proxyProto = .socks5
            case ProxyProtocol.http.rawValue: proxyProto = .http
            default: proxyProto = .h2
            }

            self?.proxyConnection = ProxyConnection(
                host: host,
                port: UInt16(port),
                protocol: proxyProto,
                username: username,
                password: password
            )
            self?.proxyConnection?.connect { error in
                completionHandler(error)
                if error == nil {
                    self?.startForwarding()
                }
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        proxyConnection?.disconnect()
        proxyConnection = nil
        completionHandler()
    }

    private func startForwarding() {
        packetFlow.readPackets { [weak self] packets, protocols in
            for (i, packet) in packets.enumerated() {
                self?.proxyConnection?.sendPacket(packet, protocolFamily: protocols[i])
            }
            self?.startForwarding()
        }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        completionHandler?(nil)
    }
}
