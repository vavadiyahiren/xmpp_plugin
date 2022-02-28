//
//  XMPPController+Room.swift
//  xmpp_plugin
//
//  Created by xRStudio on 20/01/22.
//

import Foundation
import XMPPFramework

//MARK: - XMPPRoom
extension XMPPController : XMPPRoomDelegate {
    func createRoom(withRooms arrRooms: [groupInfo], withStrem : XMPPStream) {
        for objRoom in arrRooms {
            let roomName = objRoom.name.trim()
            if roomName.isEmpty {
                print("\(#function) | roomName nil/empty")
                
                sendMUCCreateStatus(false)
                return
            }
            guard let roomJID = XMPPJID(string: getXMPPRoomJidName(withRoomName: roomName, withStrem: withStrem)) else {
                print("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
                
                sendMUCCreateStatus(false)
                return
            }
            
            let vUserId : String = self.getUserId(usingXMPPStream: withStrem)
            if vUserId.isEmpty {
                print("\(#function) | XMPP UserId is nil/empty")
                
                sendMUCCreateStatus(false)
                return
            }
            
            print("\(#function) | XMPPRoom Jid: \(roomName)")
            self.addUpdateGroupInfo(objGroupInfo: objRoom)
            
            let roomMS : XMPPRoomMemoryStorage = XMPPRoomMemoryStorage.init()
            let xmppRoom = XMPPRoom.init(roomStorage: roomMS, jid: roomJID)
            xmppRoom.activate(withStrem)
            xmppRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
            
            let history = getXMPPRoomHistiry(withTime: 0)
            xmppRoom.join(usingNickname: vUserId, history: history)
            
            xmppRoom.fetchConfigurationForm()
            printLog("\(#function) | perform activity of create XMPPRoom | \(roomName)")
        }
    }
    
    func joinRoom(roomName: String, time : Int64, withStrem : XMPPStream){
        if roomName.trim().isEmpty {
            print("\(#function) | roomName nil/empty")
            sendMUCJoinStatus(false,roomName, "Roomname can't be empty")
            return
        }
        
        let vUserId : String = self.getUserId(usingXMPPStream: withStrem)
        if vUserId.isEmpty {
            print("\(#function) | XMPP UserId is nil/empty")
            
            sendMUCJoinStatus(false,roomName,"User Id Can't be empty")
            return
        }
        guard let xmppJID = XMPPJID(string: getXMPPRoomJidName(withRoomName: roomName, withStrem: withStrem)) else {
            print("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
            
            sendMUCJoinStatus(false,roomName, "Invalid Room Name")
            return
        }
        guard let roomMemory = XMPPRoomMemoryStorage.init() else {
            print("\(#function) | XMPPRoomMemoryStorage is nil/empty")
            
            sendMUCJoinStatus(false,roomName, "XMPPRoomMemoryStorage is nil/empty")
            return
        }
        let objGroupInfo : groupInfo = groupInfo.init()
        objGroupInfo.name = roomName
        self.addUpdateGroupInfo(objGroupInfo: objGroupInfo)
        
        let xmppRoom : XMPPRoom = XMPPRoom.init(roomStorage: roomMemory, jid: xmppJID)
        xmppRoom.activate(withStrem)
        xmppRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        /// Get Message History. set value to return message.
        let history = getXMPPRoomHistiry(withTime: time)
        xmppRoom.join(usingNickname: vUserId, history: history)
        
       // xmppRoom.fetchConfigurationForm()
        printLog("\(#function) | perform activity of Join XMPPRoom | \(roomName) | userId: \(vUserId) | history: \(history)")
    }
    
    func getXMPPRoomJidName(withRoomName roomName : String, withStrem : XMPPStream) -> String {
        var vHost : String = ""
        if let value = withStrem.hostName { vHost = value.trim() }
        
        let valueConference : String = xmppConstants.Conference.trim()
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
    
    //MARK: -
    func xmppRoomDidCreate(_ sender: XMPPRoom) {
        var vRoom : String = ""
        guard let value = sender.myRoomJID?.bareJID.user else {
            print("\(#function) | XMPPRoom Creating Error | XMPPRoom-Name: \(vRoom)")
            
            sendMUCCreateStatus(false)
            return
        }
        sendMUCCreateStatus(true)
        
        vRoom = "\(value)"
        printLog("\(#function) | XMPPRoom Created | XMPPRoom-Name: \(vRoom)")
        
        self.updateGroupInfoIntoXMPPRoomCreatedAndJoined(withXMPPRoomObj: sender, roomName: vRoom)
    }
    
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        var vRoom : String = ""
        guard let value = sender.myRoomJID?.bareJID.user else {
            print("\(#function) | XMPPRoom Joining Error | XMPPRoom-Name: \(vRoom)")
            sendMUCJoinStatus(false,vRoom,"Join Error ")
            return
        }
        vRoom = "\(value)"
        printLog("\(#function) | XMPPRoom Joined | XMPPRoom-Name: \(vRoom)")
        
        sendMUCJoinStatus(true,vRoom,"")
     
        /// No needs for update  alredy join room setting updates
        // Why Uncomment line : Not getting xmppRoom object for getting memeber list.
        self.updateGroupInfoIntoXMPPRoomCreatedAndJoined(withXMPPRoomObj: sender, roomName: vRoom)
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
    
    // MARK: - Room - IQ
    func xmppRoom(_ sender: XMPPRoom, didConfigure iqResult: XMPPIQ) {
        printLog("\(#function) | XMPPRoom: \(sender) | iqResult: \(iqResult)")
    }
    
    func xmppRoom(_ sender: XMPPRoom, didNotConfigure iqResult: XMPPIQ) {
        printLog("\(#function) | XMPPRoom: \(sender) | iqResult: \(iqResult)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        printLog("\(#function) | XMPPRoom: \(sender) | iq: \(iq)")
        
        if let eleError = iq.childErrorElement {
            var vCode : String = ""
            var vErrorMess : String = ""
            
            if let valueCode = eleError.attributeStringValue(forName: "code") { vCode = valueCode.trim() }
            if let valueErrorMess = eleError.getElements(withKey: "text").first?.stringValue { vErrorMess = valueErrorMess.trim() }
            let isErrorIQ = (vCode == "403") && (vErrorMess.lowercased() == xmppConstants.errorMessOfMUC.lowercased())
            printLog("\(#function) | isErrorIQ: \(isErrorIQ) | vCode: \(vCode) | vErrorMess: \(vErrorMess)")
            
            ///Getting MUC Room Id
            var vMUCRoomName : String = ""
            if let valueFrom = iq.fromStr, valueFrom.lowercased().contains(xmppConstants.Conference) {
                vMUCRoomName = valueFrom.components(separatedBy: "@").first ?? ""
            }
            printLog("\(#function) | vMUCRoomName: \(vMUCRoomName)")
            
            if vMUCRoomName.isEmpty { return true }
            if let _ = APP_DELEGATE.objXMPP.arrGroups.firstIndex(where: { (objGroup) -> Bool in
                return objGroup.name == vMUCRoomName
            }) {
                sendMUCJoinStatus(false,vMUCRoomName, "Error Joining Group")
                return true
            }
            printLog("\(#function) | Not getting MUCRoom")
        }
        return true
    }
}

//MARK: - XMPPRoom Members
extension XMPPController {
    
    /// Get All Members in XMPPRoom based on Memeber-role
    func getRoomMember(withUserType vType : xmppMUCUserType,
                       forRoomName roomName: String,
                       withStrem : XMPPStream,
                       objXMPP : XMPPController) {
        var vOnlyRoomName : String = roomName
        if roomName.contains(xmppConstants.Conference) {
            vOnlyRoomName = roomName.components(separatedBy: "@").first ?? roomName
        }
        if vOnlyRoomName.trim().isEmpty {
            print("\(#function) | roomName nil/empty")
            
            self.sendMemberList(withUsers: [])
            return
        }
        
        guard let index = self.arrGroups.firstIndex(where: { (objGroup) -> Bool in
            return objGroup.name == vOnlyRoomName
        }) else {
            print("\(#function) | Not found XMPPRoom object in user created/joined GroupList")
            
            self.sendMemberList(withUsers: [])
            return
        }
        
        let objRoom = self.arrGroups[index]
        guard let objXMPPRoom = objRoom.objRoomXMPP else {
            print("\(#function) | Not found XMPPRoom object in user created/joined GroupList")
            
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
    func xmppRoom(_ sender: XMPPRoom, didFetchMembersList items: [Any]) {
        printLog("\(#function) | Get XMPPRoom Members | sender: \(sender) | items-count: \(items.count)")
        self.getAllMemeberInfo(withItems: items, withUserRole: .Member)
    }
    func xmppRoom(_ sender: XMPPRoom, didNotFetchMembersList iqError: XMPPIQ) {
        printLog("\(#function) | Get XMPPRoom Members error | sender: \(sender) | iqError: \(iqError)")
    }
    
    //MARK: Admins
    func xmppRoom(_ sender: XMPPRoom, didFetchAdminsList items: [Any]) {
        printLog("\(#function) | Get XMPPRoom Admins | sender: \(sender) | items-count: \(items.count)")
        self.getAllMemeberInfo(withItems: items, withUserRole: .Admin)
    }
    func xmppRoom(_ sender: XMPPRoom, didNotFetchAdminsList iqError: XMPPIQ) {
        printLog("\(#function) | Get XMPPRoom Admins error | \(iqError)")
    }
    
    //MARK: Owners
    func xmppRoom(_ sender: XMPPRoom, didFetchOwnersList items: [Any]) {
        printLog("\(#function) | Get XMPPRoom Owners | sender: \(sender) | items-count: \(items.count)")
        self.getAllMemeberInfo(withItems: items, withUserRole: .Owner)
    }
    func xmppRoom(_ sender: XMPPRoom, didNotFetchOwnersList iqError: XMPPIQ) {
        printLog("\(#function) | Get XMPPRoom Owners error | sender: \(sender) | iqError: \(iqError)")
    }
}
