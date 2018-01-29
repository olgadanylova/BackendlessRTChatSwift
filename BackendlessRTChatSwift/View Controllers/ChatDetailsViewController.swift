
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
    
    let backendless = Backendless.sharedInstance()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatNameField.delegate = self
        chatNameField.tag = 0
        chatNameField.addTarget(self, action: #selector(chatNameFieldDidChange(textField:)), for: .editingChanged)
        
        navigationItem.title = chat?.name.appending(" Details")
        chatNameField.text = chat?.name
        
        if (chat?.ownerId == backendless.userService.currentUser.objectId as String) {
            deleteButton.isEnabled = true
            chatNameField.isEnabled = true
        }
        
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
    
    //    func resignKeyboard {
    //        view.endEditing(true)
    //    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.isTranslucent = true
        
        let fixedItem = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let saveButton = UIBarButtonItem.init(title: "Save", style: .done, target: self, action: #selector(saveChat))
        toolbar.items = [fixedItem, saveButton]
        toolbar.isUserInteractionEnabled = true
        toolbar.sizeToFit()
        textField.inputAccessoryView = toolbar
        return true
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
                }, error: { fault in
                        AlertController.showErrorAlert(fault: fault!, target: self)
                })
            }
            else if (chatNameField.text == chat?.name) {
                let fault = Fault.init(message: "Please change the chat before saving")
                AlertController.showErrorAlert(fault: fault!, target: self)
            }
            else if (chatNameField.text!.count == 0) {
                let fault = Fault.init(message: "Please enter the correct chat name")
                AlertController.showErrorAlert(fault: fault!, target: self)
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
        }, error: { fault in
            AlertController.showErrorAlert(fault: fault!, target: self)
        })
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
