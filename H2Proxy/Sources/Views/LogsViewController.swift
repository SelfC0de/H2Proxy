import UIKit

struct LogEntry {
    let timestamp: Date
    let message: String
    let isBlocked: Bool
}

class LogsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    static var entries: [LogEntry] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyView = UIStackView()
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    static func log(_ message: String, blocked: Bool = false) {
        let entry = LogEntry(timestamp: Date(), message: message, isBlocked: blocked)
        entries.insert(entry, at: 0)
        if entries.count > 500 { entries.removeLast() }
        NotificationCenter.default.post(name: .logsDidUpdate, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.backgroundPrimary
        title = "Logs"
        navigationController?.navigationBar.prefersLargeTitles = false

        let clearBtn = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLogs))
        clearBtn.tintColor = Theme.accentRed
        navigationItem.rightBarButtonItem = clearBtn

        setupTableView()
        setupEmptyState()
        updateEmptyState()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadLogs), name: .logsDidUpdate, object: nil)
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LogCell.self, forCellReuseIdentifier: LogCell.id)
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
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        let iconView = UIImageView(image: UIImage(systemName: "doc.text", withConfiguration: config))
        iconView.tintColor = Theme.textMuted

        let label = UILabel()
        label.text = "No logs yet"
        label.font = Theme.body(15)
        label.textColor = Theme.textMuted

        emptyView.axis = .vertical
        emptyView.alignment = .center
        emptyView.spacing = 12
        emptyView.addArrangedSubview(iconView)
        emptyView.addArrangedSubview(label)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func updateEmptyState() {
        emptyView.isHidden = !LogsViewController.entries.isEmpty
    }

    @objc private func clearLogs() {
        LogsViewController.entries.removeAll()
        tableView.reloadData()
        updateEmptyState()
    }

    @objc private func reloadLogs() {
        tableView.reloadData()
        updateEmptyState()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        LogsViewController.entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LogCell.id, for: indexPath) as! LogCell
        let entry = LogsViewController.entries[indexPath.row]
        cell.configure(time: formatter.string(from: entry.timestamp), message: entry.message, blocked: entry.isBlocked)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
}

class LogCell: UITableViewCell {
    static let id = "LogCell"

    private let timeLabel = UILabel()
    private let msgLabel = UILabel()
    private let dot = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        dot.layer.cornerRadius = 3
        dot.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dot)

        timeLabel.font = Theme.mono(11)
        timeLabel.textColor = Theme.textMuted
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(timeLabel)

        msgLabel.font = Theme.mono(12)
        msgLabel.numberOfLines = 0
        msgLabel.lineBreakMode = .byCharWrapping
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(msgLabel)

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),

            timeLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 8),
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            msgLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 10),
            msgLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            msgLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            msgLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(time: String, message: String, blocked: Bool) {
        timeLabel.text = time
        msgLabel.text = message
        if blocked {
            msgLabel.textColor = Theme.accentOrange
            dot.backgroundColor = Theme.accentOrange
        } else {
            msgLabel.textColor = Theme.textSecondary
            dot.backgroundColor = Theme.accentGreen
        }
    }
}

extension Notification.Name {
    static let logsDidUpdate = Notification.Name("h2proxy.logsDidUpdate")
}
