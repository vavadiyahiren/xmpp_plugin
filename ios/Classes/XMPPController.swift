//
//  XMPPController.swift
//
//

import UIKit
import XMPPFramework
import flutter_xmpp

class XMPPController : NSObject {
    //MARK:- Variable
    static let sharedInstance = XMPPController()
    
    //TODO:
    var xmppStream = XMPPStream()
    
    var xmppReconnect = XMPPReconnect()
    var xmppMessage = XMPPMessage()
    var xmppRoom : XMPPRoom?
    
    var xmppPrivacy = XMPPPrivacy()
    //var xmppStreamManagement : XMPPStreamManagement?
    var xmppStreamManagement : XMPPStreamManagement = XMPPStreamManagement(storage: XMPPStreamManagementMemoryStorage.init(), dispatchQueue: DispatchQueue.main)
    
    var xmppDeliveryReceipts = XMPPMessageDeliveryReceipts.init() //https://sco0ter.bitbucket.io/babbler/xep/receipts.html

    
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
        //guard let userJID = XMPPJID.init(string: stUserJid) else {
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
        //self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.allowed
        self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.required
        //self.xmppStream.enableBackgroundingOnSocket = true
                
        
        //--------
        //https://github.com/robbiehanson/XMPPFramework/issues/34#issuecomment-42228805
        //https://stackoverflow.com/a/20880146
        xmppDeliveryReceipts = XMPPMessageDeliveryReceipts.init(dispatchQueue: DispatchQueue.main)
        //xmppDeliveryReceipts.autoSendMessageDeliveryReceipts = true
        //xmppDeliveryReceipts.autoSendMessageDeliveryRequests = true
        
        xmppReconnect = XMPPReconnect()
        xmppMessage = XMPPMessage.init()
        xmppMessage.addReceiptRequest()
        xmppMessage.addMarkableChatMarker()
        
        xmppPrivacy = XMPPPrivacy.init(dispatchQueue: DispatchQueue.main)
        
        // Activate xmpp modules
        xmppReconnect.activate(xmppStream)
        xmppPrivacy.activate(xmppStream)
        xmppDeliveryReceipts.activate(self.xmppStream)
        
        // Add ourself as a delegate to anything we may be interested in
        self.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppPrivacy.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppDeliveryReceipts.addDelegate(self, delegateQueue: DispatchQueue.main)
        
        
        //DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        //self.configureStreamManagement()
        //}
//        let xmppSMMS = XMPPStreamManagementMemoryStorage.init()
//        xmppStreamManagement = XMPPStreamManagement(storage: xmppSMMS, dispatchQueue: DispatchQueue.main)
//        xmppStreamManagement.addDelegate(self, delegateQueue: DispatchQueue.main)
//        xmppStreamManagement.activate(self.xmppStream)
    }
    
    
    func connect() {
        //Check internet connection.
        /*if isConnectedToNetwork() == false {
         print(" I AM GETTING CALLED IN LOOP AND I AM CALLING XMPP STREAM WITHOUT INTERNET HENCE LIFE IS GOING TO BE HELL IF IT HAPPENS")
         return
         }*/
        
        if self.xmppStream.isDisconnected {
            print("XMPPController | \(#function) | XMPPConnected - No")
            
            do {
                var vTimeout : TimeInterval = XMPPStreamTimeoutNone
                vTimeout = 60.00
                try self.xmppStream.connect(withTimeout: vTimeout)
                APP_DELEGATE.objXMPPConnStatus = .Processing
            } catch let error{
                print(error)
                print("Error: connect()")
                APP_DELEGATE.objXMPPConnStatus = .Failed
            }
        } else {
            print("XMPPController | \(#function) | XMPPConnected - Yes")
        }
    }
    
    func disconnect() {
        self.changeStatus(.Offline)
        self.xmppStream.disconnect()
        APP_DELEGATE.objXMPPConnStatus = .Disconnect
    }
    
    func restart() {
        self.xmppStream.disconnect()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.connect()
        }
    }
    
    func isConnected() ->Bool {
        return APP_DELEGATE.objXMPP.xmppStream.isConnected
    }
    
    func isAuthenticated() ->Bool {
        return APP_DELEGATE.objXMPP.xmppStream.isAuthenticated
    }
    
    func isSendMessage() ->Bool {
        return (self.isConnected() && self.isAuthenticated())
    }
    
    //MARK:- User status
    func changeStatus(_ UserStatus: Status) {
        let presence = XMPPPresence()
        switch UserStatus {
        case .Online:
            presence.addAttribute(withName: "status", stringValue: "online")
        case .Offline:
            presence.addAttribute(withName: "status", stringValue: "unavailable")
        }
        self.xmppStream.send(presence)
    }
    
    //https://stackoverflow.com/a/51018129
    //Other:
    //https://www.ejabberd.im/node/24766/index.html
    //https://github.com/robbiehanson/XMPPFramework/issues/34#issuecomment-185838413
    //https://www.e-learn.cn/topic/1100175
    // Stream Management
    func configureStreamManagement() {
        let xmppSMMS = XMPPStreamManagementMemoryStorage.init()
        xmppStreamManagement = XMPPStreamManagement(storage: xmppSMMS, dispatchQueue: DispatchQueue.main)
        xmppStreamManagement.addDelegate(self, delegateQueue: DispatchQueue.main)
        xmppStreamManagement.activate(self.xmppStream)
        
        xmppStreamManagement.autoResume = true
        xmppStreamManagement.ackResponseDelay = 1.0
        xmppStreamManagement.requestAck()
        xmppStreamManagement.automaticallyRequestAcks(afterStanzaCount: 1, orTimeout: 10)
        xmppStreamManagement.automaticallySendAcks(afterStanzaCount: 1, orTimeout: 10)
        xmppStreamManagement.enable(withResumption: true, maxTimeout: 10)
        
        xmppStreamManagement.sendAck()
        xmppStream.register(xmppStreamManagement)
    }
}

