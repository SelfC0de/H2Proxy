import Foundation

enum ProxyProtocol: String, Codable, CaseIterable {
    case http = "HTTP/HTTPS"
    case socks5 = "SOCKS5"
    case h2 = "HTTP/2 Tunnel"
}

struct ServerConfig: Codable, Identifiable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var protocolType: ProxyProtocol
    var username: String?
    var password: String?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int,
        protocolType: ProxyProtocol = .h2,
        username: String? = nil,
        password: String? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.protocolType = protocolType
        self.username = username
        self.password = password
        self.isActive = isActive
    }
}
