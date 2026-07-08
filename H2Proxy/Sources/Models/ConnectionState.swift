import Foundation

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

class ConnectionState: NSObject {
    static let shared = ConnectionState()

    @objc dynamic var status: Int = 0 // 0=disconnected,1=connecting,2=connected,3=disconnecting
    var bytesUp: Int64 = 0
    var bytesDown: Int64 = 0
    var connectedSince: Date?
    var activeServer: ServerConfig?

    var connectionStatus: ConnectionStatus {
        switch status {
        case 1: return .connecting
        case 2: return .connected
        case 3: return .disconnecting
        default: return .disconnected
        }
    }

    var formattedUptime: String {
        guard let since = connectedSince else { return "00:00:00" }
        let interval = Int(Date().timeIntervalSince(since))
        let h = interval / 3600
        let m = (interval % 3600) / 60
        let s = interval % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    static func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        if unitIndex == 0 { return "\(bytes) B" }
        return String(format: "%.1f %@", value, units[unitIndex])
    }
}
