
import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        DispatchQueue.main.async(execute: {() -> Void in self.preferredDisplayMode = .allVisible })
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if (secondaryViewController is UINavigationController) && (((secondaryViewController as? UINavigationController)?.topViewController) is ChatViewController) && (((secondaryViewController as? UINavigationController)?.topViewController as? ChatViewController)?.chat == nil) {
            return true
        }
        else {
            return false
        }
    }   
}
