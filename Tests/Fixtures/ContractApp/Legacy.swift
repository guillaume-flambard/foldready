import UIKit

final class Legacy: UIViewController {
    func layout() {
        let width = UIScreen.main.bounds.width
        view.frame = CGRect(x: 0, y: 0, width: width, height: 100)
        if UIDevice.current.userInterfaceIdiom == .pad {
            view.backgroundColor = .systemBackground
        }
    }
}
