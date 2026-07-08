import UIKit

class SettingsViewController: UITableViewController {

    private let sections = ["Connection", "About"]
    private let items: [[String]] = [
        ["Auto-connect on launch", "Kill switch", "DNS leak protection"],
        ["Version", "Logs"]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView = UITableView(frame: .zero, style: .insetGrouped)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { sections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items[section].count }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { sections[section] }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let item = items[indexPath.section][indexPath.row]
        cell.textLabel?.text = item

        if indexPath.section == 0 {
            let toggle = UISwitch()
            toggle.isOn = UserDefaults.standard.bool(forKey: "h2proxy.\(item)")
            toggle.tag = indexPath.row
            toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
        } else if item == "Version" {
            cell.detailTextLabel?.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            cell.selectionStyle = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 1 {
            let vc = LogsViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc private func toggleChanged(_ toggle: UISwitch) {
        let key = "h2proxy.\(items[0][toggle.tag])"
        UserDefaults.standard.set(toggle.isOn, forKey: key)
    }
}
