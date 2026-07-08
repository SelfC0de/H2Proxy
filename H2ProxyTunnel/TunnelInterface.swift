import NetworkExtension
import Foundation

class TunnelInterface {
    private let packetFlow: NEPacketTunnelFlow
    private var running = false

    init(packetFlow: NEPacketTunnelFlow) {
        self.packetFlow = packetFlow
    }

    func startHandling() {
        running = true
        readPackets()
    }

    func stop() {
        running = false
    }

    private func readPackets() {
        guard running else { return }
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self, self.running else { return }
            for (i, packet) in packets.enumerated() {
                self.processIPPacket(packet, protocolFamily: protocols[i])
            }
            self.readPackets()
        }
    }

    private func processIPPacket(_ packet: Data, protocolFamily: NSNumber) {
        guard packet.count >= 20 else { return }

        let version = (packet[0] >> 4) & 0x0F
        guard version == 4 else { return }

        let ihl = Int(packet[0] & 0x0F) * 4
        guard packet.count >= ihl else { return }

        let proto = packet[9]
        let dstIP = "\(packet[16]).\(packet[17]).\(packet[18]).\(packet[19])"

        if proto == 17 && dstIP == "1.1.1.1" || dstIP == "8.8.8.8" {
            // DNS packets flow through the tunnel naturally
        }
        // IP packets are handled by the system proxy settings
        // which route HTTP/HTTPS traffic to our local proxy server
    }

    func writePackets(_ packets: [Data], protocols: [NSNumber]) {
        packetFlow.writePackets(packets, withProtocols: protocols)
    }
}
