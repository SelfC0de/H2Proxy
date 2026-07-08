import Foundation
import NetworkExtension

class VPNManager {
    static let shared = VPNManager()
    private var manager: NETunnelProviderManager?
    private var statsTimer: Timer?
    private let sharedDefaults = UserDefaults(suiteName: "group.com.h2proxy.app")

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
        proto.disconnectOnSleep = false

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

        // Reset stats
        sharedDefaults?.set(0, forKey: "bytesUp")
        sharedDefaults?.set(0, forKey: "bytesDown")

        manager.saveToPreferences { error in
            if let error = error {
                completion(error)
                return
            }
            manager.loadFromPreferences { [weak self] error in
                if let error = error {
                    completion(error)
                    return
                }
                do {
                    try manager.connection.startVPNTunnel()
                    ConnectionState.shared.status = 1
                    ConnectionState.shared.activeServer = server
                    ConnectionState.shared.connectedSince = Date()
                    self?.startStatsPolling()
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }

    func disconnect() {
        manager?.connection.stopVPNTunnel()
        stopStatsPolling()
        ConnectionState.shared.status = 0
        ConnectionState.shared.connectedSince = nil
        ConnectionState.shared.bytesUp = 0
        ConnectionState.shared.bytesDown = 0
    }

    func observeStatus(handler: @escaping (NEVPNStatus) -> Void) {
        NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { notification in
            guard let conn = notification.object as? NEVPNConnection else { return }
            handler(conn.status)
        }
    }

    // MARK: - Stats polling

    private func startStatsPolling() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.pollStats()
        }
    }

    private func stopStatsPolling() {
        statsTimer?.invalidate()
        statsTimer = nil
    }

    private func pollStats() {
        guard let session = manager?.connection as? NETunnelProviderSession else { return }
        do {
            try session.sendProviderMessage("getStats".data(using: .utf8)!) { data in
                guard let data = data, let str = String(data: data, encoding: .utf8) else { return }
                let parts = str.components(separatedBy: ",")
                if parts.count == 2, let up = Int64(parts[0]), let down = Int64(parts[1]) {
                    DispatchQueue.main.async {
                        ConnectionState.shared.bytesUp = up
                        ConnectionState.shared.bytesDown = down
                    }
                }
            }
        } catch {
            // Extension not running
        }
    }
}
