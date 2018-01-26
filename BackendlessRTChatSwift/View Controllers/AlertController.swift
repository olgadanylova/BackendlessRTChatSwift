
import UIKit

class AlertController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    class func showErrorAlert(fault: Fault, target: UIViewController) {
        var errorTitle = "Error"
        if (fault.faultCode != nil) {
            errorTitle = String(format:"Error %@", fault.faultCode)
        }
        let alert = UIAlertController.init(title: errorTitle, message: fault.message, preferredStyle: .alert)
        let dismissAction = UIAlertAction.init(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(dismissAction)
        target.present(alert, animated: true, completion: nil)
    }
    
    class func showAlertWithTitle(title: String, message: String, target: UIViewController, handler:  ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let chatsAction = UIAlertAction.init(title: "OK", style: .default, handler: handler)
        alert.addAction(chatsAction)
        target.present(alert, animated: true, completion: nil)
    }
}
