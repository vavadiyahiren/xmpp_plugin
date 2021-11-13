import Flutter
import UIKit

public class FlutterXmppPlugin: NSObject, FlutterPlugin {
    
    static var  objEventChannel : FlutterEventChannel  =  FlutterEventChannel.init()
    var objEventData : FlutterEventSink?
    var objXMPP : XMPPController = XMPPController.sharedInstance
    var objXMPPConnStatus : xmppConnectionStatus = xmppConnectionStatus.None {
        didSet {
            postNotification(Name: .xmpp_ConnectionStatus)
        }
    }
    var singalCallBack : FlutterResult?
    
    //MARK:-
    override init() {
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_xmpp/method", binaryMessenger: registrar.messenger())
        let instance = FlutterXmppPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        objEventChannel = FlutterEventChannel(name: "flutter_xmpp/stream", binaryMessenger: registrar.messenger())
        objEventChannel.setStreamHandler(SwiftStreamHandler())
        
        APP_DELEGATE.manange_NotifcationObservers()
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let vMethod : String = call.method.trim()
        switch vMethod {
        case pluginMethod.login:
            self.hadleLoginActivity(call, result)
                        
        case pluginMethod.sendMessage,
             pluginMethod.sendMessageInGroup,
             pluginMethod.sendCustomMessage,
             pluginMethod.sendCustomMessageInGroup:
            self.hadleSendMessageActivity(call, result)
                        
        case pluginMethod.createMUC:
            self.hadleCreateMUCActivity(call, result)
            
        case pluginMethod.joinMUC:
            self.hadleJoinMUCActivity(call, result)
        
        case pluginMethod.sendReceiptDelivery:
            self.hadleReceiptDeliveryActivity(call, result)
            
        case pluginMethod.addMembersInGroup:
            self.hadleAddMembersInGroupActivity(call, result)
            
        case pluginMethod.addAdminsInGroup:
            self.hadleAddAdminsInGroupActivity(call, result)
            
        case pluginMethod.getMembers:
            self.hadleGetMembersInGroupActivity(call, result)
            
        case pluginMethod.getAdmins:
            self.hadleGetAdminsInGroupActivity(call, result)
        
        case pluginMethod.getOwners:
            self.hadleGetOwnersInGroupActivity(call, result)
            
        default:
            break
        }
        //result("iOS " + UIDevice.current.systemVersion)
    }
    
