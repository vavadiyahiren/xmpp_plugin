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
            print("\(#function) | XMPPConnected - Yes")
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

extension XMPPController: XMPPStreamDelegate, XMPPMUCLightDelegate, XMPPHTPPFileUploadDelegate  {
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
        self.xmppStreamDidConnect(sender)
    }
}

//MARK: - XMPPRoom
extension XMPPController : XMPPRoomDelegate {
    //TODO: Delegate methods
    
    func xmppRoomDidCreate(_ sender: XMPPRoom) {
        var vRoom : String = ""
        if let value = sender.myRoomJID?.bareJID.user {
            vRoom = "\(value)"
            print("\(#function) | XMPPRoom Created | XMPPRoom-Name: \(vRoom)")
            //self.joinRoom(roomName: vRoom, time: 0, withStrem: <#XMPPStream#>)
        } else {
            print("\(#function) | XMPPRoom Creating Error | XMPPRoom-Name: \(vRoom)")
        }
    }
    
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        var vRoom : String = ""
        if let value = sender.myRoomJID?.bareJID.user {
            vRoom = "\(value)"
            print("\(#function) | XMPPRoom Joined | XMPPRoom-Name: \(vRoom)")
        } else {
            print("\(#function) | XMPPRoom Joining Error | XMPPRoom-Name: \(vRoom)")
        }
    }
    
    func createRoom(roomName: String, withXMPP objXMPP : XMPPController, withStrem : XMPPStream) {
        if roomName.trim().isEmpty {
            print("\(#function) | roomName nil/empty")
            return
        }
        guard let roomJID = XMPPJID(string: get_RoomName(roomName: roomName, withStrem: withStrem)) else {
            print("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
            return
        }
        
        var vUserId : String = ""
        if let value = withStrem.myJID?.description { vUserId = (value.components(separatedBy: "@").first ?? "").trim() }
        if vUserId.isEmpty {
            print("\(#function) | XMPP UserId is nil/empty")
            return
        }
        let roomMS : XMPPRoomMemoryStorage = XMPPRoomMemoryStorage.init()
        let xmppRoom = XMPPRoom.init(roomStorage: roomMS, jid: roomJID)
        xmppRoom.activate(withStrem)
        xmppRoom.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        let history = XMLElement.init(name: "history")
        history.addAttribute(withName: "maxstanzas", stringValue: "0") //Set Value to return Value-Of-No-Messsage in Chat room
        xmppRoom.join(usingNickname: vUserId, history: history)
    }
    
    func joinRoom(roomName: String, time : Int64) {
        if roomName.trim().isEmpty {
            print("\(#function) | roomName nil/empty")
            return
        }
        
        var vUserId : String = ""
        if let value = withStrem.myJID?.description { vUserId = (value.components(separatedBy: "@").first ?? "").trim() }
        if vUserId.isEmpty {
            print("\(#function) | XMPP UserId is nil/empty")
            return
        }
        
        //let xmppJID = XMPPJID(string: roomName)
        guard let xmppJID = XMPPJID(string: get_RoomName(roomName: roomName, withStrem: withStrem)) else {
            print("\(#function) | Invalid XMPPRoom Jid: \(roomName)")
            return
        }
        guard let roomMemory = XMPPRoomMemoryStorage.init() else {
            print("\(#function) | XMPPRoomMemoryStorage is nil/empty")
            return
        }

        let room : XMPPRoom = XMPPRoom.init(roomStorage: roomMemory, jid: xmppJID!)
        room.activate(self.xmppStream)

        room.fetchConfigurationForm()
        room.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        //Get Message History. set value to return message.
        let history = XMLElement.init(name: "history")
        history.addAttribute(withName: "maxstanzas", stringValue: "1") //Set Value to return

        let history = getXMPPRoomHistiry(withTime: time)
        room.join(usingNickname: vUserId, history: history)
        
        print("\(#function) | history: \(history) | self.userId: \(vUserId) | jid: \(xmppJID)")

    }

    func get_RoomName(roomName : String, withStrem : XMPPStream) -> String {
        var vHost : String = ""
        if let value = withStrem.hostName { vHost = value.trim() }
        return [roomName, "@conference.", vHost].joined(separator: "")
    }

    
    func getXMPPRoomHistiry(withTime time : Int64) -> XMLElement {
        //Get Message History. set value to return message.
        let history = XMLElement.init(name: "history")
        //history.addAttribute(withName: "maxstanzas", stringValue: "1000") //Set Value to return
        
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
        print("\(#function) | didSend message: \(message)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        print("\(#function) | didReceive message: \(message)")
        
        let vMessType : String = (message.type ?? "").trim()
        /*switch vMessType {
        case xmppChatType.CHAT:
            self.handel_ChatMessage(message)
            break
            
        case xmppChatType.NORMAL:
            self.handel_ChatMessage(message)
            break
            
        default:
            self.handel_ChatMessage(message)
            break
        }*/
        self.handel_ChatMessage(message, withType: vMessType)
    }
    
    func xmppStream(_ sender: XMPPStream, didFailToSend message: XMPPMessage, error: Error) {
        print("didFailToSend message : \(error.localizedDescription)")
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
            if let vMessId = value as? String {
                let vFrom : String = ""
                let vBody : String = ""
                let dicDate = ["type" : "incoming",
                               "id" : vMessId,
                               "from" : vFrom,
                               "body" : vBody,
                               "msgtype" : "normal"]
                APP_DELEGATE.objEventData!(dicDate)
            }
        }
    }    
}

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
}


//MARK:- Enum's
enum XMPPControllerError: Error {
    case wrongUserJID
}
enum xmppConnectionStatus : Int {
    case None
    case Processing
    case Sucess
    case Disconnect
    case Failed
    
    var value: Int {
        return rawValue
    }
}
enum Status {
    case Online
    case Offline
}


//MARK:- Struct's
struct xmppChatType {
    static let GROUPCHAT : String = "groupchat"
    static let CHAT : String = "chat"
    static let NORMAL : String = "normal"
}
struct xmppConstants {
    static let Resource : String = "iOS"
    static let BODY : String = "body"
    static let ID : String = "id"
    static let TO : String = "to"
    static let FROM : String = "from"
}

