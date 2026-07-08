import UIKit
import NetworkExtension

class MainViewController: UIViewController {

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let settingsButton = UIButton(type: .system)

    private let connectContainer = UIView()
    private let connectRing = CAShapeLayer()
    private let connectPulse = CAShapeLayer()
    private let connectButton = UIButton(type: .system)
    private let connectLabel = UILabel()
    private let connectGlow = CAGradientLayer()

    private let statusCard = UIView()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let uptimeLabel = UILabel()

    private let statsCard = UIView()
    private let uploadTitleLabel = UILabel()
    private let uploadValueLabel = UILabel()
    private let uploadSpeedLabel = UILabel()
    private let downloadTitleLabel = UILabel()
    private let downloadValueLabel = UILabel()
    private let downloadSpeedLabel = UILabel()

    private let serverCard = UIView()
    private let serverIconView = UIImageView()
    private let serverNameLabel = UILabel()
    private let serverDetailLabel = UILabel()
    private let serverPingLabel = UILabel()
    private let serverChevron = UIImageView()

    private let manageButton = UIButton(type: .system)

    private var uptimeTimer: Timer?
    private var pulseTimer: Timer?
    private var isConnected = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = Theme.backgroundPrimary
        setupScrollView()
        setupHeader()
        setupConnectButton()
        setupStatusCard()
        setupStatsCard()
        setupServerCard()
        setupManageButton()
        loadVPN()
        NotificationCenter.default.addObserver(self, selector: #selector(serversChanged), name: .serversDidChange, object: nil)
        updateActiveServer()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        connectGlow.frame = connectContainer.bounds
    }

