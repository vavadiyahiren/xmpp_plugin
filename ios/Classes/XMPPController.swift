//
//  XMPPController.swift
//
//

import UIKit
import XMPPFramework

class XMPPController : NSObject {
    //MARK:- Variable
    static let sharedInstance = XMPPController()
    
    //TODO:
    var xmppStream = XMPPStream()
    var xmppReconnect = XMPPReconnect()
    var xmppRoom : XMPPRoom?
    var xmppStreamManagement : XMPPStreamManagement = XMPPStreamManagement(storage: XMPPStreamManagementMemoryStorage.init(), dispatchQueue: DispatchQueue.main)
    var xmppRoster : XMPPRoster?
    var xmppRosterStorage: XMPPRosterCoreDataStorage?
    var xmppLastActivity = XMPPLastActivity()
    
    internal var hostName: String = ""
    internal var hostPort: Int16 = 0
    internal var userId: String = ""
    internal var userJID = XMPPJID()
    private var password: String = ""
    private var arrGroups : [groupInfo] = []
    
    //MARK:-
    override init() {
        super.init()
    }
    
    init(hostName: String, hostPort : Int16, userId: String, password: String) throws {
        super.init()
        
        let stUserJid = "\(userId)@\(hostName)"
        guard let userJID = XMPPJID.init(string: stUserJid, resource: xmppConstants.Resource) else {
            APP_DELEGATE.objXMPPConnStatus = .Failed
            throw XMPPControllerError.wrongUserJID
        }
        
        self.hostName = hostName
        self.hostPort = hostPort
        self.userId = userId
        self.password = password
        self.userJID = userJID
        
        /// Stream Configuration
        self.xmppStream = XMPPStream.init()
        self.xmppStream.hostName = hostName
        self.xmppStream.hostPort = UInt16(hostPort)
        self.xmppStream.myJID = userJID
        self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.required
        self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        /// xmppReconnect Configuration
        xmppReconnect = XMPPReconnect()
        self.xmppReconnect.manualStart()
        self.xmppReconnect.activate(self.xmppStream)
        self.xmppReconnect.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        /// xmppRoster Configuration
        self.xmppRosterStorage = XMPPRosterCoreDataStorage.init()
        if let objRosSto = self.xmppRosterStorage {
            self.xmppRoster = XMPPRoster.init(rosterStorage: objRosSto)
            self.xmppRoster?.autoFetchRoster = true
            self.xmppRoster?.autoAcceptKnownPresenceSubscriptionRequests = true
            self.xmppRoster?.activate(self.xmppStream)
            self.xmppRoster?.addDelegate(self, delegateQueue: DispatchQueue.main)
        }
        
        /// xmppLastActivity Configuration
        self.xmppLastActivity = XMPPLastActivity.init()
        self.xmppLastActivity.activate(self.xmppStream)
        self.xmppLastActivity.addDelegate(self, delegateQueue: DispatchQueue.main)
    }
        
    func connect() {
        if !self.xmppStream.isDisconnected {
            printLog("\(#function) | XMPPConnected - Yes")
            return
        }
        do {
            var vTimeout : TimeInterval = XMPPStreamTimeoutNone
            vTimeout = 60.00
            try self.xmppStream.connect(withTimeout: vTimeout)
            APP_DELEGATE.objXMPPConnStatus = .Processing
        } catch let error{
            print("\(#function) | Error: connect() | error: \(error.localizedDescription)")
            APP_DELEGATE.objXMPPConnStatus = .Failed
        }
    }
    
    func disconnect() {
        APP_DELEGATE.objXMPPConnStatus = .Disconnect
        self.xmppStream.disconnectAfterSending()
    }
    
    func restart() {
        self.xmppStream.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.connect() }
    }
    
    func isConnected() ->Bool {
        return self.xmppStream.isConnected
    }
    
    func isAuthenticated() ->Bool {
        return self.xmppStream.isAuthenticated
    }
    
    func isSendMessage() ->Bool {
        return (self.isConnected() && self.isAuthenticated())
    }
    
    func getUserId(usingXMPPStream objXMPPStream : XMPPStream) -> String {
        var vUserId : String = ""
        if let value = objXMPPStream.myJID?.description {
            vUserId = (value.components(separatedBy: "@").first ?? "").trim()
        }
        return vUserId
    }

    func getJIDNameForUser(_ jid : String, withStrem: XMPPStream) -> String {
        var vHost : String = ""
        if let value = withStrem.hostName { vHost = value.trim() }
        if jid.contains(vHost) { return jid }
        return [jid, "@", vHost].joined(separator: "")
    }
    
    //MARK:- User status
    func changeStatus(_ userStatus: Status, withXMPPStrem xmppStream : XMPPStream) {
        let vStatus : String = (userStatus == .Online) ? "available" : "unavailable"
        let presence = XMPPPresence(type: vStatus.trim())
        xmppStream.send(presence)
    }
}