extension XMPPController: XMPPStreamDelegate, XMPPMUCLightDelegate, XMPPHTPPFileUploadDelegate  {
    //Isuse : https://github.com/robbiehanson/XMPPFramework/issues/52#issue-4796378
    
    //MARK:- stream Connect
    func xmppStreamDidConnect(_ stream: XMPPStream) {
        print("XMPPController | \(#function) | userJid: \(self.userJID) | xmpp Connect Status - Yes")
        if self.password.count == 0 {
            print("XMPPController | \(#function) | userJid: \(self.userJID) | xmpp Connect Status - YES | Not perform user authenticate. RREASON: Password empty!")
            return
        }
        do {
            print("XMPPController | \(#function) | userJid: \(self.userJID) | perform user authentication activity.")
            try stream.authenticate(withPassword: self.password)
        } catch {
            print("XMPPController | \(#function) | userJid: \(self.userJID) | xmpp Connect Status - No")
            
            APP_DELEGATE.objXMPPConnStatus = .Disconnect
            APP_DELEGATE.perform_connectToXMPP()
        }
    }
    
    func xmppStreamDidDisconnect(_ sender: XMPPStream, withError error: Error?) {
        if let err = error {
            print("XMPPController | \(#function) | userJid: \(self.userJID) | Error: \(err.localizedDescription)")
            
            self.changeStatus(.Offline)
            APP_DELEGATE.objXMPPConnStatus = .Disconnect
            APP_DELEGATE.perform_connectToXMPP()
            return
        }
        print("XMPPController | \(#function) | userJid: \(self.userJID) | Success")
    }
    
    //MARK:- Authenticate
    func xmppStreamDidAuthenticate(_ sender: XMPPStream) {
        print("XMPPController | \(#function) | userJid: \(self.userJID) | User Authenticate - Yes")
        
        configureStreamManagement()
        //xmppStreamManagement!.activate(self.xmppStream)
        //xmppStreamManagement!.activate(sender)
        //xmppStreamManagement!.enable(withResumption: true, maxTimeout: 100000)
        
        APP_DELEGATE.objXMPPConnStatus = .Sucess
        self.changeStatus(.Online)
    }
    
    func xmppStream(_ sender: XMPPStream, didNotAuthenticate error: DDXMLElement) {
        print("XMPPController | \(#function) | userJid: \(self.userJID) | User Authenticate - No | Error: \(error.description)")
        
        //print("User: Authenticated - Error: \(error.description))")
        APP_DELEGATE.objXMPPConnStatus = .Failed
        
        //Again try to join xmpp
        APP_DELEGATE.perform_connectToXMPP()
    }
    
    //MARK:- XMPPIQ
    func xmppStream(_ sender: XMPPStream, didSend iq: XMPPIQ) {
        //print("didSend iq : \(iq)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive iq: XMPPIQ) -> Bool {
        print("didReceive iq : \(iq)")
        return false
    }
    
