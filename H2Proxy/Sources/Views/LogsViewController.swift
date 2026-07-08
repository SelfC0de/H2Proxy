import UIKit

struct LogEntry {
    let timestamp: Date
    let message: String
    let isBlocked: Bool
}

class LogsViewController: UITableViewController {

    static var entries: [LogEntry] = []

    static func log(_ message: String, blocked: Bool = false) {
        let entry = LogEntry(timestamp: Date(), message: message, isBlocked: blocked)
        entries.insert(entry, at: 0)
        if entries.count > 500 { entries.removeLast() }
        NotificationCenter.default.post(name: .logsDidUpdate, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Logs"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "log")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLogs))
        NotificationCenter.default.addObserver(self, selector: #selector(reloadLogs), name: .logsDidUpdate, object: nil)
    }

    @objc private func clearLogs() {
        LogsViewController.entries.removeAll()
        tableView.reloadData()
    }

    @objc private func reloadLogs() {
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        LogsViewController.entries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "log", for: indexPath)
        let entry = LogsViewController.entries[indexPath.row]
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: entry.timestamp)
        cell.textLabel?.text = "\(time) \(entry.message)"
        cell.textLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        cell.textLabel?.textColor = entry.isBlocked ? .systemOrange : .label
        cell.selectionStyle = .none
        return cell
    }
}

extension Notification.Name {
    static let logsDidUpdate = Notification.Name("h2proxy.logsDidUpdate")
}
