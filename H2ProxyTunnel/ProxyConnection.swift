import Foundation

enum ProxyProtocol: String, Codable, CaseIterable {
    case http = "HTTP/HTTPS"
    case socks5 = "SOCKS5"
    case h2 = "HTTP/2 Tunnel"
}
