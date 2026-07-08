import Foundation

class ServerStore {
    static let shared = ServerStore()
    private let key = "h2proxy.servers"

    var servers: [ServerConfig] {
        get {
            guard let data = UserDefaults(suiteName: "group.com.h2proxy.app")?.data(forKey: key),
                  let list = try? JSONDecoder().decode([ServerConfig].self, from: data) else {
                return []
            }
            return list
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults(suiteName: "group.com.h2proxy.app")?.set(data, forKey: key)
            NotificationCenter.default.post(name: .serversDidChange, object: nil)
        }
    }

    func add(_ server: ServerConfig) {
        var list = servers
        list.append(server)
        servers = list
    }

    func update(_ server: ServerConfig) {
        var list = servers
        if let idx = list.firstIndex(where: { $0.id == server.id }) {
            list[idx] = server
            servers = list
        }
    }

    func delete(id: UUID) {
        var list = servers
        list.removeAll { $0.id == id }
        servers = list
    }

    func setActive(id: UUID) {
        var list = servers
        for i in list.indices {
            list[i].isActive = (list[i].id == id)
        }
        servers = list
    }
}

extension Notification.Name {
    static let serversDidChange = Notification.Name("h2proxy.serversDidChange")
}
