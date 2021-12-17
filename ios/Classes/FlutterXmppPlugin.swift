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
    
    var objXMPPLogger : xmppLoggerInfo?
    
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
    //MARK: -
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        addLogger(.receiveFromFlutter, call)
        
        let vMethod : String = call.method.trim()
        switch vMethod {
        case pluginMethod.login:
            self.performLoginActivity(call, result)
               
        case pluginMethod.logout:
            self.performLogoutActivity(call, result)
            
        case pluginMethod.sendMessage,
             pluginMethod.sendMessageInGroup,
             pluginMethod.sendCustomMessage,
             pluginMethod.sendCustomMessageInGroup:
            self.performSendMessageActivity(call, result)
                        
        case pluginMethod.createMUC:
            self.performCreateMUCActivity(call, result)
            
        case pluginMethod.joinMUCGroups:
            self.performJoinMUCGroupsActivity(call, result)
        
        case pluginMethod.joinMUCGroup:
            self.performJoinMUCGroupActivity(call, result)
            
        case pluginMethod.sendReceiptDelivery:
            self.performReceiptDeliveryActivity(call, result)
            
        case pluginMethod.addMembersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Member, actionType: .Add, call, result)
            
        case pluginMethod.addAdminsInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Admin, actionType: .Add, call, result)
            
        case pluginMethod.addOwnersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Owner, actionType: .Add, call, result)
            
        case pluginMethod.getMembers:
            self.performGetMembersInGroupActivity(withMemeberType: .Member, call, result)
            
        case pluginMethod.getAdmins:
            self.performGetMembersInGroupActivity(withMemeberType: .Admin, call, result)
            
        case pluginMethod.getOwners:
            self.performGetMembersInGroupActivity(withMemeberType: .Owner, call, result)
            
        case pluginMethod.removeMembersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Member, actionType: .Remove, call, result)
        
        case pluginMethod.removeAdminsInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Admin, actionType: .Remove, call, result)
            
        case pluginMethod.removeOwnersInGroup:
            self.performAddRemoveMembersInGroupActivity(withMemeberType: .Owner, actionType: .Remove, call, result)
        
        case pluginMethod.getLastSeen:
            self.performLastActivity(call, result)
            
        case pluginMethod.createRosters:
            self.createRostersActivity(call, result)
            
        case pluginMethod.getMyRosters:
            self.getMyRostersActivity(call, result)
            
        default:
            guard let vData = call.arguments as? [String : Any] else {
                print("Getting invalid/nil arguments-data by pluging.... | \(vMethod) | arguments: \(String(describing: call.arguments))")
                
                result(xmppConstants.ERROR)
                return
            }
            print("\(#function) | Not handel arguments-data by pluging.... | \(vMethod) | arguments: \(vData)")
            break
        }
        //result("iOS " + UIDevice.current.systemVersion)
    }
    
    func performLoginActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult)  {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.DataNil);
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let vHost : String = (vData["host"] as? String ?? "").trim()
        let vPort : String = (vData["port"] as? String ?? "0").trim()
        let vUserId : String = (vData["user_jid"] as? String ?? "").trim()
        let vUserJid = (vUserId.components(separatedBy: "@").first ?? "").trim()
        
        var vResource : String = xmppConstants.Resource
        let arrResource = vUserId.components(separatedBy: "/")
        if arrResource.count == 2 {
            vResource = (arrResource.last ?? vResource).trim()
        }
        let vPassword : String = (vData["password"] as? String ?? "").trim()
        let vLogPath : String = (vData["nativeLogFilePath"] as? String ?? "").trim()
        
        if [vHost.count, vUserJid.count, vPassword.count].contains(0) {
            result(xmppConstants.DataNil)
            return
        }
        if APP_DELEGATE.objXMPP.isSendMessage() {
            result(xmppConstants.SUCCESS)
            return
        }
        // Logs
        if self.setupXMPPLoggerSetting(withLogFileUrl: vLogPath) {
            addLogger(.receiveFromFlutter, call)
        }
        
        xmpp_HostName = vHost
        xmpp_HostPort = Int16(vPort) ?? 0
        xmpp_UserId = vUserJid
        xmpp_UserPass = vPassword
        xmpp_Resource = vResource
        
        self.performXMPPConnectionActivity()
        result(xmppConstants.SUCCESS)
    }
    
    func setupXMPPLoggerSetting(withLogFileUrl urlString: String) -> Bool {
        if urlString.trim().isEmpty {
            printLog("\(#function) | Getting nativeLogFilePath is empty.")
            return false
        }
        guard let urlLogFile = URL(string: urlString) else {
            printLog("\(#function) | Invalid nativeLogFilePath | path: \(urlString)")
            return false
        }
        let objLogger = xmppLoggerInfo.init()
        objLogger.isLogEnable = true
        objLogger.logPath = urlLogFile.absoluteString
        
        APP_DELEGATE.objXMPPLogger = objLogger
        return true
    }
    
    func performLogoutActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        var dicData : [String : Any] = [:]
        if let dic = call.arguments as? [String : Any] {
            dicData = dic
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(dicData)")
        self.objXMPP.disconnect(withStrem: self.objXMPP.xmppStream)
    }
    
    func performSendMessageActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let toJid : String = (vData["to_jid"] as? String ?? "").trim()
        let body : String = vData["body"] as? String ?? ""
        let id : String = (vData["id"] as? String ?? "").trim()
        let time : String = (vData["time"] as? String ?? "0").trim()
        
        var customElement : String = ""
        if [pluginMethod.sendCustomMessage, pluginMethod.sendCustomMessageInGroup].contains(vMethod) {
            customElement = (vData["customText"] as? String ?? "").trim()
        }
        let isGroupMess : Bool = [pluginMethod.sendMessageInGroup, pluginMethod.sendCustomMessageInGroup].contains(vMethod)
        self.objXMPP.sendMessage(messageBody: body,
                                 time: time,
                                 reciverJID: toJid,
                                 messageId: id,
                                 isGroup: isGroupMess,
                                 customElement: customElement,
                                 withStrem: self.objXMPP.xmppStream)
        result(xmppConstants.SUCCESS)
    }
    
    func performCreateMUCActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
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
        
        if !self.isValidMUCInfo(withRoomName: vGroupName) {
            printLog("\(#function) | \(vMethod) | invalid groupname validation : \(vGroupName)")
            result(false)
            return
        }
        
        printLog("\(#function) | \(vMethod) | after validation : \(vData)")
        
        let objGroupInfo : groupInfo = groupInfo.init()
        objGroupInfo.name = vGroupName
        objGroupInfo.isPersistent = isPersistent
        
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.createRoom(withRooms: [objGroupInfo], withStrem: self.objXMPP.xmppStream)
        //result(xmppConstants.SUCCESS)
    }
    
    func performJoinMUCGroupsActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let arrRooms = vData["all_groups_ids"] as? [String] ?? []
        for vRoom  in arrRooms {
            let arrRoomCompo : [String] = vRoom.components(separatedBy: ",")
            if arrRoomCompo.count != 2 { continue }
            
            let vRoomName : String = arrRoomCompo.first ?? ""
            let vRoomTS : String = arrRoomCompo.last ?? "0"
            let vRoomTSLongFormat : Int64 = Int64(vRoomTS) ?? 0
            
            if !self.isValidMUCInfo(withRoomName: vRoomName, timeStamp: vRoomTSLongFormat) {
                result(false)
                continue
            }
            APP_DELEGATE.objXMPP.joinRoom(roomName: vRoomName, time: vRoomTSLongFormat, withStrem: self.objXMPP.xmppStream)
        }
        //result(xmppConstants.SUCCESS)
        result(true)
    }
    
    func performJoinMUCGroupActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        let vRoom = vData["group_id"] as? String ?? ""
        let arrRoomCompo : [String] = vRoom.components(separatedBy: ",")
        if arrRoomCompo.count != 2 {
            result(false)
            return
        }
        let vRoomName : String = arrRoomCompo.first ?? ""
        let vRoomTS : String = arrRoomCompo.last ?? "0"
        let vRoomTSLongFormat : Int64 = Int64(vRoomTS) ?? 0
        
        if !self.isValidMUCInfo(withRoomName: vRoomName, timeStamp: vRoomTSLongFormat) {
            result(false)
            return
        }
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.joinRoom(roomName: vRoomName, time: vRoomTSLongFormat, withStrem: self.objXMPP.xmppStream)
        //result(true)
    }
    
    func performReceiptDeliveryActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
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
    
    func performAddRemoveMembersInGroupActivity(withMemeberType type : xmppMUCUserType,
                                              actionType: xmppMUCUserActionType,
                                              _ call: FlutterMethodCall,
                                              _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        let membersJids : [String] = vData["members_jid"] as? [String] ?? []
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | vGroupName: \(vGroupName) | membersJids : \(membersJids)")
        
        APP_DELEGATE.objXMPP.addRemoveMemberInRoom(withUserRole: type,
                                                   actionType: actionType,
                                                   withRoomName: vGroupName,
                                                   withUsers: membersJids,
                                                   withStrem: self.objXMPP.xmppStream)
    }
    
    func performGetMembersInGroupActivity(withMemeberType type : xmppMUCUserType,
                                        _ call: FlutterMethodCall,
                                        _ result: @escaping FlutterResult) {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.ERROR)
            return
        }
        let vMethod : String = call.method.trim()
        let vGroupName : String = (vData["group_name"] as? String ?? "").trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData) | vGroupName: \(vGroupName)")
        
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.getRoomMember(withUserType: type,
                                           forRoomName: vGroupName,
                                           withStrem: self.objXMPP.xmppStream)
    }
    
    func performLastActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult)  {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.DataNil);
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        var vUserId : String = (vData["user_jid"] as? String ?? "").trim()
        vUserId = (vUserId.components(separatedBy: "@").first ?? "").trim()
        
        if vUserId.isEmpty {
            result(xmppConstants.DataNil)
            return
        }
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.getLastActivity(withUserJid: vUserId,
                                             withStrem: self.objXMPP.xmppStream,
                                             objXMPP: self.objXMPP)
        printLog("\(#function) | \(vMethod) | vUserId: \(vUserId)")
        //result(xmppConstants.SUCCESS)
    }
    
    func createRostersActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult)  {
        guard let vData = call.arguments as? [String : Any] else {
            result(xmppConstants.DataNil);
            return
        }
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(vData)")
        
        var vUserId : String = (vData["user_jid"] as? String ?? "").trim()
        vUserId = (vUserId.components(separatedBy: "@").first ?? "").trim()
        
        if vUserId.isEmpty {
            result(xmppConstants.DataNil)
            return
        }
        APP_DELEGATE.objXMPP.createRosters(withUserJid: vUserId, withStrem: self.objXMPP.xmppStream, objXMPP: self.objXMPP)
        //result(xmppConstants.SUCCESS)
    }
    
    func getMyRostersActivity(_ call: FlutterMethodCall, _ result: @escaping FlutterResult)  {
        var vData : [String : Any]?
        if let data = call.arguments as? [String : Any] { vData = data }
        
        let vMethod : String = call.method.trim()
        printLog("\(#function) | \(vMethod) | arguments: \(String(describing: vData))")
                
        APP_DELEGATE.singalCallBack = result
        APP_DELEGATE.objXMPP.getMyRosters(withStrem: self.objXMPP.xmppStream, objXMPP: self.objXMPP)
        //result(xmppConstants.SUCCESS)
    }
    
    //MARK: - perform XMPP Connection
    func performXMPPConnectionActivity() {
        switch APP_DELEGATE.objXMPPConnStatus {
        case .None,
             .Failed:
            APP_DELEGATE.objXMPPConnStatus = .Processing
            do {
                try self.objXMPP = XMPPController.init(hostName: xmpp_HostName,
                                                       hostPort: xmpp_HostPort,
                                                       userId: xmpp_UserId,
                                                       password: xmpp_UserPass,
                                                       resource: xmpp_Resource)
                self.objXMPP.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
                self.objXMPP.connect()
            } catch let err {
                print("\(#function) | Getting error on XMPP Connect | error : \(err.localizedDescription)")
            }
            
        case .Processing:
            break
            
        case .Disconnect:
            APP_DELEGATE.objXMPPConnStatus = .None
            
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
    
    //MARK: - MUC Validation
    func isValidMUCInfo(withRoomName vRoom : String) -> Bool {
        if vRoom.trim().isEmpty {
            printLog("\(#function) | MUCRoomName is empty.")
            return false
        }
        
        if vRoom.containsWhitespace {
            printLog("\(#function) | MUCRoomName is invalid | Its contail whitespapce | MUCRoomName: \(vRoom)")
            return false
        }
        printLog("returning true ")
        return true
    }
    
    func isValidMUCInfo(withRoomName vRoom : String, timeStamp : Int64) -> Bool {
        if !self.isValidMUCInfo(withRoomName: vRoom) {
            return false
        }
        
        let vCurretTimeStamp = getTimeStamp()
        if timeStamp > vCurretTimeStamp {
            printLog("\(#function) | Timestamp is invalid | timeStamp is more then curretTimeStamp | curretTimestamp: \(vCurretTimeStamp) | timeStamp: \(timeStamp)")
            return false
        }
        return true
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
