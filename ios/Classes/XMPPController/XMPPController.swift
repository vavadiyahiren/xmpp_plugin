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
    
    /// Using get chat Archive Messages
    var xmppMAM: XMPPMessageArchiveManagement? // = XMPPMessageArchiveManagement.init()
    
    internal var hostName: String = ""
    internal var hostPort: Int16 = 0
    internal var userId: String = ""
    internal var userJID = XMPPJID()
    private var password: String = ""
    internal var arrGroups : [groupInfo] = []
    
    //MARK:-
    override init() {
        super.init()
    }
    
    init(hostName: String, hostPort : Int16, userId: String, password: String, resource: String) throws {
        super.init()
        
        let stUserJid = "\(userId)@\(hostName)"
        guard let userJID = XMPPJID.init(string: stUserJid, resource: resource) else {
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
        
        //SSL Connection
        if xmpp_RequireSSLConnection {
            self.xmppStream.startTLSPolicy = XMPPStreamStartTLSPolicy.required
        }
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
        
        //Archive Messge
        self.xmppMAM = XMPPMessageArchiveManagement.init()
        self.xmppMAM?.activate(self.xmppStream)
        self.xmppMAM?.addDelegate(self, delegateQueue: DispatchQueue.main)
        self.xmppMAM?.retrieveFormFields()
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
    
    func disconnect(withStrem: XMPPStream) {
        self.changeStatus(.Offline, withXMPPStrem: withStrem)
        self.xmppStream.disconnectAfterSending()
        
        APP_DELEGATE.objXMPPConnStatus = .Disconnect
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
//        guard let err = error else {
//            printLog("\(#function) | Not getting any error.")
//
//        }
        //print("\(#function) | XMPP Server connection error | error: \(err.localizedDescription)")
        
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

//MARK: - XMPPMessage
extension XMPPController {
    //MARK: XMPPMessage delegate methods
    func xmppStream(_ sender: XMPPStream, didSend message: XMPPMessage) {
        printLog("\(#function) | didSend message: \(message)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive message: XMPPMessage) {
        addLogger(.receiveMessageFromServer, message)
        printLog("\(#function) | didReceive message: \(message)")
        
        //------------------------------------------------------------------------
        // Manange MAM Message
        if let objMessMAM = message.mamResult?.forwardedMessage  {
            self.manageMAMMessage(message: objMessMAM)
            return
        }
        
        //------------------------------------------------------------------------
        //Other Chat message received
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
        addLogger(.receiveStanzaAckFromServer, stanzaIds)
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

    func getTimeElementInfo() -> String {
        var value : String = "0"
        let arrMI = self.elements(forName: eleTIME.Name)
        guard let eleMI = arrMI.first else {
            return value
        }
        
        let arrMInfo = eleMI.elements(forName: eleTIME.Kay)
        guard let vInfo = arrMInfo.first?.stringValue else {
            return value
        }
        value = vInfo.trim()
        return value
    }

    func getCustomElementInfo(withKey vKey : String) -> String {
        var value : String = ""
        let arrMI = self.elements(forName: eleCustom.Name)
        guard let eleMI = arrMI.first else {
            return value
        }
        
        let arrMInfo = eleMI.elements(forName: vKey)
        guard let vInfo = arrMInfo.first?.stringValue else {
            return value
        }
        value = vInfo.trim()
        return value
    }
}

extension DDXMLElement {

    func getElements(withKey vKey : String) -> [DDXMLElement] {
        return self.elements(forName: vKey)
    }
    
    func getValue(withKey vKey : String) -> String? {
        var value : String = ""
        guard let vInfo = self.stringValue else {
            return value
        }
        value = vInfo.trim()
        return value
    }
}