    func xmppStream(_ sender: XMPPStream, didFailToSend iq: XMPPIQ, error: Error) {
        print("didFailToSend iq : \(error.localizedDescription)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceiveError error: DDXMLElement) {
        print("didReceiveError : \(error)")
    }
    
    //MARK:- XMPPPresence
    func xmppStream(_ sender: XMPPStream, didSend presence: XMPPPresence) {
        print("\(#function) | presence: \(presence)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        print("XMPPController | Presence: \(presence)")
    }
}

//MARK: - XMPPRoom
extension XMPPController : XMPPRoomDelegate {
    //TODO: Delegate methods
    
    func xmppRoomDidCreate(_ sender: XMPPRoom) {
        var vRoom : String = ""
        if let value = sender.myRoomJID?.bareJID.user {
            vRoom = "\(value)"
            print("\(#function) | roomName: \(vRoom)")
         
            self.joinRoom(roomName: vRoom, time: 0)
        } else {
            print("\(#function) | roomName: \(vRoom) | Error")
        }
    }
    
    func xmppRoomDidJoin(_ sender: XMPPRoom) {
        var vRoom : String = ""
        if let value = sender.myRoomJID?.bareJID.user {
            vRoom = "\(value)"
            print("XMPPController | \(#function) | roomName: \(vRoom)")
            
        } else {
            print("XMPPController | \(#function) | roomName: \(vRoom) | Error")
        }
    }
    
    /*
    //TODO: Room/Chatroom
    func get_RoomName(roomName : String) -> String {
        let vChatRoomName : String = [roomName, "@conference.", HOST_NAME].joined(separator: "")
        return vChatRoomName
    }
    func get_JidName_Channel(_ Jid : String) -> String {
        let vChatRoomName : String = [Jid, "@conference.", HOST_NAME].joined(separator: "")
        return vChatRoomName
    }
    func get_JidName_User(_ Jid : String) -> String {
        if Jid.count == 0 { return Jid }
        if Jid.contains(HOST_NAME) == true { return Jid }
        let vChatRoomName : String = [Jid, "@", HOST_NAME].joined(separator: "")
        return vChatRoomName
    }*/
    
    func createRoom(roomName: String) {
        if roomName.trim().count == 0 { return }
        
        let roomMS : XMPPRoomMemoryStorage = XMPPRoomMemoryStorage.init()
        if let roomJID = XMPPJID(string: roomName) {
            
            self.xmppRoom = XMPPRoom.init(roomStorage: roomMS, jid: roomJID)
            self.xmppRoom!.activate(self.xmppStream)
            self.xmppRoom!.addDelegate(self, delegateQueue: DispatchQueue.main)
            
            let history = XMLElement.init(name: "history")
            history.addAttribute(withName: "maxstanzas", stringValue: "0") //Set Value to return Value-Of-No-Messsage in Chat room
            self.xmppRoom?.join(usingNickname: self.userId, history: history)
            
            //self.joinRoom(roomName: roomName, time: 0)
        }
    }
    
    func joinRoom(roomName: String, time : Int64) {
        if roomName.trim().count == 0 { return }
        
        //-> https://stackoverflow.com/a/19438542/5593725
        //-> https://github.com/robbiehanson/XMPPFramework/issues/206#issuecomment-19737322
        //let xmppJID = XMPPJID(string: get_RoomName(roomName: roomName))
        let xmppJID = XMPPJID(string: roomName)
        if let roomMemory = XMPPRoomMemoryStorage.init() {
            let room : XMPPRoom = XMPPRoom.init(roomStorage: roomMemory, jid: xmppJID!)
            room.activate(self.xmppStream)
            room.fetchConfigurationForm()
            room.addDelegate(self, delegateQueue: DispatchQueue.main)
                        
            //Get Message History. set value to return message.
            let history = XMLElement.init(name: "history")
            history.addAttribute(withName: "maxstanzas", stringValue: "1") //Set Value to return Value-Of-No-Messsage in Chat room
            
            //-------------------------
            //Time send in Second | Source:
            //print("RoomName-time: \(vRoomName) - \(time)")
            //let currentTime : Int64 = Int64(NSDate().timeIntervalSince1970 * 1000)
            //let vTimeSecond : Int64 = (currentTime - time) / 1000
            
            //Send timestamp value to get message after send timestamp
            //history.addAttribute(withName: "seconds", stringValue: vTimeSecond.description)
            room.join(usingNickname: self.userId, history: history)
            //debugPrintLog("XMPPController | \(#function) | RoomName-time-vTimeSecond: \(roomName) - \(time) - \(vTimeSecond.description)")
            
            print("Room Jooining Log: \(roomName)")
        }
    }
}

//MARK: - XMPPMessage
extension XMPPController {
    //MARK: XMPPMessage delegate methods
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        print("\n\(#function) | didSend message: \n\(message)")
        
        /*if message.isChatMessage {
            if let mess = message.generateReceiptResponse  {
                //self.xmppMessage = mess
                self.xmppMessage.addChild(mess)
            }
        }*/
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        print("\n\(#function) | Message: \n\(message)")
        
        let vMessType : String = (message.type ?? "").trim()
        switch vMessType {
        case xmppChatType.GROUPCHAT:
            //TODO: GROUPCHAT
            self.handel_GroupMessage(message)
            break
            
        case xmppChatType.CHAT:
            //TODO: CHAT
            self.handel_ChatMessage(message)
            break
            
        case xmppChatType.NORMAL:
            //TODO: NORMAL
            self.handel_ChatMessage(message)
            break
            
        default:
            self.handel_ChatMessage(message)
            print("XMPPController | \(#function) | New message type: \(vMessType)")
            break
        }
    }
    
    //Source: https://stackoverflow.com/a/53531672/5593725
    func xmppStream(_ sender: XMPPStream, didFailToSend message: XMPPMessage, error: Error) {
        print("didFailToSend message : \(error.localizedDescription)")
    }
}

extension XMPPController : XMPPStreamManagementDelegate {
    internal func xmppStreamManagement(_ sender: XMPPStreamManagement, wasEnabled enabled: DDXMLElement) {
        print("Stream Management: enabled")
    }
    internal func xmppStreamManagement(_ sender: XMPPStreamManagement, wasNotEnabled failed: DDXMLElement) {
        print("Stream Management: not enabled")
    }
    func xmppStreamManagement(_ sender: XMPPStreamManagement, didReceiveAckForStanzaIds stanzaIds: [Any]) {
        print("\(#function) | stanzaId: \(stanzaIds)")
        
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
                print("\(#function) | dicDate: \(dicDate)")
                APP_DELEGATE.objEventData!(dicDate)
            }
        }
    }
    
    /*public func xmppStreamManagement(_ sender: XMPPStreamManagement, stanzaIdForSentElement element: XMPPElement) -> Any? {
        print("\(#function) | stanzaId: \(element)")
    }*/
    
    /*public func xmppStreamManagementDidRequestAck(_ sender: XMPPStreamManagement) {
        print("\(#function) | sender: \(sender)")
    }*/
    
    /*public func xmppStreamManagement(_ sender: XMPPStreamManagement, getIsHandled isHandledPtr: UnsafeMutablePointer<ObjCBool>?, stanzaId stanzaIdPtr: AutoreleasingUnsafeMutablePointer<AnyObject?>?, forReceivedElement element: XMPPElement) {
        print("\(#function) | element: \(element)")
    }*/
    
}

