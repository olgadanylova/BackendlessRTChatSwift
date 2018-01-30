
import UIKit

class MembersViewController: UITableViewController {
    
    var channel: Channel!
    
    private var members: Set<ChatMember>?
    private let LISTING_STATUS = "LISTING"
    private let CONNECTED_STATUS = "CONNECTED"
    private let DISCONNECTED_STATUS = "DISCONNECTED"
    private let ONLINE_STATUS = "online"
    private let OFFLINE_STATUS = "offline"
    
    private let backendless = Backendless.sharedInstance()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addRTListeners()
    }
    
    private func addRTListeners() {
        members = Set<ChatMember>()
        channel.addErrorListener({ fault in AlertController.showErrorAlert(fault: fault!, target: self) })
        
        channel.addUserStatusListener({ userStatus in
            guard let status = userStatus?.status else {
                return
            }
            if (status == self.LISTING_STATUS) {
                var listingMembers = Set<String>()
                for data in (userStatus?.data)! {
                    listingMembers.insert(data["userId"] as! String)
                }
                for userId in listingMembers {
                    let user = self.backendless.userService.find(byId: userId)
                    let member = ChatMember()
                    member.userId = user?.objectId as String?
                    member.identity = user?.email as String?
                    member.status = self.ONLINE_STATUS
                    self.members?.insert(member)
                }
            }
            else if (status == self.CONNECTED_STATUS) {
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
        })
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
