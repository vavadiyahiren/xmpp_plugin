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
            throw XMPPControllerError.wrongUserJID
        }
        
        self.hostName = hostName
        self.hostPort = hostPort
        self.userId = userId
        self.password = password
        self.userJID = userJID
        
        // Stream Configuration
        self.xmppStream = XMPPStream.init()
        self.xmppStream.hostName = hostName
        self.xmppStream.hostPort = UInt16(hostPort)
        self.xmppStream.myJID = userJID
        self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.required
        self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        xmppReconnect = XMPPReconnect()
        self.xmppReconnect.manualStart()
        self.xmppReconnect.activate(self.xmppStream)
        self.xmppReconnect.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        /// XMPP Room
        
    }
    
    
    func connect() {
        if self.xmppStream.isDisconnected {
            do {
                var vTimeout : TimeInterval = XMPPStreamTimeoutNone
                vTimeout = 60.00
                try self.xmppStream.connect(withTimeout: vTimeout)
                APP_DELEGATE.objXMPPConnStatus = .Processing
            } catch let error{
                print("\(#function) | Error: connect() | error: \(error.localizedDescription)")
                APP_DELEGATE.objXMPPConnStatus = .Failed
            }
        } else {
            printLog("\(#function) | XMPPConnected - Yes")
        }
    }
    
    func disconnect() {
        APP_DELEGATE.objXMPPConnStatus = .Disconnect
        self.xmppStream.disconnectAfterSending()
    }
    
    func restart() {
        self.xmppStream.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.connect()
        }
    }
    
    func isConnected() ->Bool {
        let status = self.xmppStream.isConnected
        return status
    }
    
    func isAuthenticated() ->Bool {
        let status = self.xmppStream.isAuthenticated
        return status
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
    
    //MARK:- User status
    func changeStatus(_ UserStatus: Status) {
        switch UserStatus {
        case .Online:
            let presence = XMPPPresence(type: "available")
            self.xmppStream.send(presence)
            
        case .Offline:
            let presence = XMPPPresence(type: "unavailable")
            self.xmppStream.send(presence)
        }
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
            APP_DELEGATE.performXMPPConnectionActivity()
        }
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        if let err = error {
            self.changeStatus(.Offline)
            APP_DELEGATE.objXMPPConnStatus = .Disconnect
            APP_DELEGATE.performXMPPConnectionActivity()
            return
        }
    }
    
    //MARK:- Authenticate
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        self.configureStreamManagement()
        self.changeStatus(.Online)
        
        APP_DELEGATE.objXMPPConnStatus = .Sucess
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        APP_DELEGATE.objXMPPConnStatus = .Failed
        //self.xmppStreamDidConnect(sender)
    }
}

//MARK: - XMPPRoom
extension XMPPController : XMPPRoomDelegate {
    //TODO: Delegate methods
    
    func xmppRoomDidCreate(_ sender: XMPPRoom) {
        var vRoom : String = ""
        if let value = sender.myRoomJID?.bareJID.user {
            vRoom = "\(value)"
            printLog("\(#function) | XMPPRoom Created | XMPPRoom-Name: \(vRoom)")
        } else {
            print("\(#function) | XMPPRoom Creating Error | XMPPRoom-Name: \(vRoom)")
        }
    }
    
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        var vRoom : String = ""
        if let value = sender.myRoomJID?.bareJID.user {
            vRoom = "\(value)"
            printLog("\(#function) | XMPPRoom Joined | XMPPRoom-Name: \(vRoom)")
        } else {
            print("\(#function) | XMPPRoom Joining Error | XMPPRoom-Name: \(vRoom)")
        }
    }
    func xmppRoom(_ sender: XMPPRoom, didFetchConfigurationForm configForm: DDXMLElement) {
        printLog("\(#function) | arrGroups: \(arrGroups.count) | \(arrGroups)")
        
        var vRoomName : String = ""
        if let value = sender.myRoomJID?.bareJID.user { vRoomName = value.trim() }
        
        var newConfiguration = configForm.copy() as? DDXMLElement
        
        let vKey : String = "field"
        //guard let arrRoomConfig = configForm.elements(forName: vKey) as? [DDXMLElement] else {
        guard let arrRoomConfig = newConfiguration?.elements(forName: vKey) as? [DDXMLElement] else {
            print("\(#function) | Not getting XMPPRoom Configuration | XMPPRoom: \(vRoomName)")
            return
        }
        for field in arrRoomConfig {
            guard let roomProparty = field.attribute(forName: "var")?.stringValue else {
                print("\(#function) | Not getting XMPPRoom Configuration-var")
                continue
            }
            //printLog("\(#function) | XMPPRoom Configuration-var | \(roomProparty)")
                        
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
    
    func createRoom(withRooms arrRooms: [groupInfo], withStrem : XMPPStream) {
        for objRoom in arrRooms {
        let roomName = objRoom.name.trim()
        if roomName.isEmpty {
            print("\(#function) | roomName nil/empty")
            return
        }
        guard let roomJID = XMPPJID(string: get_RoomName(roomName: roomName, withStrem: withStrem)) else {
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
        self.arrGroups.append(objRoom)
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
        guard let xmppJID = XMPPJID(string: get_RoomName(roomName: roomName, withStrem: withStrem)) else {
            print("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
            return
        }
        guard let roomMemory = XMPPRoomMemoryStorage.init() else {
            print("\(#function) | XMPPRoomMemoryStorage is nil/empty")
            return
        }
        
        //Reset Old XMPPRoom/Group info
        self.arrGroups = []

        let xmppRoom : XMPPRoom = XMPPRoom.init(roomStorage: roomMemory, jid: xmppJID)
        xmppRoom.activate(withStrem)
        xmppRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //Get Message History. set value to return message.
        let history = getXMPPRoomHistiry(withTime: time)
        xmppRoom.join(usingNickname: vUserId, history: history)
        
        xmppRoom.fetchConfigurationForm()
        printLog("\(#function) | perform activity of Join XMPPRoom | \(roomName) | userId: \(vUserId) | history: \(history)")
    }

    func get_RoomName(roomName : String, withStrem : XMPPStream) -> String {
        var vHost : String = ""
        if let value = withStrem.hostName { vHost = value.trim() }
        
        let valueConference : String = "conference"
        if roomName.contains(valueConference) {
            return roomName
        }
        return [roomName, "@", valueConference, ".", vHost].joined(separator: "")
    }

    
    func getXMPPRoomHistiry(withTime time : Int64) -> XMLElement {
        //Get Message History. set value to return message.
        let history = XMLElement.init(name: "history")
        //history.addAttribute(withName: "maxstanzas", stringValue: "1000") //Set Value to return number of message
        
        //Time send in Second | Source:
        let currentTime : Int64 = Int64(NSDate().timeIntervalSince1970 * 1000)
        let vTimeSecond : Int64 = (currentTime - time) / 1000
        
        //------------------------->
        //Send timestamp value to get message after send timestamp
        history.addAttribute(withName: "seconds", stringValue: vTimeSecond.description)
        
        return history
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
