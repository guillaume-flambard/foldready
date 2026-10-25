import UIKit

// Since iOS 27, apps linked against the current UIKit SDK must use UIScene.
// Building a UIWindow with UIScreen.main in AppDelegate crashes on launch.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration",
                                                sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = JourneyController()
        window.makeKeyAndVisible()
        self.window = window
    }
}

/// Deliberately small UI with synthetic data. Broken behavior is opt-in at launch.
final class JourneyController: UIViewController {
    private let journey = ProcessInfo.processInfo.environment["FR_JOURNEY"] ?? "form"
    private let broken = ProcessInfo.processInfo.environment["FR_VARIANT"] == "broken"
    private var step = 0
    private var values = ["name": "", "details": "", "quantity": "0", "orders": "0",
                          "body": "", "saves": "0"]
    private var labels: [String: UILabel] = [:]
    private let geometry = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])
        let heading = UILabel()
        heading.text = "Continuity demo: \(journey) / \(broken ? "broken" : "fixed")"
        heading.font = .preferredFont(forTextStyle: .headline)
        stack.addArrangedSubview(heading)
        let explanation = UILabel()
        explanation.text = "Synthetic data. Tap each step, then rotate. Broken mode injects a lifecycle defect."
        explanation.numberOfLines = 0
        stack.addArrangedSubview(explanation)
        let keys: [String]
        let titles: [String]
        switch journey {
        case "cart": keys = ["quantity", "orders"]; titles = ["Add one item", "Place order once"]
        case "draft": keys = ["body", "saves"]; titles = ["Write draft", "Save draft once"]
        default: keys = ["name", "details"]; titles = ["Enter Ada", "Enter delivery details"]
        }
        for key in keys {
            let label = UILabel()
            label.accessibilityIdentifier = key
            label.isAccessibilityElement = true
            labels[key] = label
            stack.addArrangedSubview(label)
        }
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.accessibilityIdentifier = "step\(index + 1)"
            button.tag = index + 1
            button.addTarget(self, action: #selector(advance(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
        let reset = UIButton(type: .system)
        reset.setTitle("Reset synthetic fixture", for: .normal)
        reset.accessibilityIdentifier = "reset"
        reset.addTarget(self, action: #selector(resetFixture), for: .touchUpInside)
        stack.addArrangedSubview(reset)
        let listDemo = UIButton(type: .system)
        listDemo.setTitle("Open synthetic list journey", for: .normal)
        listDemo.accessibilityIdentifier = "openListDemo"
        listDemo.addTarget(self, action: #selector(openListDemo), for: .touchUpInside)
        stack.addArrangedSubview(listDemo)
        geometry.accessibilityIdentifier = "geometry"
        geometry.isAccessibilityElement = true
        stack.addArrangedSubview(geometry)
        refresh()
    }

    @objc private func advance(_ button: UIButton) {
        step = button.tag
        switch journey {
        case "cart":
            if step == 1 { values["quantity"] = "1" }
            else { values["orders"] = String(Int(values["orders"]!)! + 1) }
        case "draft":
            if step == 1 { values["body"] = "Delivery notes" }
            else { values["saves"] = String(Int(values["saves"]!)! + 1) }
        default:
            values[step == 1 ? "name" : "details"] = step == 1 ? "Ada" : "12 Test Street"
        }
        refresh()
    }

    @objc private func openListDemo() {
        let list = ListContinuityController()
        list.modalPresentationStyle = .fullScreen
        present(list, animated: false)
    }

    @objc private func resetFixture() {
        step = 0
        values = ["name": "", "details": "", "quantity": "0", "orders": "0", "body": "", "saves": "0"]
        refresh()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if broken && step > 0 {
            switch journey {
            case "cart":
                if step == 2 { values["orders"] = String(Int(values["orders"]!)! + 1) }
            case "draft": values["body"] = ""
            default: values["name"] = ""
            }
            refresh()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        geometry.text = "Window: \(Int(view.bounds.width)) x \(Int(view.bounds.height))"
        geometry.accessibilityValue = view.bounds.width > view.bounds.height ? "landscape" : "portrait"
    }

    private func refresh() {
        for (key, label) in labels {
            label.text = "\(key): \(values[key]!)"
            label.accessibilityValue = values[key]!
        }
    }
}


/// An actual, scrollable UIKit table. The selected row and content offset
/// are measured across the Duo's cover/inner/cover geometry transitions.
/// This is synthetic test content, not an existing customer app.
final class ListContinuityController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let count = 80
    private let table = UITableView(frame: .zero, style: .plain)
    private let selectedLabel = UILabel()
    private let offsetLabel = UILabel()
    private let geometry = UILabel()
    private var selection: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let title = UILabel()
        title.text = "Continuity demo: list / fixed"
        title.font = .preferredFont(forTextStyle: .headline)
        title.accessibilityIdentifier = "listHeading"

        selectedLabel.accessibilityIdentifier = "listSelected"
        selectedLabel.isAccessibilityElement = true
        offsetLabel.accessibilityIdentifier = "listOffset"
        offsetLabel.isAccessibilityElement = true
        geometry.accessibilityIdentifier = "geometry"
        geometry.isAccessibilityElement = true

        let jump = UIButton(type: .system)
        jump.setTitle("Scroll to item 70", for: .normal)
        jump.accessibilityIdentifier = "listJumpTo70"
        jump.addTarget(self, action: #selector(jumpTo70), for: .touchUpInside)

        table.register(UITableViewCell.self, forCellReuseIdentifier: "item")
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 44
        table.accessibilityIdentifier = "listTable"

        let heading = UIStackView(arrangedSubviews: [title, selectedLabel, offsetLabel, jump, geometry])
        heading.axis = .vertical
        heading.spacing = 8
        heading.translatesAutoresizingMaskIntoConstraints = false
        table.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heading)
        view.addSubview(table)
        NSLayoutConstraint.activate([
            heading.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            heading.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            heading.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            table.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 8),
            table.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            table.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            table.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        updateObservedState()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item", for: indexPath)
        cell.textLabel?.text = "Item \(indexPath.row)"
        cell.accessibilityIdentifier = "listItem-\(indexPath.row)"
        cell.isAccessibilityElement = true
        cell.accessoryType = indexPath.row == selection ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selection = indexPath.row
        tableView.reloadData()
        updateObservedState()
    }

    @objc private func jumpTo70() {
        table.layoutIfNeeded()
        table.scrollToRow(at: IndexPath(row: 70, section: 0), at: .middle, animated: false)
        updateObservedState()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateObservedState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        geometry.text = "Window: \(Int(view.bounds.width)) x \(Int(view.bounds.height))"
        updateObservedState()
    }

    private func updateObservedState() {
        let value = selection.map { "Item \($0)" } ?? "none"
        selectedLabel.text = "Selected: \(value)"
        selectedLabel.accessibilityValue = value
        let offset = String(Int(table.contentOffset.y.rounded()))
        offsetLabel.text = "Scroll offset: \(offset)"
        offsetLabel.accessibilityValue = offset
    }
}