    // MARK: - Scroll View

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    // MARK: - Header

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "H2Proxy"
        titleLabel.font = Theme.title(28)
        titleLabel.textColor = Theme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text = "Secure tunnel"
        subtitleLabel.font = Theme.body(14)
        subtitleLabel.textColor = Theme.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: config), for: .normal)
        settingsButton.tintColor = Theme.textSecondary
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubview(titleLabel)
        headerView.addSubview(subtitleLabel)
        headerView.addSubview(settingsButton)

        let topPadding: CGFloat = 52
        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: topPadding + 50),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: topPadding),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        contentStack.addArrangedSubview(headerView)
    }

    // MARK: - Connect Button

    private func setupConnectButton() {
        connectContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectContainer.heightAnchor.constraint(equalToConstant: 200)
        ])

        // Glow background
        connectGlow.colors = [
            UIColor.clear.cgColor,
            Theme.accentBlue.withAlphaComponent(0.08).cgColor,
            UIColor.clear.cgColor
        ]
        connectGlow.type = .radial
        connectGlow.startPoint = CGPoint(x: 0.5, y: 0.5)
        connectGlow.endPoint = CGPoint(x: 1.0, y: 1.0)
        connectContainer.layer.addSublayer(connectGlow)

        let buttonSize: CGFloat = 140
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.backgroundColor = Theme.accentBlue.withAlphaComponent(0.12)
        connectButton.layer.cornerRadius = buttonSize / 2
        connectButton.layer.cornerCurve = .continuous
        connectButton.layer.borderWidth = 2.5
        connectButton.layer.borderColor = Theme.accentBlue.cgColor

        let powerConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        connectButton.setImage(UIImage(systemName: "power", withConfiguration: powerConfig), for: .normal)
        connectButton.tintColor = Theme.accentBlue
        connectButton.addTarget(self, action: #selector(connectTapped), for: .touchUpInside)
        connectButton.addTarget(self, action: #selector(connectDown), for: .touchDown)
        connectButton.addTarget(self, action: #selector(connectUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        connectContainer.addSubview(connectButton)

        connectLabel.text = "Tap to connect"
        connectLabel.font = Theme.caption(13)
        connectLabel.textColor = Theme.textMuted
        connectLabel.textAlignment = .center
        connectLabel.translatesAutoresizingMaskIntoConstraints = false
        connectContainer.addSubview(connectLabel)

        NSLayoutConstraint.activate([
            connectButton.centerXAnchor.constraint(equalTo: connectContainer.centerXAnchor),
            connectButton.centerYAnchor.constraint(equalTo: connectContainer.centerYAnchor, constant: -10),
            connectButton.widthAnchor.constraint(equalToConstant: buttonSize),
            connectButton.heightAnchor.constraint(equalToConstant: buttonSize),
            connectLabel.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 14),
            connectLabel.centerXAnchor.constraint(equalTo: connectContainer.centerXAnchor)
        ])

        // Pulse ring
        let pulsePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: buttonSize + 30, height: buttonSize + 30))
        connectPulse.path = pulsePath.cgPath
        connectPulse.fillColor = UIColor.clear.cgColor
        connectPulse.strokeColor = Theme.accentBlue.withAlphaComponent(0.3).cgColor
        connectPulse.lineWidth = 2
        connectPulse.opacity = 0
        connectButton.layer.addSublayer(connectPulse)
        connectPulse.position = CGPoint(x: -15, y: -15)

        contentStack.addArrangedSubview(connectContainer)
    }

    // MARK: - Status Card

    private func setupStatusCard() {
        Theme.styleCard(statusCard)
        statusCard.translatesAutoresizingMaskIntoConstraints = false

        statusDot.backgroundColor = Theme.textMuted
        statusDot.layer.cornerRadius = 5
        statusDot.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.text = "Disconnected"
        statusLabel.font = Theme.heading(15)
        statusLabel.textColor = Theme.textPrimary
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        uptimeLabel.text = ""
        uptimeLabel.font = Theme.mono(13)
        uptimeLabel.textColor = Theme.textSecondary
        uptimeLabel.translatesAutoresizingMaskIntoConstraints = false

        statusCard.addSubview(statusDot)
        statusCard.addSubview(statusLabel)
        statusCard.addSubview(uptimeLabel)

        NSLayoutConstraint.activate([
            statusCard.heightAnchor.constraint(equalToConstant: 52),
            statusDot.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 18),
            statusDot.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 10),
            statusLabel.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor),
            uptimeLabel.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -18),
            uptimeLabel.centerYAnchor.constraint(equalTo: statusCard.centerYAnchor)
        ])

        contentStack.addArrangedSubview(statusCard)
    }

    // MARK: - Stats Card

    private func setupStatsCard() {
        Theme.styleCard(statsCard, elevated: true)
        statsCard.translatesAutoresizingMaskIntoConstraints = false

        let upStack = makeStatColumn(
            icon: "arrow.up.circle.fill",
            iconColor: Theme.accentCyan,
            titleLabel: uploadTitleLabel, titleText: "Upload",
            valueLabel: uploadValueLabel, valueText: "0 B",
            speedLabel: uploadSpeedLabel, speedText: ""
        )
        let downStack = makeStatColumn(
            icon: "arrow.down.circle.fill",
            iconColor: Theme.accentBlue,
            titleLabel: downloadTitleLabel, titleText: "Download",
            valueLabel: downloadValueLabel, valueText: "0 B",
            speedLabel: downloadSpeedLabel, speedText: ""
        )

        let divider = UIView()
        divider.backgroundColor = Theme.separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        let hStack = UIStackView(arrangedSubviews: [upStack, divider, downStack])
        hStack.axis = .horizontal
        hStack.distribution = .fillEqually
        hStack.alignment = .center
        hStack.spacing = 0
        hStack.translatesAutoresizingMaskIntoConstraints = false

        statsCard.addSubview(hStack)
        NSLayoutConstraint.activate([
            statsCard.heightAnchor.constraint(equalToConstant: 110),
            hStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16),
            hStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -12),
            hStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -16),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 50)
        ])

        contentStack.addArrangedSubview(statsCard)
    }

    private func makeStatColumn(icon: String, iconColor: UIColor, titleLabel: UILabel, titleText: String, valueLabel: UILabel, valueText: String, speedLabel: UILabel, speedText: String) -> UIStackView {
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: iconConfig))
        iconView.tintColor = iconColor
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = titleText
        titleLabel.font = Theme.caption(11)
        titleLabel.textColor = Theme.textMuted
        titleLabel.textAlignment = .center

        valueLabel.text = valueText
        valueLabel.font = Theme.heading(20)
        valueLabel.textColor = Theme.textPrimary
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7

        speedLabel.text = speedText
        speedLabel.font = Theme.mono(11)
        speedLabel.textColor = Theme.textSecondary
        speedLabel.textAlignment = .center

        let titleRow = UIStackView(arrangedSubviews: [iconView, titleLabel])
        titleRow.axis = .horizontal
        titleRow.spacing = 4
        titleRow.alignment = .center

        let wrapperView = UIView()
        titleRow.translatesAutoresizingMaskIntoConstraints = false
        wrapperView.addSubview(titleRow)
        NSLayoutConstraint.activate([
            titleRow.centerXAnchor.constraint(equalTo: wrapperView.centerXAnchor),
            titleRow.centerYAnchor.constraint(equalTo: wrapperView.centerYAnchor),
            wrapperView.heightAnchor.constraint(equalToConstant: 20)
        ])

        let stack = UIStackView(arrangedSubviews: [wrapperView, valueLabel, speedLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }

    // MARK: - Server Card

    private func setupServerCard() {
        Theme.styleCard(serverCard)
        serverCard.translatesAutoresizingMaskIntoConstraints = false

        let sectionLabel = UILabel()
        sectionLabel.text = "ACTIVE SERVER"
        sectionLabel.font = Theme.caption(11)
        sectionLabel.textColor = Theme.textMuted
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        serverIconView.image = UIImage(systemName: "server.rack", withConfiguration: iconConfig)
        serverIconView.tintColor = Theme.accentBlue
        serverIconView.contentMode = .scaleAspectFit
        serverIconView.translatesAutoresizingMaskIntoConstraints = false

        serverNameLabel.text = "No server selected"
        serverNameLabel.font = Theme.heading(16)
        serverNameLabel.textColor = Theme.textPrimary
        serverNameLabel.numberOfLines = 1
        serverNameLabel.lineBreakMode = .byTruncatingTail
        serverNameLabel.translatesAutoresizingMaskIntoConstraints = false

        serverDetailLabel.text = "Tap to choose a server"
        serverDetailLabel.font = Theme.body(13)
        serverDetailLabel.textColor = Theme.textSecondary
        serverDetailLabel.numberOfLines = 2
        serverDetailLabel.lineBreakMode = .byWordWrapping
        serverDetailLabel.translatesAutoresizingMaskIntoConstraints = false

        serverPingLabel.text = ""
        serverPingLabel.font = Theme.mono(12)
        serverPingLabel.textColor = Theme.accentGreen
        serverPingLabel.textAlignment = .right
        serverPingLabel.setContentHuggingPriority(.required, for: .horizontal)
        serverPingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        serverPingLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        serverChevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        serverChevron.tintColor = Theme.textMuted
        serverChevron.translatesAutoresizingMaskIntoConstraints = false

        serverCard.addSubview(sectionLabel)
        serverCard.addSubview(serverIconView)
        serverCard.addSubview(serverNameLabel)
        serverCard.addSubview(serverDetailLabel)
        serverCard.addSubview(serverPingLabel)
        serverCard.addSubview(serverChevron)

        NSLayoutConstraint.activate([
            serverCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 90),

            sectionLabel.topAnchor.constraint(equalTo: serverCard.topAnchor, constant: 14),
            sectionLabel.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 18),

            serverIconView.topAnchor.constraint(equalTo: sectionLabel.bottomAnchor, constant: 12),
            serverIconView.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 18),
            serverIconView.widthAnchor.constraint(equalToConstant: 28),
            serverIconView.heightAnchor.constraint(equalToConstant: 28),

            serverNameLabel.topAnchor.constraint(equalTo: serverIconView.topAnchor, constant: -2),
            serverNameLabel.leadingAnchor.constraint(equalTo: serverIconView.trailingAnchor, constant: 12),
            serverNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: serverPingLabel.leadingAnchor, constant: -8),

            serverDetailLabel.topAnchor.constraint(equalTo: serverNameLabel.bottomAnchor, constant: 2),
            serverDetailLabel.leadingAnchor.constraint(equalTo: serverNameLabel.leadingAnchor),
            serverDetailLabel.trailingAnchor.constraint(equalTo: serverChevron.leadingAnchor, constant: -8),
            serverDetailLabel.bottomAnchor.constraint(lessThanOrEqualTo: serverCard.bottomAnchor, constant: -14),

            serverPingLabel.centerYAnchor.constraint(equalTo: serverIconView.centerYAnchor),
            serverPingLabel.trailingAnchor.constraint(equalTo: serverChevron.leadingAnchor, constant: -8),

            serverChevron.centerYAnchor.constraint(equalTo: serverCard.centerYAnchor),
            serverChevron.trailingAnchor.constraint(equalTo: serverCard.trailingAnchor, constant: -16)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(openServerList))
        serverCard.addGestureRecognizer(tap)
        serverCard.isUserInteractionEnabled = true

        contentStack.addArrangedSubview(serverCard)
    }

    // MARK: - Manage Button

    private func setupManageButton() {
        manageButton.translatesAutoresizingMaskIntoConstraints = false
        manageButton.setTitle("Manage servers", for: .normal)
        manageButton.titleLabel?.font = Theme.heading(15)
        manageButton.setTitleColor(Theme.accentBlue, for: .normal)
        manageButton.backgroundColor = Theme.accentBlue.withAlphaComponent(0.08)
        manageButton.layer.cornerRadius = 14
        manageButton.layer.cornerCurve = .continuous
        manageButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        manageButton.addTarget(self, action: #selector(openServerList), for: .touchUpInside)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        manageButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: iconConfig), for: .normal)
        manageButton.tintColor = Theme.accentBlue
        manageButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -6, bottom: 0, right: 6)

        NSLayoutConstraint.activate([
            manageButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        contentStack.addArrangedSubview(manageButton)
    }

    // MARK: - Animations

    private func animateEntrance() {
        let views = [statusCard, statsCard, serverCard, manageButton]
        for (i, v) in views.enumerated() {
            Theme.fadeIn(v, delay: Double(i) * 0.08)
        }

        connectButton.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        connectButton.alpha = 0
        Theme.springAnimate(0.8, delay: 0.1, damping: 0.6, velocity: 0.8, animations: {
            self.connectButton.transform = .identity
            self.connectButton.alpha = 1
        })
    }

    @objc private func connectDown() {
        Theme.springAnimate(0.2, damping: 0.9, animations: {
            self.connectButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        })
    }

    @objc private func connectUp() {
        Theme.springAnimate(0.4, damping: 0.5, animations: {
            self.connectButton.transform = .identity
        })
    }

    private func startPulseAnimation() {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 1.0
        anim.toValue = 1.5
        anim.duration = 1.5
        anim.repeatCount = .infinity
        anim.autoreverses = false

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.5
        fade.toValue = 0.0
        fade.duration = 1.5
        fade.repeatCount = .infinity

        let group = CAAnimationGroup()
        group.animations = [anim, fade]
        group.duration = 1.5
        group.repeatCount = .infinity

        connectPulse.opacity = 1
        connectPulse.add(group, forKey: "pulse")
    }

    private func stopPulseAnimation() {
        connectPulse.removeAllAnimations()
        connectPulse.opacity = 0
    }

    private func transitionToConnected() {
        isConnected = true
        Theme.springAnimate(0.5, damping: 0.7, animations: {
            self.connectButton.backgroundColor = Theme.accentGreen.withAlphaComponent(0.15)
            self.connectButton.layer.borderColor = Theme.accentGreen.cgColor
            self.connectButton.tintColor = Theme.accentGreen
            self.statusDot.backgroundColor = Theme.accentGreen
        })

        connectLabel.text = "Tap to disconnect"
        statusLabel.text = "Connected"
        startPulseAnimation()
        connectPulse.strokeColor = Theme.accentGreen.withAlphaComponent(0.3).cgColor

        // Glow animation
        let glowAnim = CABasicAnimation(keyPath: "colors")
        glowAnim.toValue = [
            UIColor.clear.cgColor,
            Theme.accentGreen.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        glowAnim.duration = 0.8
        glowAnim.fillMode = .forwards
        glowAnim.isRemovedOnCompletion = false
        connectGlow.add(glowAnim, forKey: "glowColor")
    }

    private func transitionToDisconnected() {
        isConnected = false
        Theme.springAnimate(0.5, damping: 0.7, animations: {
            self.connectButton.backgroundColor = Theme.accentBlue.withAlphaComponent(0.12)
            self.connectButton.layer.borderColor = Theme.accentBlue.cgColor
            self.connectButton.tintColor = Theme.accentBlue
            self.statusDot.backgroundColor = Theme.textMuted
        })

        connectLabel.text = "Tap to connect"
        statusLabel.text = "Disconnected"
        uptimeLabel.text = ""
        stopPulseAnimation()

        let glowAnim = CABasicAnimation(keyPath: "colors")
        glowAnim.toValue = [
            UIColor.clear.cgColor,
            Theme.accentBlue.withAlphaComponent(0.08).cgColor,
            UIColor.clear.cgColor
        ]
        glowAnim.duration = 0.8
        glowAnim.fillMode = .forwards
        glowAnim.isRemovedOnCompletion = false
        connectGlow.add(glowAnim, forKey: "glowColor")
    }

    // MARK: - VPN

    private func loadVPN() {
        VPNManager.shared.loadManager { [weak self] error in
            if let error = error { print("VPN load error: \(error)") }
            self?.observeVPN()
        }
    }

    private func observeVPN() {
        VPNManager.shared.observeStatus { [weak self] status in
            DispatchQueue.main.async { self?.handleVPNStatus(status) }
        }
    }

    private func handleVPNStatus(_ status: NEVPNStatus) {
        switch status {
        case .connected:
            ConnectionState.shared.status = 2
            if ConnectionState.shared.connectedSince == nil {
                ConnectionState.shared.connectedSince = Date()
            }
            transitionToConnected()
            startUptimeTimer()

        case .connecting:
            ConnectionState.shared.status = 1
            statusLabel.text = "Connecting..."
            statusDot.backgroundColor = Theme.accentOrange
            connectLabel.text = "Establishing tunnel..."

            // Breathing animation during connect
            UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut], animations: {
                self.connectButton.alpha = 0.5
            })

        case .disconnecting:
            ConnectionState.shared.status = 3
            statusLabel.text = "Disconnecting..."
            statusDot.backgroundColor = Theme.accentOrange

        default:
            ConnectionState.shared.status = 0
            connectButton.layer.removeAllAnimations()
            connectButton.alpha = 1
            transitionToDisconnected()
            stopUptimeTimer()
        }
    }

    private func startUptimeTimer() {
        uptimeTimer?.invalidate()
        uptimeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.uptimeLabel.text = ConnectionState.shared.formattedUptime
            self.uploadValueLabel.text = ConnectionState.formatBytes(ConnectionState.shared.bytesUp)
            self.downloadValueLabel.text = ConnectionState.formatBytes(ConnectionState.shared.bytesDown)
        }
    }

    private func stopUptimeTimer() {
        uptimeTimer?.invalidate()
        uptimeTimer = nil
    }

    // MARK: - Actions

    @objc private func connectTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        let state = ConnectionState.shared
        if state.connectionStatus == .connected || state.connectionStatus == .connecting {
            VPNManager.shared.disconnect()
        } else {
            guard let server = ServerStore.shared.servers.first(where: { $0.isActive }) else {
                showAlert(title: "No server", message: "Select a server first from the server list.")
                return
            }
            VPNManager.shared.connect(server: server) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showAlert(title: "Connection failed", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc private func openServerList() {
        let vc = ServerListViewController()
        vc.hidesBottomBarWhenPushed = true
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
            serverDetailLabel.text = "\(active.host):\(active.port) · \(active.protocolType.rawValue)"
            serverPingLabel.text = ""
            serverIconView.tintColor = Theme.accentGreen
        } else {
            serverNameLabel.text = "No server selected"
            serverDetailLabel.text = "Tap to choose a server"
            serverPingLabel.text = ""
            serverIconView.tintColor = Theme.textMuted
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
