import UIKit

class ServerListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var servers: [ServerConfig] = []
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.backgroundPrimary
        setupNavBar()
        setupTableView()
        setupEmptyState()
        reload()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .serversDidChange, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        for (i, cell) in tableView.visibleCells.enumerated() {
            Theme.fadeIn(cell, delay: Double(i) * 0.05)
        }
    }

    private func setupNavBar() {
        title = "Servers"
        navigationController?.setNavigationBarHidden(false, animated: true)
        navigationController?.navigationBar.prefersLargeTitles = true

        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus.circle.fill"), style: .plain, target: self, action: #selector(addServer))
        addButton.tintColor = Theme.accentBlue
        navigationItem.rightBarButtonItem = addButton
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
        tableView.register(ServerCell.self, forCellReuseIdentifier: ServerCell.id)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyLabel.text = "No servers yet.\nTap + to add one."
        emptyLabel.font = Theme.body(15)
        emptyLabel.textColor = Theme.textMuted
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func reload() {
        servers = ServerStore.shared.servers
        emptyLabel.isHidden = !servers.isEmpty
        tableView.reloadData()
    }

    @objc private func addServer() {
        let vc = AddServerViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { servers.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ServerCell.id, for: indexPath) as! ServerCell
        cell.configure(with: servers[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 82 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let server = servers[indexPath.row]

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        ServerStore.shared.setActive(id: server.id)

        if let cell = tableView.cellForRow(at: indexPath) {
            Theme.springAnimate(0.3, damping: 0.8, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            }) { _ in
                Theme.springAnimate(0.3, damping: 0.8, animations: {
                    cell.transform = .identity
                })
            }
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self = self else { return }
            ServerStore.shared.delete(id: self.servers[indexPath.row].id)
            completion(true)
        }
        delete.image = UIImage(systemName: "trash.fill")
        delete.backgroundColor = Theme.accentRed
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Server Cell

class ServerCell: UITableViewCell {
    static let id = "ServerCell"

    private let card = UIView()
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let protocolBadge = UILabel()
    private let checkView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        Theme.styleCard(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        iconContainer.backgroundColor = Theme.accentBlue.withAlphaComponent(0.1)
        iconContainer.layer.cornerRadius = 12
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconContainer)

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        iconView.image = UIImage(systemName: "bolt.shield.fill", withConfiguration: config)
        iconView.tintColor = Theme.accentBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)

        nameLabel.font = Theme.heading(16)
        nameLabel.textColor = Theme.textPrimary
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

        detailLabel.font = Theme.body(13)
        detailLabel.textColor = Theme.textSecondary
        detailLabel.numberOfLines = 1
        detailLabel.lineBreakMode = .byTruncatingMiddle
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(detailLabel)

        protocolBadge.font = Theme.caption(10)
        protocolBadge.textColor = Theme.accentCyan
        protocolBadge.backgroundColor = Theme.accentCyan.withAlphaComponent(0.1)
        protocolBadge.layer.cornerRadius = 6
        protocolBadge.layer.cornerCurve = .continuous
        protocolBadge.clipsToBounds = true
        protocolBadge.textAlignment = .center
        protocolBadge.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(protocolBadge)

        let checkConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        checkView.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConfig)
        checkView.tintColor = Theme.accentGreen
        checkView.translatesAutoresizingMaskIntoConstraints = false
        checkView.isHidden = true
        card.addSubview(checkView)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            iconContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconContainer.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 42),
            iconContainer.heightAnchor.constraint(equalToConstant: 42),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkView.leadingAnchor, constant: -8),

            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: protocolBadge.leadingAnchor, constant: -8),

            protocolBadge.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
            protocolBadge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            protocolBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            protocolBadge.heightAnchor.constraint(equalToConstant: 20),

            checkView.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            checkView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
        ])
    }

    func configure(with server: ServerConfig) {
        nameLabel.text = server.name
        detailLabel.text = "\(server.host):\(server.port)"
        protocolBadge.text = "  \(server.protocolType.rawValue)  "
        checkView.isHidden = !server.isActive

        if server.isActive {
            card.layer.borderWidth = 1.5
            card.layer.borderColor = Theme.accentGreen.withAlphaComponent(0.4).cgColor
        } else {
            card.layer.borderWidth = 0
        }

        switch server.protocolType {
        case .h2:
            iconView.image = UIImage(systemName: "bolt.shield.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
            iconView.tintColor = Theme.accentBlue
            iconContainer.backgroundColor = Theme.accentBlue.withAlphaComponent(0.1)
            protocolBadge.textColor = Theme.accentBlue
            protocolBadge.backgroundColor = Theme.accentBlue.withAlphaComponent(0.1)
        case .socks5:
            iconView.image = UIImage(systemName: "network", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
            iconView.tintColor = Theme.accentCyan
            iconContainer.backgroundColor = Theme.accentCyan.withAlphaComponent(0.1)
            protocolBadge.textColor = Theme.accentCyan
            protocolBadge.backgroundColor = Theme.accentCyan.withAlphaComponent(0.1)
        case .http:
            iconView.image = UIImage(systemName: "globe", withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium))
            iconView.tintColor = Theme.accentOrange
            iconContainer.backgroundColor = Theme.accentOrange.withAlphaComponent(0.1)
            protocolBadge.textColor = Theme.accentOrange
            protocolBadge.backgroundColor = Theme.accentOrange.withAlphaComponent(0.1)
        }
    }
}
