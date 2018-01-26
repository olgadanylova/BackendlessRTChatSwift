
import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    
    let backendless = Backendless.sharedInstance()!
    let HOST_URL = "http://localhost:9000"
    let APP_ID = "A9D1448F-6BBE-97DC-FFC8-B4F8FD449B00"
    let API_KEY = "7E03B9EC-B744-DFBD-FF25-EAF950A53900"
    
    private var timer: Timer?
    private var activeField: UITextField?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backendless.hostURL = HOST_URL
        backendless.initApp(APP_ID, apiKey: API_KEY)
        
        if (backendless.userService.currentUser != nil) {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(showChats), userInfo: nil, repeats: false)
        }
        
        loginField.delegate = self
        loginField.tag = 0
        passwordField.delegate = self
        passwordField.tag = 1
        
        let singleTapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(singleTap(gesture:)))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.isEnabled = true
        singleTapGestureRecognizer.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(singleTapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name:.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name:.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc private func showChats() {
        performSegue(withIdentifier: "ShowChats", sender: nil)
    }
    
    @objc private func singleTap(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc private func keyboardDidShow(notification: NSNotification) {
        let keyboardRect = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! CGRect
        let contentInsets = UIEdgeInsetsMake(0, 0, keyboardRect.size.height, 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
        var viewFrame = view.frame
        viewFrame.size.height -= keyboardRect.size.height
        if (!viewFrame.contains((activeField?.frame.origin)!)) {
            scrollView.scrollRectToVisible((activeField?.frame)!, animated: true)
        }
    }
    
    @objc private func keyboardWillBeHidden(notification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        activeField = nil
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (passwordField.superview?.viewWithTag(textField.tag + 1) != nil) {
            let nextField = passwordField.superview?.viewWithTag(textField.tag + 1) as! UITextField
            nextField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return false;
    }
    
    @IBAction func prepareForUnwindToLoginVC(segue:UIStoryboardSegue) {
        backendless.userService .logout({ loggedOut in
        }, error: { fault in AlertController.showErrorAlert(fault: fault!, target: self)
        })
    }
    
    @IBAction func pressedLogin(_ sender: Any) {
        if (rememberMeSwitch.isOn) {
            backendless.userService.setStayLoggedIn(true)
        }
        else {
            backendless.userService.setStayLoggedIn(false)
        }
        backendless.userService.login(loginField.text, password: passwordField.text, response: {
            currentUser in self.showChats()
        }, error: {
            fault in AlertController.showErrorAlert(fault: fault!, target: self)
        })
    }
    
    @IBAction func pressedSignUp(_ sender: Any) {
        let newUser = BackendlessUser()
        newUser.email = loginField.text! as NSString
        newUser.password = passwordField.text! as NSString
        backendless.userService.register(newUser, response: { registeredUser in
            AlertController.showAlertWithTitle(title: "Registration complete", message: String(format:"You have been ergistered as %@", (registeredUser?.email)!), target: self, handler: { alertAction in self.showChats()
            })            
        }, error: { fault in AlertController.showErrorAlert(fault: fault!, target: self)
        })
    }
}