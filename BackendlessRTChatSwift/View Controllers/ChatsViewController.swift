
import UIKit

class ChatsViewController: UITableViewController {
    
    private let backendless = Backendless.sharedInstance()!
    private var chats: [Chat]?

    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveChats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        retrieveChats()
        DispatchQueue.once(token: NSUUID().uuidString) { addRTListeners(); print("CALLED ONCE!!!") }
    }
    
    @objc private func retrieveChats() {
        backendless.data.of(Chat.ofClass()).find({
            retrievedChats in
            self.chats = (retrievedChats as! [Chat]).sorted(by: {(first: Chat, second: Chat) -> Bool in
                first.name < second.name
            })
            self.tableView.reloadData()
        }, error: { fault in AlertController.showErrorAlert(fault: fault!, target: self) }
        )
    }
    
    @objc private func addRTListeners() {
        let chatStore = backendless.rt.data.of(Chat.ofClass())
        chatStore?.addErrorListener({ fault in AlertController.showErrorAlert(fault: fault!, target: self) })
        chatStore?.addCreateListener({ createdChat in self.retrieveChats() })
        chatStore?.addUpdateListener({ updatedChat in self.retrieveChats() })
        chatStore?.addDeleteListener({ deletedChat in self.retrieveChats()})
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        //chatVC.chatField.text = "";
        //chatVC.inputField.text = "";
        //chatVC.userTypingLabel.hidden = YES;
        //[chatVC.leaveChatButton setEnabled:NO];
        //[chatVC.detailsButton setEnabled:NO];
        //[chatVC.textButton setEnabled:NO];
        //[chatVC.sendButton setEnabled:NO];
        //Channel *channelToLeave = chatVC.channel;
        //[channelToLeave disconnect];
    }
    
    @IBAction func addNewChat(_ sender: Any) {
        let alertController = UIAlertController.init(title: "New chat", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {textField in textField.placeholder = "Enter chat name here"})
        let okAction = UIAlertAction.init(title: "OK", style: .default, handler: { action in
            let newChat = Chat()
            newChat.name = alertController.textFields?.first?.text
            self.backendless.data.of(Chat.ofClass()).save(newChat, response: { savedChat in
            }, error: { fault in AlertController.showErrorAlert(fault: fault!, target: self)
            })
        })
        alertController.addAction(okAction)
        let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
