
import UIKit

class ChatViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var leaveChatButton: UIBarButtonItem!
    @IBOutlet weak var detailsButton: UIBarButtonItem!
    @IBOutlet weak var chatField: UITextView!
    @IBOutlet weak var userTypingLabel: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var textButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIBarButtonItem!
    
    var chat: Chat?
    var channel: Channel?
    var inputField: UITextView?
    
    private let backendless = Backendless.sharedInstance()!
    private var usersTyping: Set<String>?
    private var onError: ((Fault?) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        onError = { (fault: Fault?) -> Void in
            AlertController.showErrorAlert(fault: fault!, target: self, handler: { alertAction in
                if (self.splitViewController?.isCollapsed)! {
                    self.performSegue(withIdentifier: "UnwindToChats", sender: nil)
                }
            })
        }
        
        usersTyping = Set<String>()
        navigationItem.title = chat?.name
        userTypingLabel.isHidden = true
        leaveChatButton.isEnabled = false
        detailsButton.isEnabled = false
        textButton.isEnabled = false
        sendButton.isEnabled = false
        setupToolbarButtons()
        guard chat?.name != nil else {
            return
        }
        leaveChatButton.isEnabled = true
        detailsButton.isEnabled = true
        textButton.isEnabled = true
        channel = backendless.messaging.subscribe(chat?.objectId)
        addRTListeners()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.backBarButtonItem?.isEnabled = false
        navigationItem.hidesBackButton = true
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name:.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name:.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        inputField?.frame = CGRect(x: 0, y: 0, width: self.toolbar.frame.size.width * 0.75, height: self.toolbar.frame.size.height * 0.75)
    }
    
    private func setupToolbarButtons() {
        inputField = UITextView.init(frame: CGRect(x: 0,y: 0, width: self.toolbar.frame.size.width * 0.75, height: self.toolbar.frame.size.height * 0.75))
        inputField?.delegate = self
        inputField?.font = UIFont.systemFont(ofSize: 15)
        inputField?.layer.cornerRadius = 5.0
        inputField?.clipsToBounds = true
        inputField?.textContainer.lineBreakMode = .byTruncatingTail
        textButton.customView = inputField
    }
    
    private func addRTListeners() {
        channel?.addConnectListener({ }, error: onError)
        
        channel?.addMessageListener({ message in
            if let messageData = message?.data {
                if let messageInfo = (messageData as! [String : Any])["message"] {
                    let userEmail = (messageInfo as! [String : Any])["userEmail"] as! String
                    let text = (messageInfo as! [String : Any])["text"] as! String
                    self.putFormattedMessageIntoChatViewFromUser(userIdentity: userEmail, messageText: text)
                }
            }
        }, error: onError)
        
        self.channel?.addCommandListener({ typing in
            if (typing?.type == "USER_TYPING") {
                let user = self.backendless.userService.find(byId: typing?.userId)
                self.usersTyping?.insert((user?.email as String?)!)
                self.userTypingLabel.isHidden = false
                var usersTypingString = ""
                for userTyping in self.usersTyping! {
                    usersTypingString = usersTypingString.appending(userTyping)
                    if (userTyping != Array(self.usersTyping!).last) {
                        usersTypingString = usersTypingString.appending(", ")
                    }
                }
                self.userTypingLabel.text = String(format:"%@ typing...", usersTypingString)
            }
            else if (typing?.type == "USER_STOP_TYPING") {
                let user = self.backendless.userService.find(byId: typing?.userId)
                self.usersTyping?.remove(user!.email as String)
                if (self.usersTyping?.count == 0) {
                    self.userTypingLabel.isHidden = true
                }
                else {
                    var usersTypingString = "";
                    for userTyping in self.usersTyping! {
                        usersTypingString = usersTypingString.appending(userTyping)
                        if (userTyping != Array(self.usersTyping!).last) {
                            usersTypingString = usersTypingString.appending(", ")
                        }
                    }
                    self.userTypingLabel.text = String(format:"%@ typing...", usersTypingString)
                }
            }
        }, error: onError)
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardSize = keyboardFrame.cgRectValue.size
        UIView.animate(withDuration: 0.3, animations: {
            var f = self.view.frame
            f.origin.y = -keyboardSize.height
            self.view.frame = f
        })
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification) {
        UIView.animate(withDuration: 0.3, animations: {
            var f = self.view.frame
            f.origin.y = 0
            self.view.frame = f
        })
    }
    
    @objc func putFormattedMessageIntoChatViewFromUser(userIdentity: String, messageText: String) {
        let user = NSMutableAttributedString.init(string: userIdentity)
        user.addAttribute(NSAttributedStringKey.font, value: UIFont.boldSystemFont(ofSize: 15), range: NSRange(location: 0, length: user.length))
        
        let message = NSMutableAttributedString.init(string: String(format:"\n%@\n\n", messageText))
        message.addAttribute(NSAttributedStringKey.font, value: UIFont.systemFont(ofSize: 12), range: NSRange(location: 0, length: message.length))
        user.append(message)
        
        let textViewString = NSMutableAttributedString.init(string: chatField.attributedText.string)
        textViewString.append(user)
        
        chatField.attributedText = textViewString
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(getHintsFromTextViewWhenStartTyping(textView:)), object: textView)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(getHintsFromTextViewWhenStopTyping(textView:)), object: textView)
        perform(#selector(getHintsFromTextViewWhenStartTyping(textView:)), with: textView, afterDelay: 0)
        perform(#selector(getHintsFromTextViewWhenStopTyping(textView:)), with: textView, afterDelay: 1)
        return true
    }
    
    @objc private func getHintsFromTextViewWhenStartTyping(textView: UITextView) {
        if (textView.text.count > 0) {
            if (textView.text.count > 0) {
                backendless.messaging.sendCommand("USER_TYPING",
                                                  channelName: channel?.channelName,
                                                  data: nil,
                                                  onSuccess: { result in },
                                                  onError: onError)
            }
        }
    }
    
    @objc private func getHintsFromTextViewWhenStopTyping(textView: UITextView) {
        sendUserStopTyping()
    }
    
    private func sendUserStopTyping () {
        backendless.messaging.sendCommand("USER_STOP_TYPING",
                                          channelName: channel?.channelName,
                                          data: nil,
                                          onSuccess: { result in },
                                          onError: onError)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if (textView.text.count == 0) {
            sendButton.isEnabled = false
            sendUserStopTyping()
        }
        else {
            sendButton.isEnabled = true
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        inputField?.resignFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowChatDetails") {
            let chatDetailsVC = segue.destination as! ChatDetailsViewController
            chatDetailsVC.chat = chat
            chatDetailsVC.channel = channel
            view.endEditing(true)
        }
    }
    
    @IBAction func prepareForUnwindToChatVCAfterDelete(segue:UIStoryboardSegue) {
        chat = nil
        navigationItem.title = nil
        chatField.text = ""
        userTypingLabel.isHidden = true
        leaveChatButton.isEnabled = false
        detailsButton.isEnabled = false
        textButton.isEnabled = false
        if (splitViewController!.isCollapsed) {
            self.performSegue(withIdentifier: "UnwindToChats", sender: nil)
        }
    }
    
    @IBAction func prepareForUnwindToChatVCAfterSave(segue:UIStoryboardSegue) {
        let chatDetailsVC = segue.source as! ChatDetailsViewController
        chat = chatDetailsVC.chat
        navigationItem.title = chat?.name
        userTypingLabel.isHidden = true
        leaveChatButton.isEnabled = true
        detailsButton.isEnabled = true
        textButton.isEnabled = true
    }
    
    @IBAction func pressedSend(_ sender: Any) {
        let message = ["text" : inputField?.text ?? "", "userEmail" : backendless.userService.currentUser.email] as [String : Any]
        backendless.messaging.publish(channel?.channelName,
                                      message: message,
                                      response: { status in
                                        self.inputField?.text = ""
                                        self.sendButton.isEnabled = false
                                        self.view.endEditing(true)
                                        self.sendUserStopTyping()
                                        
        }, error: onError)
    }
    
    @IBAction func pressedDetails(_ sender: Any) {
        performSegue(withIdentifier: "ShowChatDetails", sender: sender)
    }
}
