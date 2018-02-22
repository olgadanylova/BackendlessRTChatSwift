
import UIKit

class ChatDetailsViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var chatNameField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var membersButton: UIBarButtonItem!
    
    var chat: Chat?
    var channel: Channel?
    
    private var timer: Timer?
    private var activeField: UITextField?
    private var onError: ((Fault?) -> Void)!
    
    let backendless = Backendless.sharedInstance()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatNameField.delegate = self
        chatNameField.tag = 0
        chatNameField.addTarget(self, action: #selector(chatNameFieldDidChange(textField:)), for: .editingChanged)
        
        navigationItem.title = chat?.name.appending(" Details")
        chatNameField.text = chat?.name
        chatNameField.returnKeyType = .done
        
        saveButton.isEnabled = false
        deleteButton.isEnabled = false
        chatNameField.isEnabled = false
        
        if (chat?.ownerId == backendless.userService.currentUser.objectId as String) {
            print("current = \(backendless.userService.currentUser.objectId as String)")
            saveButton.isEnabled = true
            deleteButton.isEnabled = true
            chatNameField.isEnabled = true
        }
        
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc private func chatNameFieldDidChange(textField: UITextField) {
        if (!textField.text!.isEmpty) {
            if (textField.text != chat?.name) {
                saveButton.isEnabled = true
            }
            else {
                saveButton.isEnabled = false
            }
        }
        else {
            saveButton.isEnabled = false
        }
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
        
        if (activeField != nil) {
            print ("active field")
        }
        else {
            print ("no active field")
        }
        
        
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
        textField.resignFirstResponder()
        return true
    }
    
    @objc private func saveChat() {
        if (chatNameField.text!.count > 0) {
            if (chatNameField.text != chat?.name) {
                chat?.name = chatNameField.text
                backendless.data.of(Chat.ofClass()).save(
                    chat,
                    response: { updatedChat in
                        AlertController.showAlertWithTitle(title: "Chat updated",
                                                           message: String(format:"'%@' successfully updated", (updatedChat as! Chat).name),
                                                           target: self,
                                                           handler: { alertAction in self.performSegue(withIdentifier: "UnwindToChatAfterSave", sender: nil)
                        })
                }, error: onError)
            }
            else if (chatNameField.text == chat?.name) {
                AlertController.showAlertWithTitle(title: "Update failed", message: "Please change chat name to update", target: self, handler: nil)
            }
            else if (chatNameField.text!.count == 0) {
                AlertController.showAlertWithTitle(title: "Update failed", message: "Please enter the correct chat name", target: self, handler: nil)
            }
            
        }
    }
    
    @objc private func deleteChat() {
        let name = chat?.name
        backendless.data.of(Chat.ofClass()).remove(
            chat,
            response: { deletedChat in
                AlertController.showAlertWithTitle(title: "Chat deleted",
                                                   message: String(format:"'%@' successfully deleted", name!),
                                                   target: self,
                                                   handler: { alertAction in
                                                    self.channel?.removeAllListeners()
                                                    self.performSegue(withIdentifier: "UnwindToChatAfterDelete", sender: nil)
                })
        }, error: onError)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowMembers") {
            let membersVC = segue.destination as! MembersViewController
            membersVC.channel = channel
        }
    }
    
    @IBAction func pressedSave(_ sender: Any) {
        view.endEditing(true)
        saveChat()
    }
    
    @IBAction func pressedDelete(_ sender: Any) {
        view.endEditing(true)
        deleteChat()
    }
    
    @IBAction func pressedMembers(_ sender: Any) {
        performSegue(withIdentifier: "ShowMembers", sender: sender)
    }
}
