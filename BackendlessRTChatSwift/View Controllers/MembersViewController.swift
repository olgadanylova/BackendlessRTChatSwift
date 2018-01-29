
import UIKit

class MembersViewController: UITableViewController {
    
    var channel: Channel!
    
    private var members: NSMutableSet?
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
        members = NSMutableSet()
        channel.addErrorListener({ fault in AlertController.showErrorAlert(fault: fault!, target: self) })
        channel.addUserStatusListener({ userStatus in
            let status = userStatus?.status
            if (status == self.LISTING_STATUS) {
                let listingMembers = NSMutableSet()
                for data in (userStatus?.data)! {
                    listingMembers.add(data.value(forKey: "userId") as Any)
                }
                for userId in listingMembers {
                    let user = self.backendless.userService.find(byId: userId as! String)
                    let member = ChatMember()
                    member.userId = user?.objectId as String?
                    member.identity = user?.email as String?
                    member.status = self.ONLINE_STATUS
                    self.members?.add(member)
                }
            }
            else if (status == self.CONNECTED_STATUS) {
                let connectedMembers = NSMutableSet()
                for data in (userStatus?.data)! {
                    connectedMembers.add(data.value(forKey: "userId") as Any)
                }
                for userId in connectedMembers {
                    let predicate = NSPredicate(format: "userId = %@", userId as! CVarArg)
                    let member = self.members?.filter { predicate.evaluate(with: $0) }.first as? ChatMember
                    if (member != nil) {
                        member?.status = self.ONLINE_STATUS
                    }
                    else {
                        let user = self.backendless.userService.find(byId: userId as! String)
                        let member = ChatMember()
                        member.userId = user?.objectId as String?
                        member.identity = user?.email as String?
                        member.status = self.ONLINE_STATUS
                        self.members?.add(member)
                    }
                }
            }
            else if (status == self.DISCONNECTED_STATUS) {
                let disconnectedMembers = NSMutableSet()
                for data in (userStatus?.data)! {
                    disconnectedMembers.add(data.value(forKey: "userId") as Any)
                }
                for userId in disconnectedMembers {
                    let predicate = NSPredicate(format: "userId = %@", userId as! CVarArg)
                    let member = self.members?.filter { predicate.evaluate(with: $0) }.first as? ChatMember
                    if (member != nil) {
                        member?.status = self.OFFLINE_STATUS
                    }
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
        let member = members?.allObjects[indexPath.row] as! ChatMember
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
