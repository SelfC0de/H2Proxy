import Foundation
import NetworkExtension

class VPNManager {
    static let shared = VPNManager()
    private var manager: NETunnelProviderManager?

    func loadManager(completion: @escaping (Error?) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                completion(error)
                return
            }
            self?.manager = managers?.first ?? NETunnelProviderManager()
            completion(nil)
        }
    }

    func connect(server: ServerConfig, completion: @escaping (Error?) -> Void) {
        guard let manager = manager else {
            completion(NSError(domain: "H2Proxy", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager not loaded"]))
            return
        }

        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "com.h2proxy.app.tunnel"
        proto.serverAddress = "\(server.host):\(server.port)"

        var conf: [String: Any] = [
            "host": server.host,
            "port": server.port,
            "protocol": server.protocolType.rawValue
        ]
        if let user = server.username { conf["username"] = user }
        if let pass = server.password { conf["password"] = pass }
        proto.providerConfiguration = conf

        manager.protocolConfiguration = proto
        manager.localizedDescription = "H2Proxy"
        manager.isEnabled = true

        manager.saveToPreferences { error in
            if let error = error {
                completion(error)
                return
            }
            manager.loadFromPreferences { error in
                if let error = error {
                    completion(error)
                    return
                }
                do {
                    try manager.connection.startVPNTunnel()
                    ConnectionState.shared.status = 1
                    ConnectionState.shared.activeServer = server
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }

    func disconnect() {
        manager?.connection.stopVPNTunnel()
        ConnectionState.shared.status = 0
        ConnectionState.shared.connectedSince = nil
        ConnectionState.shared.bytesUp = 0
        ConnectionState.shared.bytesDown = 0
    }

    func observeStatus(handler: @escaping (NEVPNStatus) -> Void) {
        NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager?.connection,
            queue: .main
        ) { notification in
            guard let conn = notification.object as? NEVPNConnection else { return }
            handler(conn.status)
        }
    }
}