extension XMPPController : XMPPMessageDeliveryReceiptsDelegate {
    public func xmppMessageDeliveryReceipts(_ xmppMessageDeliveryReceipts: XMPPMessageDeliveryReceipts, didReceiveReceiptResponseMessage message: XMPPMessage) {
        print("\(#function) | message: \(message)")
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

struct CONVERSATION_TYPE {
    static let SELF : Int16 = 0 //LOGIN USER OWN DETAILS
    static let NORMAL : Int16 = 1 //Store Users/Members info of member of Channel/Chatroom/Group
    static let GROUP : Int16 = 2 //Store Particuler Channel/Chatroom/Group Info
    static let CHANNEL : Int16 = 3 //Not Implement
    static let BROADCAST : Int16 = 4 //Not Implement
}

struct eleRECEIVED {
  static let ELEMENT : String = "received"
  static let NAMESPACE : String = "urn:xmpp:receipts"
}

//MARK:-
/*
 // FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
 // Consider refactoring the code to use the non-optional operators.
 fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
 switch (lhs, rhs) {
 case let (l?, r?):
 return l < r
 case (nil, _?):
 return true
 default:
 return false
 }
 }
 
 // FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
 // Consider refactoring the code to use the non-optional operators.
 fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
 switch (lhs, rhs) {
 case let (l?, r?):
 return l > r
 default:
 return rhs < lhs
 }
 }*/