extension XMPPController: XMPPStreamDelegate, XMPPMUCLightDelegate  {
    //MARK:- stream Connect
    func xmppStreamDidConnect(_ stream: XMPPStream) {
        if self.password.isEmpty {
            print("\(#function) | XMPP User password is empty/nil.")
            return
        }
        do {
            try stream.authenticate(withPassword: self.password)
        } catch {
            APP_DELEGATE.objXMPPConnStatus = .Disconnect
        }
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        guard let err = error else {
            printLog("\(#function) | Not getting any error.")
            return
        }
        print("\(#function) | XMPP Server connection error | error: \(err.localizedDescription)")
        
        self.changeStatus(.Offline, withXMPPStrem: sender)
        APP_DELEGATE.objXMPPConnStatus = .Disconnect
    }
    
    //MARK:- Authenticate
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        self.configureStreamManagement()
        self.changeStatus(.Online, withXMPPStrem: sender)
        
        APP_DELEGATE.objXMPPConnStatus = .Sucess
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        APP_DELEGATE.objXMPPConnStatus = .Failed
        //self.xmppStreamDidConnect(sender)
    }
}

//MARK: - XMPPRoom
extension XMPPController : XMPPRoomDelegate {
    func xmppRoomDidCreate(_ sender: XMPPRoom) {
        var vRoom : String = ""
        guard let value = sender.myRoomJID?.bareJID.user else {
            print("\(#function) | XMPPRoom Creating Error | XMPPRoom-Name: \(vRoom)")
            return
        }
        vRoom = "\(value)"
        printLog("\(#function) | XMPPRoom Created | XMPPRoom-Name: \(vRoom)")
        
        self.updateGroupInfoIntoXMPPRoomCreatedAndJoined(withXMPPRoomObj: sender, roomName: vRoom)
    }
    
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        var vRoom : String = ""
        guard let value = sender.myRoomJID?.bareJID.user else {
            print("\(#function) | XMPPRoom Joining Error | XMPPRoom-Name: \(vRoom)")
            return
        }
        vRoom = "\(value)"
        printLog("\(#function) | XMPPRoom Joined | XMPPRoom-Name: \(vRoom)")
        
