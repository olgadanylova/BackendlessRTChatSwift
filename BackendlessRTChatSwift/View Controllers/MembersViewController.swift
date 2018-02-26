
import UIKit

class MembersViewController: UITableViewController {
    
    var channel: Channel!
    
    private let backendless = Backendless.sharedInstance()!
    
    private let CONNECTED_STATUS = "CONNECTED"
    private let DISCONNECTED_STATUS = "DISCONNECTED"
    private let ONLINE_STATUS = "online"
    private let OFFLINE_STATUS = "offline"
    
    private var members: Set<ChatMember>?
    private var onError: ((Fault?) -> Void)!
    private var onUserStatus: ((UserStatusObject?) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Members"
        members = Set<ChatMember>()
        
        let you = ChatMember()
        you.userId = backendless.userService.currentUser.objectId as String!
        you.identity = backendless.userService.currentUser.email as String!
        you.status = ONLINE_STATUS
        members?.insert(you)
        
        onUserStatus = { userStatus in
            guard let status = userStatus?.status else {
                return
            }
            if (status == self.CONNECTED_STATUS) {
                var connectedMembers = Set<String>()
                for data in (userStatus?.data)! {
                    connectedMembers.insert(data["userId"] as! String)
                }
                for userId in connectedMembers {
                    let member = self.members!.filter { $0.userId == userId }.first
                    if (member == nil) {
                        let user = self.backendless.userService.find(byId: userId)
                        let member = ChatMember()
                        member.userId = user?.objectId as String!
                        member.identity = user?.email as String!
                        member.status = self.ONLINE_STATUS
                        self.members?.insert(member)
                    }
                    else {
                        member?.status = self.ONLINE_STATUS
                    }
                }
            }
            else if (status == self.DISCONNECTED_STATUS) {
                var disconnectedMembers = Set<String>()
                for data in (userStatus?.data)! {
                    disconnectedMembers.insert(data["userId"] as! String)
                }
                for userId in disconnectedMembers {
                    let member = self.members!.filter { $0.userId == userId }.first
                    member?.status = self.OFFLINE_STATUS
                }
            }
            self.tableView.reloadData()
        }
        
        onError = { (fault: Fault?) -> Void in
            AlertController.showErrorAlert(fault: fault!, target: self, handler: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addRTListeners()
    }
    
    private func addRTListeners() {
        channel.addUserStatusListener(onUserStatus, error: onError)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (members?.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath)
        let member = Array(members!)[indexPath.row]
        cell.textLabel?.text = member.identity
        cell.detailTextLabel?.text = member.status
        if (member.status == OFFLINE_STATUS) {
            cell.detailTextLabel?.textColor = UIColor.red
        }
        else if (member.status == ONLINE_STATUS) {
            cell.detailTextLabel?.textColor = UIColor.blue
        }
        return cell
    }
}
