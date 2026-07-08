import UIKit
import ObjectiveC

private var navRowActionKey: UInt8 = 0

private class ClosureWrapper {
    let closure: () -> Void
    init(_ closure: @escaping () -> Void) { self.closure = closure }
}

class SettingsViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let connectionSettings: [(title: String, icon: String, key: String)] = [
        ("Auto-connect on launch", "bolt.fill", "autoConnect"),
        ("Kill switch", "shield.lefthalf.filled", "killSwitch"),
        ("DNS leak protection", "lock.shield.fill", "dnsProtection")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.backgroundPrimary
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

        // Connection section
        addSectionLabel("CONNECTION")
        let connCard = UIView()
        Theme.styleCard(connCard)
        let connStack = UIStackView()
        connStack.axis = .vertical
        connStack.spacing = 0
        connStack.translatesAutoresizingMaskIntoConstraints = false
        connCard.addSubview(connStack)
        NSLayoutConstraint.activate([
            connStack.topAnchor.constraint(equalTo: connCard.topAnchor, constant: 6),
            connStack.leadingAnchor.constraint(equalTo: connCard.leadingAnchor),
            connStack.trailingAnchor.constraint(equalTo: connCard.trailingAnchor),
            connStack.bottomAnchor.constraint(equalTo: connCard.bottomAnchor, constant: -6)
        ])

        for (i, setting) in connectionSettings.enumerated() {
            let row = makeToggleRow(title: setting.title, icon: setting.icon, key: setting.key)
            connStack.addArrangedSubview(row)
            if i < connectionSettings.count - 1 {
                let sep = UIView()
                sep.backgroundColor = Theme.separator
                sep.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([sep.heightAnchor.constraint(equalToConstant: 1)])
                connStack.addArrangedSubview(sep)
            }
        }
        contentStack.addArrangedSubview(connCard)

        // About section
        addSectionLabel("ABOUT")
        let aboutCard = UIView()
        Theme.styleCard(aboutCard)
        let aboutStack = UIStackView()
        aboutStack.axis = .vertical
        aboutStack.spacing = 0
        aboutStack.translatesAutoresizingMaskIntoConstraints = false
        aboutCard.addSubview(aboutStack)
        NSLayoutConstraint.activate([
            aboutStack.topAnchor.constraint(equalTo: aboutCard.topAnchor, constant: 6),
            aboutStack.leadingAnchor.constraint(equalTo: aboutCard.leadingAnchor),
            aboutStack.trailingAnchor.constraint(equalTo: aboutCard.trailingAnchor),
            aboutStack.bottomAnchor.constraint(equalTo: aboutCard.bottomAnchor, constant: -6)
        ])

        aboutStack.addArrangedSubview(makeInfoRow(title: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", icon: "info.circle.fill"))

        let sep2 = UIView()
        sep2.backgroundColor = Theme.separator
        sep2.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([sep2.heightAnchor.constraint(equalToConstant: 1)])
        aboutStack.addArrangedSubview(sep2)

        aboutStack.addArrangedSubview(makeNavRow(title: "Connection logs", icon: "doc.text.fill") { [weak self] in
            let vc = LogsViewController()
            self?.navigationController?.pushViewController(vc, animated: true)
        })

        contentStack.addArrangedSubview(aboutCard)
    }

    private func addSectionLabel(_ text: String) {
        let label = UILabel()
        label.text = text
        label.font = Theme.caption(11)
        label.textColor = Theme.textMuted
        contentStack.addArrangedSubview(label)
        contentStack.setCustomSpacing(8, after: label)
    }

    private func makeToggleRow(title: String, icon: String, key: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([row.heightAnchor.constraint(equalToConstant: 52)])

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        iconView.tintColor = Theme.accentBlue
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = Theme.body(15)
        label.textColor = Theme.textPrimary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.onTintColor = Theme.accentBlue
        toggle.isOn = UserDefaults.standard.bool(forKey: "h2proxy.\(key)")
        toggle.accessibilityIdentifier = key
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(iconView)
        row.addSubview(label)
        row.addSubview(toggle)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -12),
            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -18),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func makeInfoRow(title: String, value: String, icon: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([row.heightAnchor.constraint(equalToConstant: 52)])

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        iconView.tintColor = Theme.accentBlue
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = Theme.body(15)
        label.textColor = Theme.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = Theme.mono(14)
        valueLabel.textColor = Theme.textSecondary
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(iconView)
        row.addSubview(label)
        row.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -18),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func makeNavRow(title: String, icon: String, action: @escaping () -> Void) -> UIView {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([btn.heightAnchor.constraint(equalToConstant: 52)])

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        iconView.tintColor = Theme.accentBlue
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = Theme.body(15)
        label.textColor = Theme.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        let chevConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let chev = UIImageView(image: UIImage(systemName: "chevron.right", withConfiguration: chevConfig))
        chev.tintColor = Theme.textMuted
        chev.translatesAutoresizingMaskIntoConstraints = false

        btn.addSubview(iconView)
        btn.addSubview(label)
        btn.addSubview(chev)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 18),
            iconView.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
            chev.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -18),
            chev.centerYAnchor.constraint(equalTo: btn.centerYAnchor)
        ])

        objc_setAssociatedObject(btn, &navRowActionKey, ClosureWrapper(action), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        btn.addTarget(self, action: #selector(navRowTapped(_:)), for: .touchUpInside)
        return btn
    }

    @objc private func navRowTapped(_ sender: UIButton) {
        guard let wrapper = objc_getAssociatedObject(sender, &navRowActionKey) as? ClosureWrapper else { return }
        wrapper.closure()
    }

    @objc private func toggleChanged(_ toggle: UISwitch) {
        guard let key = toggle.accessibilityIdentifier else { return }
        UserDefaults.standard.set(toggle.isOn, forKey: "h2proxy.\(key)")
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}
