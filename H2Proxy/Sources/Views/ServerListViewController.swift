import UIKit

class ServerListViewController: UITableViewController {

    private var servers: [ServerConfig] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Servers"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addServer))
        reload()
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .serversDidChange, object: nil)
    }

    @objc private func reload() {
        servers = ServerStore.shared.servers
        tableView.reloadData()
    }

    @objc private func addServer() {
        let vc = AddServerViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        servers.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let server = servers[indexPath.row]
        cell.textLabel?.text = server.name
        cell.detailTextLabel?.text = "\(server.host):\(server.port) · \(server.protocolType.rawValue)"
        cell.accessoryType = server.isActive ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        ServerStore.shared.setActive(id: servers[indexPath.row].id)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            ServerStore.shared.delete(id: servers[indexPath.row].id)
        }
    }
}