        /// No needs for update  alredy join room setting updates
        //self.updateGroupInfoIntoXMPPRoomCreatedAndJoined(withXMPPRoomObj: sender, roomName: vRoom)
    }
    
    func xmppRoom(_ sender: XMPPRoom, didFetchConfigurationForm configForm: DDXMLElement) {
        printLog("\(#function) | arrGroups: \(arrGroups.count) | \(arrGroups)")
        
        var vRoomName : String = ""
        if let value = sender.myRoomJID?.bareJID.user { vRoomName = value.trim() }
        
        let newConfiguration = configForm.copy() as? DDXMLElement
        
        let vKey : String = "field"
        guard let arrRoomConfig = newConfiguration?.elements(forName: vKey) as? [DDXMLElement] else {
            print("\(#function) | Not getting XMPPRoom Configuration | XMPPRoom: \(vRoomName)")
            return
        }
        for field in arrRoomConfig {
            guard let roomProparty = field.attribute(forName: "var")?.stringValue else {
                print("\(#function) | Not getting XMPPRoom Configuration-var")
                continue
            }
            switch roomProparty {
            case "muc#roomconfig_persistentroom":
                var defaultConfig : String = ""
                if let ele = field.getElements(withKey: "value").first,
                   let value = ele.getValue(withKey: "value") {
                    defaultConfig = value
                }
                printLog("\(#function) | XMPPRoom Configuration | \(roomProparty) | defaultConfig: \(defaultConfig)")
                
                var isPersistentroom : Bool = default_isPersistent
                if let objRoomInfo = self.arrGroups.first(where: { (obj) -> Bool in
                    return obj.name == vRoomName
                }) {
                    isPersistentroom = objRoomInfo.isPersistent
                    
                    field.removeChild(at: 0)
                    field.addChild(DDXMLElement(name: "value", stringValue: isPersistentroom ? "1" : "0"))
                    printLog("\(#function) | XMPPRoom Configuration | \(roomProparty) | update-Config: \(field)")
                }
                
            case "muc#roomconfig_membersonly":
                if let _ = self.arrGroups.first(where: { (obj) -> Bool in
                    return obj.name == vRoomName
                }) {
                    field.removeChild(at: 0)
                    field.addChild(DDXMLElement(name: "value", stringValue: "1"))
                    printLog("\(#function) | XMPPRoom Configuration | \(roomProparty) | update-Config: \(field)")
                }
            
            default:
                printLog("\(#function) | XMPPRoom Configuration-var | \(roomProparty)")
                break
            }
        }
        sender.configureRoom(usingOptions: newConfiguration)
    }
    
    func xmppRoom(_ sender: XMPPRoom, didConfigure iqResult: XMPPIQ) {
        printLog("\(#function) | XMPPRoom: \(sender) | iqResult: \(iqResult)")
    }
    
    func xmppRoom(_ sender: XMPPRoom, didNotConfigure iqResult: XMPPIQ) {
        printLog("\(#function) | XMPPRoom: \(sender) | iqResult: \(iqResult)")
    }
    
    //MARK: -
    func createRoom(withRooms arrRooms: [groupInfo], withStrem : XMPPStream) {
        for objRoom in arrRooms {
            let roomName = objRoom.name.trim()
            if roomName.isEmpty {
                print("\(#function) | roomName nil/empty")
                return
            }
            guard let roomJID = XMPPJID(string: getXMPPRoomJidName(withRoomName: roomName, withStrem: withStrem)) else {
                print("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
                return
            }
            let vUserId : String = self.getUserId(usingXMPPStream: withStrem)
            if vUserId.isEmpty {
                print("\(#function) | XMPP UserId is nil/empty")
                return
            }
            let roomMS : XMPPRoomMemoryStorage = XMPPRoomMemoryStorage.init()
            let xmppRoom = XMPPRoom.init(roomStorage: roomMS, jid: roomJID)
            xmppRoom.activate(withStrem)
            xmppRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
            
            let history = getXMPPRoomHistiry(withTime: 0)
            xmppRoom.join(usingNickname: vUserId, history: history)
            
            xmppRoom.fetchConfigurationForm()
            self.addUpdateGroupInfo(objGroupInfo: objRoom)
            
            printLog("\(#function) | perform activity of create XMPPRoom | \(roomName)")
        }
    }
    
    func joinRoom(roomName: String, time : Int64, withStrem : XMPPStream){
        if roomName.trim().isEmpty {
            print("\(#function) | roomName nil/empty")
            return
        }
        
        let vUserId : String = self.getUserId(usingXMPPStream: withStrem)
        if vUserId.isEmpty {
            print("\(#function) | XMPP UserId is nil/empty")
            return
        }
        guard let xmppJID = XMPPJID(string: getXMPPRoomJidName(withRoomName: roomName, withStrem: withStrem)) else {
            print("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
            return
        }
        guard let roomMemory = XMPPRoomMemoryStorage.init() else {
            print("\(#function) | XMPPRoomMemoryStorage is nil/empty")
            return
        }
        let xmppRoom : XMPPRoom = XMPPRoom.init(roomStorage: roomMemory, jid: xmppJID)
        xmppRoom.activate(withStrem)
        xmppRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        /// Get Message History. set value to return message.
        let history = getXMPPRoomHistiry(withTime: time)
        xmppRoom.join(usingNickname: vUserId, history: history)
        
        xmppRoom.fetchConfigurationForm()
        printLog("\(#function) | perform activity of Join XMPPRoom | \(roomName) | userId: \(vUserId) | history: \(history)")
    }

    func getXMPPRoomJidName(withRoomName roomName : String, withStrem : XMPPStream) -> String {
        var vHost : String = ""
        if let value = withStrem.hostName { vHost = value.trim() }
        
        let valueConference : String = "conference"
        if roomName.contains(valueConference) { return roomName }
        return [roomName, "@", valueConference, ".", vHost].joined(separator: "")
    }
    
    /// Get Message History. set value to return message.
    func getXMPPRoomHistiry(withTime time : Int64) -> XMLElement {
        
        let history = XMLElement.init(name: "history")
        //history.addAttribute(withName: "maxstanzas", stringValue: "1000") //Set Value to return number of message
        
        /// Time send in Second | Source:
        let currentTime : Int64 = Int64(NSDate().timeIntervalSince1970 * 1000)
        let vTimeSecond : Int64 = (currentTime - time) / 1000
        
        /// Send timestamp value to get message after send timestamp
        history.addAttribute(withName: "seconds", stringValue: vTimeSecond.description)
        
        return history
    }
    
    func addUpdateGroupInfo( objGroupInfo : groupInfo) {
        let roomName = objGroupInfo.name.trim()
        if roomName.isEmpty {
            print("\(#function) | roomName nil/empty")
            return
        }
        if let index = self.arrGroups.firstIndex(where: { (objRoom) -> Bool in
            return objRoom.name == roomName
        }) {
            self.arrGroups.remove(at: index)
            self.arrGroups.insert(objGroupInfo, at: index)
            
            printLog("\(#function) | Update XMPPRoom | \(roomName)")
            return
        }
        self.arrGroups.append(objGroupInfo)
        printLog("\(#function) | New Added XMPPRoom | \(roomName)")
    }
    
    func updateGroupInfoIntoXMPPRoomCreatedAndJoined(withXMPPRoomObj roomXMPP : XMPPRoom, roomName vRoom: String) {
        if let index = self.arrGroups.firstIndex(where: { (objGroup) -> Bool in
            return objGroup.name == vRoom
        }) {
            let objRoomNew = self.arrGroups[index]
            objRoomNew.objRoomXMPP = roomXMPP
            
            self.arrGroups.remove(at: index)
            self.arrGroups.insert(objRoomNew, at: index)
            
            printLog("\(#function) | Update XMPPRoom | \(vRoom)")
            return
        }
        printLog("\(#function) | Not found XMPPRoom in GroupInfo list | \(vRoom)")
    }
}

extension XMPPController {
    /// Get All Members in XMPPRoom based on Memeber-role
    func getRoomMember(withUserType vType : xmppMUCUserType, forRoomName roomName: String, withStrem : XMPPStream) {
        if roomName.trim().isEmpty {
            print("\(#function) | roomName nil/empty")
            
            self.sendMemberList(withUsers: [])
            return
        }
        guard let index = self.arrGroups.firstIndex(where: { (objGroup) -> Bool in
            return objGroup.name == roomName
        }) else {
            print("\(#function) | Not found XMPPRoom object in user created/join GroupList")
            
            self.sendMemberList(withUsers: [])
            return
        }
        
        let objRoom = self.arrGroups[index]
        guard let objXMPPRoom = objRoom.objRoomXMPP else {
            print("\(#function) | User not succesfully created/join XMPPRoom")
            
            self.sendMemberList(withUsers: [])
            return
        }
        printLog("\(#function) | perform activity of get XMPPRoom Member | room: \(roomName) | role: \(vType)")
        switch vType {
        case .Member:
            objXMPPRoom.fetchMembersList()
            
        case .Admin:
            objXMPPRoom.fetchAdminsList()
            
        case .Owner:
            objXMPPRoom.fetchOwnersList()
        }
    }
    
    /// Add-or-Remove Members in XMPPRoom
    func addRemoveMemberInRoom(withUserRole vRole : xmppMUCUserType,
                               actionType: xmppMUCUserActionType,
                               withRoomName roomName: String,
                               withUsers arrUser : [String],
                               withStrem: XMPPStream) {
        if roomName.trim().isEmpty {
            print("\(#function) | roomName nil/empty")
            return
        }
        if arrUser.isEmpty {
            print("\(#function) | Users nil/empty")
            return
        }
        /// Get RoomInfo
        guard let index = self.arrGroups.firstIndex(where: { (objGroup) -> Bool in
            return objGroup.name == roomName
        }) else {
            print("\(#function) | Not found XMPPRoom object in user created/join GroupList")
            return
        }
        let objRoom = self.arrGroups[index]
        guard let objXMPPRoom = objRoom.objRoomXMPP else {
            print("\(#function) | User not succesfully created/join XMPPRoom.")
            return
        }
        printLog("\(#function) | perform activity of XMPPRoom Member - \(actionType) | room: \(roomName) | role: \(vRole)")
        
        /// Set Users role value
        var vUserRole : String = ""
        switch vRole {
        case .Member:
            vUserRole = (actionType == .Add) ? xmppMUCRole.Member : xmppMUCRole.None
            
        case .Admin:
            vUserRole = (actionType == .Add) ? xmppMUCRole.Admin : xmppMUCRole.Member
            
        case .Owner:
            vUserRole = (actionType == .Add) ? xmppMUCRole.Owner : xmppMUCRole.Member
        }
        if vUserRole.trim().isEmpty {
            print("\(#function) | Member role is empty/nil")
            return
        }
        
        /// Create Users List
        var arrUsers: [DDXMLElement] = []
        for user in arrUser {
            if user.trim().isEmpty {
                print("\(#function) | UserJidString is empty/nil")
                continue
            }
            let userJIDString = getJIDNameForUser(user.trim(), withStrem: withStrem)
            let eleUser : XMLElement = XMLElement.init(name: "item")
            eleUser.addAttribute(withName: "affiliation", stringValue: vUserRole.trim())
            eleUser.addAttribute(withName: "jid", stringValue: userJIDString)
            arrUsers.append(eleUser)
        }
        if arrUsers.isEmpty {
            print("\(#function) | Add users list in Circle are empty/nil")
            return
        }
        objXMPPRoom.editPrivileges(arrUsers)
    }
    
    func getAllMemeberInfo(withItems items: [Any], withUserRole vRole : xmppMUCUserType) {
        var arrUsers : [String] = []
        for objUser in items {
            guard let eleUser = objUser as? DDXMLElement else {
                printLog("\(#function) | Invalid XMPPRoom Users object | objUser: \(objUser)")
                continue
            }
            var vAffiliation : String = ""
            var vJid : String = ""
            if let value = eleUser.attributeStringValue(forName: "affiliation") { vAffiliation = value.trim() }
            if let value = eleUser.attributeStringValue(forName: "jid") { vJid = value.trim() }
            printLog("\(#function) | eleUser: \(eleUser) | eleUser-affiliation: \(vAffiliation) | eleUser-jid: \(vJid) | role: \(vRole)")
            
            arrUsers.append(vJid)
        }
        self.sendMemberList(withUsers: arrUsers)
    }
    
    //MARK: Members
    /**
     <item affiliation="member" jid="test@xrstudio.in"></item>
     */
    func xmppRoom(_ sender: XMPPRoom, didFetchMembersList items: [Any]) {
        printLog("\(#function) | Get XMPPRoom Members | sender: \(sender) | items-count: \(items.count)")
        self.getAllMemeberInfo(withItems: items, withUserRole: .Member)
    }
    func xmppRoom(_ sender: XMPPRoom, didNotFetchMembersList iqError: XMPPIQ) {
        printLog("\(#function) | Get XMPPRoom Members error | sender: \(sender) | iqError: \(iqError)")
    }
    
    //MARK: Admins
    /**
     <item affiliation="admin" jid="test@xrstudio.in"></item>
     */
    func xmppRoom(_ sender: XMPPRoom, didFetchAdminsList items: [Any]) {
        printLog("\(#function) | Get XMPPRoom Admins | sender: \(sender) | items-count: \(items.count)")
        self.getAllMemeberInfo(withItems: items, withUserRole: .Admin)
    }
    func xmppRoom(_ sender: XMPPRoom, didNotFetchAdminsList iqError: XMPPIQ) {
        printLog("\(#function) | Get XMPPRoom Admins error | \(iqError)")
    }
    
    //MARK: Owners
    /**
     <item affiliation="owner" jid="test@xrstudio.in"></item>
     */
    func xmppRoom(_ sender: XMPPRoom, didFetchOwnersList items: [Any]) {
        printLog("\(#function) | Get XMPPRoom Owners | sender: \(sender) | items-count: \(items.count)")
        self.getAllMemeberInfo(withItems: items, withUserRole: .Owner)
    }
    func xmppRoom(_ sender: XMPPRoom, didNotFetchOwnersList iqError: XMPPIQ) {
        printLog("\(#function) | Get XMPPRoom Owners error | sender: \(sender) | iqError: \(iqError)")
    }
}

//MARK: - XMPPMessage
extension XMPPController {
    //MARK: XMPPMessage delegate methods
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        printLog("\(#function) | didSend message: \(message)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        printLog("\(#function) | didReceive message: \(message)")
        
        let vMessType : String = (message.type ?? xmppChatType.NORMAL).trim()
        switch vMessType {
        case xmppChatType.NORMAL:
            self.handelNormalChatMessage(message, withStrem: sender)
            
        default:
            self.handel_ChatMessage(message, withType: vMessType, withStrem: sender)
        }
    }
    
    func xmppStream(_ sender: XMPPStream, didFailToSend message: XMPPMessage, error: Error) {
        printLog("didFailToSend message : \(error.localizedDescription)")
    }
}

extension XMPPController : XMPPStreamManagementDelegate {
    func configureStreamManagement() {
        let xmppSMMS = XMPPStreamManagementMemoryStorage.init()
        xmppStreamManagement = XMPPStreamManagement(storage: xmppSMMS, dispatchQueue: DispatchQueue.main)
        xmppStreamManagement.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppStreamManagement.activate(self.xmppStream)
        
        xmppStreamManagement.autoResume = true
        xmppStreamManagement.ackResponseDelay = 0.01
        xmppStreamManagement.requestAck()
        xmppStreamManagement.automaticallyRequestAcks(afterStanzaCount: 1, orTimeout: 10)
        xmppStreamManagement.automaticallySendAcks(afterStanzaCount: 1, orTimeout: 10)
        xmppStreamManagement.enable(withResumption: true, maxTimeout: 2.0)
        
        xmppStreamManagement.sendAck()
        xmppStream.register(xmppStreamManagement)
    }
    
    func xmppStreamManagement(_ sender: XMPPStreamManagement, didReceiveAckForStanzaIds stanzaIds: [Any]) {
        if APP_DELEGATE.objEventData == nil {
            print("\(#function) | Nil data of APP_DELEGATE.objEventData")
            return
        }
        for value in stanzaIds {
            guard let vMessId = value as? String  else {
                print("\(#function) | getting Invalid Message Id | \(value)")
                continue
            }
            self.sendAck(vMessId)
        }
    }
}

//MARK: - XMPPRoster
extension XMPPController : XMPPRosterDelegate {
    func xmppRoster(_ sender: XMPPRoster, didReceivePresenceSubscriptionRequest presence: XMPPPresence) {
        printLog("\(#function) | presence : \(presence)")
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterPush iq: XMPPIQ) {
        printLog("\(#function) | iq : \(iq)")
    }
    
    func xmppRosterDidBeginPopulating(_ sender: XMPPRoster, withVersion version: String) {
        printLog("\(#function) | version : \(version)")
    }
    
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        printLog("\(#function) | sender: \(sender)")
    }
    
    //MARK: -
    func createRosters(withUserJid jid: String, withStrem: XMPPStream, objXMPP : XMPPController) {
        printLog("\(#function) | withUserJid: \(jid)")
        if jid.trim().isEmpty {
            print("\(#function) | getting userJid is emtpy.")
            return
        }
        let vJid : XMPPJID? = XMPPJID(string: getJIDNameForUser(jid.trim(), withStrem: withStrem))
        if let vJid = vJid {
            objXMPP.xmppRoster?.subscribePresence(toUser: vJid)
            return
        }
        print("\(#function) | Getting Invalid Jid, not created Roster | userJid : \(jid)")
    }
    
    func getMyRosters(withStrem: XMPPStream, objXMPP : XMPPController) {
        var arrJidString : [String] = []
        guard let arrJid = objXMPP.xmppRosterStorage?.jids(for: withStrem) else {
            printLog("\(#function) | Not getting roster.")
            
            self.sendRosters(withUsersJid: arrJidString)
            return
        }
        
        for jid in arrJid {
            let strJid = jid.description.trim()
            if strJid.isEmpty { continue }
            arrJidString.append(strJid)
        }
        self.sendRosters(withUsersJid: arrJidString)
    }
}

//MARK: - XMPPRoster
extension XMPPController : XMPPLastActivityDelegate {
    func numberOfIdleTimeSeconds(for sender: XMPPLastActivity!, queryIQ iq: XMPPIQ!, currentIdleTimeSeconds idleSeconds: UInt) -> UInt {
        printLog("\(#function) | response : \(String(describing: iq)) | idleSeconds : \(idleSeconds)")
        return 0
    }
    
    func xmppLastActivity(_ sender: XMPPLastActivity!, didReceiveResponse response: XMPPIQ!) {
        /**
         ///-------------------------------------------------------------------------------------------------------------------------------------
         /// Error
         <iq
             xmlns="jabber:client" from="test2@xrstudio.in" to="test@xrstudio.in/iOS" id="9826D8E8-5BD0-4B59-AD24-21B5331DAB4F" type="error">
             <query
                 xmlns="jabber:iq:last">
             </query>
             <error code="403" type="auth">
                 <forbidden
                     xmlns="urn:ietf:params:xml:ns:xmpp-stanzas">
                 </forbidden>
             </error>
         </iq>
         
         ///-------------------------------------------------------------------------------------------------------------------------------------
         /// Result
         <iq
             xmlns="jabber:client" from="test@xrstudio.in" to="test@xrstudio.in/iOS" id="D5B3B096-16A5-4E6B-B03F-8216BD81F330" type="result">
             <query
                 xmlns="jabber:iq:last" seconds="0">
             </query>
         </iq>
         */
        printLog("\(#function) | response : \(String(describing: response))")
        var vTimeInSec : String = "-1"
        let isErrorResponse : Bool = response.isErrorIQ
        if isErrorResponse {
            print("\(#function) | Getting error in XMPPLastActivity IQ | response: \(String(describing: response))")
            
            self.sendLastActivity(withTime: vTimeInSec)
            return
        }
        
        guard let eleQuery = response.children?.first else {
            print("\(#function) | Not getting Valid XMPPLastActivity IQ-Query | response-iq: \(String(describing: response))")
            
            self.sendLastActivity(withTime: vTimeInSec)
            return
        }
        guard let ele = eleQuery as? DDXMLElement else {
            print("\(#function) | Not getting Valid IQ-Query | elementQuery: \(eleQuery)")
            
            self.sendLastActivity(withTime: vTimeInSec)
            return
        }
        if let value = ele.attribute(forName: "seconds")?.stringValue {
            vTimeInSec = value.trim()
        }
        self.sendLastActivity(withTime: vTimeInSec)
    }
    
    func xmppLastActivity(_ sender: XMPPLastActivity!, didNotReceiveResponse queryID: String!, dueToTimeout timeout: TimeInterval) {
        printLog("\(#function) | queryID : \(String(describing: queryID)) | timeout : \(timeout)")
        self.sendLastActivity(withTime: "-1")
    }
    
    //MARK: -
    func getLastActivity(withUserJid jid: String, withStrem: XMPPStream, objXMPP : XMPPController) {
        printLog("\(#function) | withUserJid : \(jid)")
        guard let vJid = XMPPJID(string: getJIDNameForUser(jid.trim(), withStrem: withStrem)) else {
            print("\(#function) | Getting invalid UserJid : \(jid)")
            return
        }
        objXMPP.xmppLastActivity.sendQuery(to: vJid)
    }
}

//MARK: - Extension
extension XMPPMessage {
    public func getMessageType() -> String? {
        return self.type
    }
    
    public func getSenderID() -> String? {
        return self.from?.resource
    }
    
    public func getSenderID_inGroupChat() -> String? {
        return self.from?.resource
    }
    public func getSenderID_inSingalChat() -> String? {
        return self.from?.user
    }
    
    public func getElementValue(_ elementKey : String) -> String? {
        return self.elements(forName: elementKey).first?.children?.first?.stringValue
    }
    
    /**
     <CUSTOM
         xmlns="urn:xmpp:custom">
         <custom>test</custom>
     </CUSTOM>
     */
    func getCustomElementInfo(withKey vKey : String) -> String {
        var value : String = ""
        let arrMI = self.elements(forName: eleCustom.Name)
        guard let eleMI = arrMI.first else {
            //printLog("\(#function) | \(eleCustom.Name) element not get")
            return value
        }
        
        let arrMInfo = eleMI.elements(forName: vKey)
        guard let vInfo = arrMInfo.first?.stringValue else {
            //printLog("\(#function) | \(vKey) element not get")
            return value
        }
        value = vInfo.trim()
        return value
    }
}

extension DDXMLElement {
    /**
     <field var="muc#roomconfig_persistentroom" type="boolean" label="Room is Persistent">
         <value>0</value>
     </field>
     */
    func getElements(withKey vKey : String) -> [DDXMLElement] {
        return self.elements(forName: vKey)
    }
    
    func getValue(withKey vKey : String) -> String? {
        var value : String = ""
        guard let vInfo = self.stringValue else {
            //printLog("\(#function) | \(vKey) key element not getting")
            return value
        }
        value = vInfo.trim()
        return value
    }
}
