import UIKit

class AddServerViewController: UITableViewController {

    private var name = ""
    private var host = ""
    private var port = "443"
    private var selectedProtocol: ProxyProtocol = .h2
    private var username = ""
    private var password = ""
    private var authEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add server"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(save))
        tableView = UITableView(frame: .zero, style: .insetGrouped)
    }

    @objc private func save() {
        guard !host.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Host is required.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let server = ServerConfig(
            name: name.isEmpty ? host : name,
            host: host,
            port: Int(port) ?? 443,
            protocolType: selectedProtocol,
            username: authEnabled ? username : nil,
            password: authEnabled ? password : nil
        )
        ServerStore.shared.add(server)
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // name, host, port, protocol
        case 1: return authEnabled ? 3 : 1 // toggle, user, pass
        case 2: return 1 // import QR
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Server"
        case 1: return "Authentication"
        case 2: return "Import"
        default: return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return makeTextFieldCell(
                placeholder: ["Name", "Host", "Port", "Protocol"][indexPath.row],
                value: [name, host, port, selectedProtocol.rawValue][indexPath.row],
                tag: indexPath.row
            )
        case 1:
            if indexPath.row == 0 {
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Authentication"
                let toggle = UISwitch()
                toggle.isOn = authEnabled
                toggle.addTarget(self, action: #selector(authToggled(_:)), for: .valueChanged)
                cell.accessoryView = toggle
                cell.selectionStyle = .none
                return cell
            }
            return makeTextFieldCell(
                placeholder: indexPath.row == 1 ? "Username" : "Password",
                value: indexPath.row == 1 ? username : password,
                tag: 10 + indexPath.row,
                isSecure: indexPath.row == 2
            )
        case 2:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = "Import from QR code"
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.textAlignment = .center
            return cell
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 && indexPath.row == 3 {
            showProtocolPicker()
        }
    }

    private func makeTextFieldCell(placeholder: String, value: String, tag: Int, isSecure: Bool = false) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let field = UITextField()
        field.placeholder = placeholder
        field.text = value
        field.tag = tag
        field.isSecureTextEntry = isSecure
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)
        field.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(field)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            field.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8),
            field.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16)
        ])
        if tag == 3 {
            field.isEnabled = false
            cell.accessoryType = .disclosureIndicator
        }
        cell.selectionStyle = tag == 3 ? .default : .none
        return cell
    }

    @objc private func textChanged(_ field: UITextField) {
        switch field.tag {
        case 0: name = field.text ?? ""
        case 1: host = field.text ?? ""
        case 2: port = field.text ?? ""
        case 11: username = field.text ?? ""
        case 12: password = field.text ?? ""
        default: break
        }
    }

    @objc private func authToggled(_ toggle: UISwitch) {
        authEnabled = toggle.isOn
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }

    private func showProtocolPicker() {
        let ac = UIAlertController(title: "Protocol", message: nil, preferredStyle: .actionSheet)
        for proto in ProxyProtocol.allCases {
            ac.addAction(UIAlertAction(title: proto.rawValue, style: .default) { [weak self] _ in
                self?.selectedProtocol = proto
                self?.tableView.reloadData()
            })
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
}
