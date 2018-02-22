
import UIKit

class ChatsViewController: UITableViewController {

    private let backendless = Backendless.sharedInstance()!
    private var chats: [Chat]?        
    private var onError: ((Fault?) -> Void)!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = backendless.userService.currentUser.email as String
        backendless.rt.addConnectEventListener({ print("Connected to RT server")})
        backendless.rt.addConnectErrorEventListener({ error in print("Failed to connect to RT server: \(error!)") })
        
        onError = { (fault: Fault?) -> Void in
            AlertController.showErrorAlert(fault: fault!, target: self, handler: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.once(token: NSUUID().uuidString) { addRTListeners() }
    }
    
    @objc private func retrieveChats() {
        backendless.data.of(Chat.ofClass()).find({
            retrievedChats in
            self.chats = (retrievedChats as! [Chat]).sorted(by: {(first: Chat, second: Chat) -> Bool in
                first.name < second.name
            })
            self.tableView.reloadData()
        }, error: onError)
    }
    
    @objc private func addRTListeners() {
        let chatStore = backendless.data.of(Chat.ofClass()).rt
        chatStore?.addCreateListener({ createdChat in self.retrieveChats() }, error: onError)
        chatStore?.addUpdateListener({ updatedChat in self.retrieveChats() }, error: onError)
        chatStore?.addDeleteListener({ deletedChat in self.retrieveChats() }, error: onError)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chats = backendless.data.of(Chat.ofClass()).find() as? [Chat]
        return (chats?.count)!
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        let chat = chats![indexPath.row]
        cell.textLabel?.text = chat.name
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowChat") {
            let navController = segue.destination as! UINavigationController
            let chatVC = navController.topViewController as! ChatViewController
            let indexPath = tableView.indexPath(for: sender as! UITableViewCell)
            chatVC.chat = chats?[(indexPath?.row)!]
        }
    }
    
    @IBAction func prepareForUnwindToChatsVC(segue:UIStoryboardSegue) {
        let chatVC = segue.source as! ChatViewController
        chatVC.navigationItem.title = ""
        chatVC.chatField.text = ""
        chatVC.inputField?.text = ""
        chatVC.userTypingLabel.isHidden = true
        chatVC.leaveChatButton.isEnabled = false
        chatVC.detailsButton.isEnabled = false
        chatVC.textButton.isEnabled = false
        chatVC.sendButton.isEnabled = false
        chatVC.channel?.disconnect()
    }
    
    @IBAction func addNewChat(_ sender: Any) {
        let alertController = UIAlertController.init(title: "New chat", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {textField in textField.placeholder = "Enter chat name here"})
        let okAction = UIAlertAction.init(title: "OK", style: .default, handler: { action in
            let newChat = Chat()
            newChat.name = alertController.textFields?.first?.text
            self.backendless.data.of(Chat.ofClass()).save(newChat, response: { savedChat in
            }, error: self.onError)
        })
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
