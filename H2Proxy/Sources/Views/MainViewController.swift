import UIKit
import NetworkExtension

class MainViewController: UIViewController {

    private let connectButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let uptimeLabel = UILabel()
    private let uploadLabel = UILabel()
    private let downloadLabel = UILabel()
    private let uploadSpeedLabel = UILabel()
    private let downloadSpeedLabel = UILabel()
    private let serverNameLabel = UILabel()
    private let serverProtocolLabel = UILabel()
    private var uptimeTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "H2Proxy"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        setupUI()
        loadVPN()
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        // Status
        statusLabel.text = "Disconnected"
        statusLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(statusLabel)

        // Connect button
        connectButton.setTitle("Connect", for: .normal)
        connectButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        connectButton.backgroundColor = .systemBlue
        connectButton.setTitleColor(.white, for: .normal)
        connectButton.layer.cornerRadius = 60
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectButton.widthAnchor.constraint(equalToConstant: 120),
            connectButton.heightAnchor.constraint(equalToConstant: 120)
        ])
        connectButton.addTarget(self, action: #selector(toggleConnection), for: .touchUpInside)
        stack.addArrangedSubview(connectButton)

        // Uptime
        uptimeLabel.text = "00:00:00"
        uptimeLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        uptimeLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(uptimeLabel)

        // Stats
        let statsStack = UIStackView()
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 12
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsStack.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])

        let upBox = makeStatBox(title: "Upload", valueLabel: &uploadLabel, speedLabel: &uploadSpeedLabel)
        let downBox = makeStatBox(title: "Download", valueLabel: &downloadLabel, speedLabel: &downloadSpeedLabel)
        statsStack.addArrangedSubview(upBox)
        statsStack.addArrangedSubview(downBox)
        stack.addArrangedSubview(statsStack)

        // Active server
        let serverCard = UIView()
        serverCard.backgroundColor = .secondarySystemGroupedBackground
        serverCard.layer.cornerRadius = 12
        serverCard.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            serverCard.widthAnchor.constraint(equalTo: stack.widthAnchor),
            serverCard.heightAnchor.constraint(equalToConstant: 56)
        ])

        serverNameLabel.text = "No server selected"
        serverNameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        serverProtocolLabel.text = "Tap to select"
        serverProtocolLabel.font = .systemFont(ofSize: 12)
        serverProtocolLabel.textColor = .secondaryLabel

        let serverStack = UIStackView(arrangedSubviews: [serverNameLabel, serverProtocolLabel])
        serverStack.axis = .vertical
        serverStack.spacing = 2
        serverStack.translatesAutoresizingMaskIntoConstraints = false
        serverCard.addSubview(serverStack)
        NSLayoutConstraint.activate([
            serverStack.centerYAnchor.constraint(equalTo: serverCard.centerYAnchor),
            serverStack.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 16)
        ])

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false
        serverCard.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerYAnchor.constraint(equalTo: serverCard.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: serverCard.trailingAnchor, constant: -16)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(openServerList))
        serverCard.addGestureRecognizer(tap)
        stack.addArrangedSubview(serverCard)

        // Server list button
        let serversButton = UIButton(type: .system)
        serversButton.setTitle("Manage Servers", for: .normal)
        serversButton.addTarget(self, action: #selector(openServerList), for: .touchUpInside)
        stack.addArrangedSubview(serversButton)

        NotificationCenter.default.addObserver(self, selector: #selector(serversChanged), name: .serversDidChange, object: nil)
        updateActiveServer()
    }

    private var _uploadLabel: UILabel?
    private var _downloadLabel: UILabel?

    private func makeStatBox(title: String, valueLabel: inout UILabel, speedLabel: inout UILabel) -> UIView {
        let box = UIView()
        box.backgroundColor = .secondarySystemGroupedBackground
        box.layer.cornerRadius = 12

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 11, weight: .medium)
        titleLbl.textColor = .tertiaryLabel

        valueLabel.text = "0 B"
        valueLabel.font = .systemFont(ofSize: 18, weight: .medium)

        speedLabel.text = ""
        speedLabel.font = .systemFont(ofSize: 11)
        speedLabel.textColor = .tertiaryLabel

        let vStack = UIStackView(arrangedSubviews: [titleLbl, valueLabel, speedLabel])
        vStack.axis = .vertical
        vStack.spacing = 2
        vStack.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            vStack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            vStack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12),
            vStack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12)
        ])
        return box
    }

    private func loadVPN() {
        VPNManager.shared.loadManager { [weak self] error in
            if let error = error {
                print("VPN load error: \(error)")
            }
            self?.observeVPN()
        }
    }

    private func observeVPN() {
        VPNManager.shared.observeStatus { [weak self] status in
            DispatchQueue.main.async {
                self?.updateUI(vpnStatus: status)
            }
        }
    }

    private func updateUI(vpnStatus: NEVPNStatus) {
        switch vpnStatus {
        case .connected:
            ConnectionState.shared.status = 2
            ConnectionState.shared.connectedSince = ConnectionState.shared.connectedSince ?? Date()
            statusLabel.text = "Connected"
            statusLabel.textColor = .systemGreen
            connectButton.setTitle("Stop", for: .normal)
            connectButton.backgroundColor = .systemRed
            startUptimeTimer()
        case .connecting:
            ConnectionState.shared.status = 1
            statusLabel.text = "Connecting..."
            statusLabel.textColor = .systemOrange
        case .disconnecting:
            ConnectionState.shared.status = 3
            statusLabel.text = "Disconnecting..."
            statusLabel.textColor = .systemOrange
        default:
            ConnectionState.shared.status = 0
            statusLabel.text = "Disconnected"
            statusLabel.textColor = .secondaryLabel
            connectButton.setTitle("Connect", for: .normal)
            connectButton.backgroundColor = .systemBlue
            stopUptimeTimer()
        }
    }

    private func startUptimeTimer() {
        uptimeTimer?.invalidate()
        uptimeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.uptimeLabel.text = ConnectionState.shared.formattedUptime
            self?.uploadLabel.text = ConnectionState.formatBytes(ConnectionState.shared.bytesUp)
            self?.downloadLabel.text = ConnectionState.formatBytes(ConnectionState.shared.bytesDown)
        }
    }

    private func stopUptimeTimer() {
        uptimeTimer?.invalidate()
        uptimeTimer = nil
        uptimeLabel.text = "00:00:00"
    }

    @objc private func toggleConnection() {
        let state = ConnectionState.shared
        if state.connectionStatus == .connected || state.connectionStatus == .connecting {
            VPNManager.shared.disconnect()
        } else {
            guard let server = ServerStore.shared.servers.first(where: { $0.isActive }) else {
                let alert = UIAlertController(title: "No server", message: "Select a server first.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            VPNManager.shared.connect(server: server) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }

    @objc private func openServerList() {
        let vc = ServerListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func openSettings() {
        let vc = SettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func serversChanged() {
        updateActiveServer()
    }

    private func updateActiveServer() {
        if let active = ServerStore.shared.servers.first(where: { $0.isActive }) {
            serverNameLabel.text = active.name
            serverProtocolLabel.text = active.protocolType.rawValue
        } else {
            serverNameLabel.text = "No server selected"
            serverProtocolLabel.text = "Tap to select"
        }
    }
}
