import UIKit

class AddServerViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private var name = ""
    private var host = ""
    private var port = "443"
    private var selectedProtocol: ProxyProtocol = .h2
    private var username = ""
    private var password = ""
    private var authEnabled = false

    private let nameField = UITextField()
    private let hostField = UITextField()
    private let portField = UITextField()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let authSwitch = UISwitch()
    private let authFieldsStack = UIStackView()
    private var protocolButtons: [ProxyProtocol: UIButton] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.backgroundPrimary
        title = "Add server"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = Theme.accentBlue
        setupUI()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        // Server section
        addSectionLabel("SERVER DETAILS")

        let serverCard = UIView()
        Theme.styleCard(serverCard)
        let serverStack = UIStackView()
        serverStack.axis = .vertical
        serverStack.spacing = 16
        serverStack.translatesAutoresizingMaskIntoConstraints = false
        serverCard.addSubview(serverStack)
        NSLayoutConstraint.activate([
            serverStack.topAnchor.constraint(equalTo: serverCard.topAnchor, constant: 18),
            serverStack.leadingAnchor.constraint(equalTo: serverCard.leadingAnchor, constant: 18),
            serverStack.trailingAnchor.constraint(equalTo: serverCard.trailingAnchor, constant: -18),
            serverStack.bottomAnchor.constraint(equalTo: serverCard.bottomAnchor, constant: -18)
        ])

        serverStack.addArrangedSubview(makeField(nameField, placeholder: "Server name", icon: "tag.fill"))
        serverStack.addArrangedSubview(makeField(hostField, placeholder: "proxy.example.com", icon: "globe"))
        serverStack.addArrangedSubview(makeField(portField, placeholder: "443", icon: "number", keyboard: .numberPad))
        portField.text = "443"

        contentStack.addArrangedSubview(serverCard)

        // Protocol section
        addSectionLabel("PROTOCOL")

        let protoCard = UIView()
        Theme.styleCard(protoCard)
        let protoStack = UIStackView()
        protoStack.axis = .vertical
        protoStack.spacing = 10
        protoStack.translatesAutoresizingMaskIntoConstraints = false
        protoCard.addSubview(protoStack)
        NSLayoutConstraint.activate([
            protoStack.topAnchor.constraint(equalTo: protoCard.topAnchor, constant: 14),
            protoStack.leadingAnchor.constraint(equalTo: protoCard.leadingAnchor, constant: 14),
            protoStack.trailingAnchor.constraint(equalTo: protoCard.trailingAnchor, constant: -14),
            protoStack.bottomAnchor.constraint(equalTo: protoCard.bottomAnchor, constant: -14)
        ])

        for proto in ProxyProtocol.allCases {
            let btn = makeProtocolButton(proto)
            protocolButtons[proto] = btn
            protoStack.addArrangedSubview(btn)
        }
        updateProtocolSelection()
        contentStack.addArrangedSubview(protoCard)

        // Auth section
        addSectionLabel("AUTHENTICATION")

        let authCard = UIView()
        Theme.styleCard(authCard)
        let authMainStack = UIStackView()
        authMainStack.axis = .vertical
        authMainStack.spacing = 14
        authMainStack.translatesAutoresizingMaskIntoConstraints = false
        authCard.addSubview(authMainStack)
        NSLayoutConstraint.activate([
            authMainStack.topAnchor.constraint(equalTo: authCard.topAnchor, constant: 18),
            authMainStack.leadingAnchor.constraint(equalTo: authCard.leadingAnchor, constant: 18),
            authMainStack.trailingAnchor.constraint(equalTo: authCard.trailingAnchor, constant: -18),
            authMainStack.bottomAnchor.constraint(equalTo: authCard.bottomAnchor, constant: -18)
        ])

        let toggleRow = UIStackView()
        toggleRow.axis = .horizontal
        let toggleLabel = UILabel()
        toggleLabel.text = "Enable authentication"
        toggleLabel.font = Theme.body(15)
        toggleLabel.textColor = Theme.textPrimary
        authSwitch.onTintColor = Theme.accentBlue
        authSwitch.addTarget(self, action: #selector(authToggled), for: .valueChanged)
        toggleRow.addArrangedSubview(toggleLabel)
        toggleRow.addArrangedSubview(authSwitch)
        authMainStack.addArrangedSubview(toggleRow)

        authFieldsStack.axis = .vertical
        authFieldsStack.spacing = 14
        authFieldsStack.isHidden = true
        authFieldsStack.addArrangedSubview(makeField(usernameField, placeholder: "Username", icon: "person.fill"))
        authFieldsStack.addArrangedSubview(makeField(passwordField, placeholder: "Password", icon: "lock.fill", isSecure: true))
        authMainStack.addArrangedSubview(authFieldsStack)

        contentStack.addArrangedSubview(authCard)

        // QR button
        let qrButton = UIButton(type: .system)
        qrButton.setTitle("  Import from QR code", for: .normal)
        qrButton.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        qrButton.titleLabel?.font = Theme.heading(15)
        qrButton.tintColor = Theme.accentBlue
        qrButton.backgroundColor = Theme.accentBlue.withAlphaComponent(0.08)
        qrButton.layer.cornerRadius = 14
        qrButton.layer.cornerCurve = .continuous
        qrButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        qrButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([qrButton.heightAnchor.constraint(equalToConstant: 50)])
        contentStack.addArrangedSubview(qrButton)
    }

    private func addSectionLabel(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = Theme.caption(11)
        label.textColor = Theme.textMuted
        contentStack.addArrangedSubview(label)
        contentStack.setCustomSpacing(8, after: label)
    }

    private func makeField(_ field: UITextField, placeholder: String, icon: String, keyboard: UIKeyboardType = .default, isSecure: Bool = false) -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.backgroundPrimary
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: iconConfig))
        iconView.tintColor = Theme.textMuted
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        field.placeholder = placeholder
        field.font = Theme.body(15)
        field.textColor = Theme.textPrimary
        field.keyboardType = keyboard
        field.isSecureTextEntry = isSecure
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(field)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 46),
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            field.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            field.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        if isSecure {
            let eyeBtn = UIButton(type: .system)
            eyeBtn.setImage(UIImage(systemName: "eye.fill"), for: .normal)
            eyeBtn.tintColor = Theme.textMuted
            eyeBtn.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
            eyeBtn.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(eyeBtn)
            NSLayoutConstraint.activate([
                eyeBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
                eyeBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                eyeBtn.widthAnchor.constraint(equalToConstant: 30)
            ])
            field.trailingAnchor.constraint(equalTo: eyeBtn.leadingAnchor, constant: -4).isActive = true
        }

        return container
    }

    private func makeProtocolButton(_ proto: ProxyProtocol) -> UIButton {
        let btn = UIButton(type: .system)
        var icon: String
        var subtitle: String
        switch proto {
        case .h2:
            icon = "bolt.shield.fill"
            subtitle = "Fast, encrypted, bypasses blocks"
        case .socks5:
            icon = "network"
            subtitle = "Universal, low overhead"
        case .http:
            icon = "globe"
            subtitle = "Classic HTTP CONNECT proxy"
        }
        btn.tag = ProxyProtocol.allCases.firstIndex(of: proto) ?? 0

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let img = UIImage(systemName: icon, withConfiguration: config)

        let container = UIView()
        container.isUserInteractionEnabled = false
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconIV = UIImageView(image: img)
        iconIV.contentMode = .scaleAspectFit
        iconIV.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = proto.rawValue
        titleLbl.font = Theme.heading(14)

        let subLbl = UILabel()
        subLbl.text = subtitle
        subLbl.font = Theme.body(12)
        subLbl.textColor = Theme.textSecondary
        subLbl.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLbl, subLbl])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        btn.addSubview(container)
        container.addSubview(iconIV)
        container.addSubview(textStack)

        NSLayoutConstraint.activate([
            btn.heightAnchor.constraint(equalToConstant: 56),
            container.topAnchor.constraint(equalTo: btn.topAnchor),
            container.leadingAnchor.constraint(equalTo: btn.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: btn.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: btn.bottomAnchor),
            iconIV.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            iconIV.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 24),
            textStack.leadingAnchor.constraint(equalTo: iconIV.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])

        btn.layer.cornerRadius = 12
        btn.layer.cornerCurve = .continuous
        btn.addTarget(self, action: #selector(protocolTapped(_:)), for: .touchUpInside)

        return btn
    }

    private func updateProtocolSelection() {
        for (proto, btn) in protocolButtons {
            let selected = proto == selectedProtocol
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                if selected {
                    btn.backgroundColor = Theme.accentBlue.withAlphaComponent(0.12)
                    btn.layer.borderWidth = 1.5
                    btn.layer.borderColor = Theme.accentBlue.cgColor
                } else {
                    btn.backgroundColor = Theme.backgroundPrimary
                    btn.layer.borderWidth = 0
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func protocolTapped(_ sender: UIButton) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        selectedProtocol = ProxyProtocol.allCases[sender.tag]
        updateProtocolSelection()
    }

    @objc private func authToggled() {
        authEnabled = authSwitch.isOn
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.authFieldsStack.isHidden = !self.authEnabled
            self.authFieldsStack.alpha = self.authEnabled ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        passwordField.isSecureTextEntry.toggle()
        let icon = passwordField.isSecureTextEntry ? "eye.fill" : "eye.slash.fill"
        sender.setImage(UIImage(systemName: icon), for: .normal)
    }

    @objc private func save() {
        let h = hostField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !h.isEmpty else {
            shakeField(hostField.superview!)
            return
        }

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)

        let server = ServerConfig(
            name: (nameField.text ?? "").isEmpty ? h : nameField.text!,
            host: h,
            port: Int(portField.text ?? "443") ?? 443,
            protocolType: selectedProtocol,
            username: authEnabled ? usernameField.text : nil,
            password: authEnabled ? passwordField.text : nil
        )
        ServerStore.shared.add(server)
        navigationController?.popViewController(animated: true)
    }

    private func shakeField(_ view: UIView) {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.duration = 0.4
        anim.values = [-8, 8, -6, 6, -3, 3, 0]
        view.layer.add(anim, forKey: "shake")

        view.layer.borderWidth = 1
        view.layer.borderColor = Theme.accentRed.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.3) {
                view.layer.borderWidth = 0
            }
        }
    }
}
