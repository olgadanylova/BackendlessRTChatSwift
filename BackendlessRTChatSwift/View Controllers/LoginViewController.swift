
import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loginField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var rememberMeSwitch: UISwitch!
    
    private let backendless = Backendless.sharedInstance()!
    private let HOST_URL = "http://apitest.backendless.com"
    private let APP_ID = "A81AB58A-FC85-EF00-FFE4-1A1C0FEADB00"
    private let API_KEY = "FE202648-517E-B0A5-FF89-CBA9D7DFDD00"
    
    private var timer: Timer?
    private var activeField: UITextField?
    private var onError: ((Fault?) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backendless.hostURL = HOST_URL
        backendless.initApp(APP_ID, apiKey: API_KEY)
        
        guard backendless.userService.currentUser == nil else {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(showChats), userInfo: nil, repeats: false)
            return
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
        
        onError = { (fault: Fault?) -> Void in
            AlertController.showErrorAlert(fault: fault!, target: self, handler: nil)
        }
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
    
    @objc func keyboardDidShow(notification: NSNotification) {
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
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
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
        guard let nextField = passwordField.superview?.viewWithTag(textField.tag + 1) as! UITextField? else {
            textField.becomeFirstResponder()
            view.endEditing(true)
            return false
        }
        nextField.becomeFirstResponder()
        return false
    }
    
    @IBAction func prepareForUnwindToLoginVC(segue:UIStoryboardSegue) {
        backendless.userService.logout({ }, error: onError)
    }
    
    @IBAction func pressedLogin(_ sender: Any) {
        if (rememberMeSwitch.isOn) {
            backendless.userService.setStayLoggedIn(true)
        }
        else {
            backendless.userService.setStayLoggedIn(false)
        }
        backendless.userService.login(loginField.text, password: passwordField.text, response: {
            currentUser in
            self.showChats()
        }, error: onError)
    }
    
    @IBAction func pressedSignUp(_ sender: Any) {
        let newUser = BackendlessUser()
        newUser.email = loginField.text! as NSString
        newUser.password = passwordField.text! as NSString
        backendless.userService.register(newUser, response: { registeredUser in
            AlertController.showAlertWithTitle(title: "Registration complete", message: String(format:"You have been registered as %@", (registeredUser?.email)!), target: self, handler: { alertAction in self.showChats()
            })            
        }, error: onError)
    }
}