    func hadleLoginActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult)  {
        guard let vData = call.arguments as? [String : Any] else {
            result("Data nil");
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let vHost : String = (vData["host"] as? String ?? "").trim()
        let vPort : String = vData["port"] as? String ?? "0"
        var vUserId : String = (vData["user_jid"] as? String ?? "").trim()
        vUserId = (vUserId.components(separatedBy: "@").first ?? "").trim()
        let vPassword : String = (vData["password"] as? String ?? "").trim()
        
        if [vHost.count, vUserId.count, vPassword.count].contains(0) {
            result(xmppConstants.DataNil)
            return
        }
        if APP_DELEGATE.objXMPP.isSendMessage() {
            result(xmppConstants.SUCCESS)
            return
        }
        xmpp_HostName = vHost
        xmpp_HostPort = Int16(vPort) ?? 0
        xmpp_UserId = vUserId
        xmpp_UserPass = vPassword
        
        // TODO : Rename name
        self.performXMPPConnectionActivity()
        
        result(xmppConstants.SUCCESS)
    }
    
    func hadleSendMessageActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let toJid : String = (vData["to_jid"] as? String ?? "").trim()
        let body : String = vData["body"] as? String ?? ""
        let id : String = (vData["id"] as? String ?? "").trim()
        
        var customElement : String = ""
        if [pluginMethod.sendCustomMessage, pluginMethod.sendCustomMessageInGroup].contains(vMethod) {
            customElement = (vData["customText"] as? String ?? "").trim()
        }
        let isGroupMess : Bool = [pluginMethod.sendMessageInGroup, pluginMethod.sendCustomMessageInGroup].contains(vMethod)
        self.objXMPP.sendMessage(messageBody: body,
                                 reciverJID: toJid,
                                 messageId: id,
                                 isGroup: isGroupMess,
                                 customElement: customElement,
                                 withStrem: self.objXMPP.xmppStream)
        result(xmppConstants.SUCCESS)
    }
    
    func hadleCreateMUCActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        var isPersistent : Bool = default_isPersistent
        if let value = vData["persistent"] as? Bool {
            isPersistent = value
        }
        else if let value = vData["persistent"] as? String {
            isPersistent = value.boolValue
        }
        let objGroupInfo : groupInfo = groupInfo.init()
        objGroupInfo.name = vGroupName
        objGroupInfo.isPersistent = isPersistent
        APP_DELEGATE.objXMPP.createRoom(withRooms: [objGroupInfo], withStrem: self.objXMPP.xmppStream)
        result(xmppConstants.SUCCESS)
    }
    
    func hadleJoinMUCActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let arrRooms = vData["all_groups_ids"] as? [String] ?? []
        for vRoom  in arrRooms {
            let arrRoomCompo : [String] = vRoom.components(separatedBy: ",")
            let vRoomName : String = arrRoomCompo.first ?? ""
            let vRoomTS : String = arrRoomCompo.last ?? "0"
            if vRoomName.isEmpty { continue }
            let vRoomTSLongFormat : Int64 = Int64(vRoomTS) ?? 0
            APP_DELEGATE.objXMPP.joinRoom(roomName: vRoomName, time: vRoomTSLongFormat, withStrem: self.objXMPP.xmppStream)
        }
        result(xmppConstants.SUCCESS)
    }
    
    func hadleReceiptDeliveryActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let toJid : String = (vData["toJid"] as? String ?? "").trim()
        let msgId : String = vData["msgId"] as? String ?? ""
        let receiptId : String = (vData["receiptId"] as? String ?? "").trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | toJid: \(toJid) | msgId : \(msgId) | receiptId: \(receiptId)")
        
        self.objXMPP.sentMessageDeliveryReceipt(withReceiptId: receiptId,
                                                jid: toJid,
                                                messageId: msgId,
                                                withStrem: self.objXMPP.xmppStream)
        result(xmppConstants.SUCCESS)
    }
        
    func hadleAddMembersInGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        let membersJids : [String] = vData["members_jid"] as? [String] ?? []
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | vGroupName: \(vGroupName) | membersJids : \(membersJids)")
        
        APP_DELEGATE.objXMPP.addMemberInRoom(withUserRole: .Member,
                                             withRoomName: vGroupName,
                                             withUsers: membersJids,
                                             withStrem: self.objXMPP.xmppStream)
        result(xmppConstants.SUCCESS)
    }
    
    func hadleAddAdminsInGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        let membersJids : [String] = vData["members_jid"] as? [String] ?? []
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | vGroupName: \(vGroupName) | membersJids : \(membersJids)")
        
        APP_DELEGATE.objXMPP.addMemberInRoom(withUserRole: .Admin,
                                             withRoomName: vGroupName,
                                             withUsers: membersJids,
                                             withStrem: self.objXMPP.xmppStream)
        result(xmppConstants.SUCCESS)
    }
    
    func hadleGetMembersInGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | vGroupName: \(vGroupName)")
        
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.getRoomMember(withUserType: .Member,
                                           forRoomName: vGroupName,
                                           withStrem: self.objXMPP.xmppStream)
    }
    
    func hadleGetAdminsInGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | vGroupName: \(vGroupName)")
        
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.getRoomMember(withUserType: .Admin,
                                           forRoomName: vGroupName,
                                           withStrem: self.objXMPP.xmppStream)
    }
    
    func hadleGetOwnersInGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | vGroupName: \(vGroupName)")
        
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.getRoomMember(withUserType: .Owner,
                                           forRoomName: vGroupName,
                                           withStrem: self.objXMPP.xmppStream)
    }
    
    //MARK: - perform XMPP Connection
    func performXMPPConnectionActivity() {
        switch APP_DELEGATE.objXMPPConnStatus {
        case .None,
             .Failed:
            APP_DELEGATE.objXMPPConnStatus = .Processing
            do {
                try self.objXMPP = XMPPController.init(hostName: xmpp_HostName, hostPort: xmpp_HostPort, userId: xmpp_UserId, password: xmpp_UserPass)
                self.objXMPP.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
                self.objXMPP.connect()
            } catch {
                APP_DELEGATE.performXMPPConnectionActivity()
            }
            break
            
        case .Processing:
            break
            
        case .Disconnect:
            APP_DELEGATE.objXMPPConnStatus = .None
            APP_DELEGATE.performXMPPConnectionActivity()
            break
            
        default:
            break
        }
    }
    
    public func manange_NotifcationObservers()  {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(notiObs_XMPPConnectionStatus(notfication:)), name: .xmpp_ConnectionStatus, object: nil)
    }
    
    @objc func notiObs_XMPPConnectionStatus(notfication: NSNotification) {
        var valueStatus : String = ""
        switch objXMPPConnStatus {
        case .Processing:
            //valueStatus = xmppConnStatus.Processing
            break
            
        case .Sucess:
            valueStatus = xmppConnStatus.Authenticated
            
        case .Failed:
            valueStatus = xmppConnStatus.Failed
            
            
        case .Disconnect,
             .None:
            valueStatus = xmppConnStatus.Disconnect
        }
        if valueStatus.isEmpty {
            print("\(#function) | XMPPConnetion status nil/empty.")
            return
        }
        
        var dicDate : [String : Any] = [:]
        dicDate["id"] = valueStatus
        dicDate["message"] = valueStatus
        dicDate["msgtype"] = valueStatus
        
        /// Send data back to flutter event handler.
        guard let objEventData = APP_DELEGATE.objEventData else {
            printLog("\(#function) | Nil/Empty of APP_DELEGATE.objEventData | \(dicDate)")
            return
        }
        objEventData(dicDate)
    }
}

class SwiftStreamHandler: NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        APP_DELEGATE.objEventData = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}
