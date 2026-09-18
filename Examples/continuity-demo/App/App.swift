import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = JourneyController()
        window?.makeKeyAndVisible()
        return true
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
