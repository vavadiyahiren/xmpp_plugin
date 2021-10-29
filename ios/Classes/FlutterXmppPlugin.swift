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
        case "login":
            if let vData = call.arguments as? [String : Any] {
                let vHost : String = (vData["host"] as? String ?? "").trim()
                let vPort : String = vData["port"] as? String ?? "0"
                var vUserId : String = (vData["user_jid"] as? String ?? "").trim()
                vUserId = (vUserId.components(separatedBy: "@").first ?? "").trim()
                let vPassword : String = (vData["password"] as? String ?? "").trim()
                
                if [vHost.count, vUserId.count, vPassword.count].contains(0) {
                    result("Data nil")
                    return
                }
                if APP_DELEGATE.objXMPP.isSendMessage() {
                    result("SUCCESS")
                    return
                }
                xmpp_HostName = vHost
                xmpp_HostPort = Int16(vPort) ?? 0
                xmpp_UserId = vUserId
                xmpp_UserPass = vPassword
                
                // TODO : Rename name
                self.performXMPPConnectionActivity()
                
                result("SUCCESS")
            } else {
                result("Data nil");
            }
            break
            
        case "send_message":
            if let vData = call.arguments as? [String : Any] {
                let toJid : String = (vData["to_jid"] as? String ?? "").trim()
                let body : String = vData["body"] as? String ?? ""
                let id : String = (vData["id"] as? String ?? "").trim()
                self.objXMPP.sendMessage(messageBody: body,
                                                 reciverJID: toJid,
                                                 messageId: id,
                                                 isGroup: false,
                                                 withStrem: self.objXMPP.xmppStream)
                result("SUCCESS")
            } else {
                result("ERROR")
            }
            break
            
        case "send_group_message":
            if let vData = call.arguments as? [String : Any] {
                let toJid : String = (vData["to_jid"] as? String ?? "").trim()
                let body : String = vData["body"] as? String ?? ""
                let id : String = (vData["id"] as? String ?? "").trim()
                self.objXMPP.sendMessage(messageBody: body,
                                                 reciverJID: toJid,
                                                 messageId: id,
                                                 isGroup: true,
                                                 withStrem: self.objXMPP.xmppStream)
                result("SUCCESS")
            } else {
                result("ERROR")
            }
            break
            
        case "join_muc_groups":
            if let vData = call.arguments as? [String : Any] {
                let arrRooms = vData["all_groups_ids"] as? [String] ?? []
                for vRoom  in arrRooms {

                    let arrRoomCompo : [String] = vRoom.components(separatedBy: ",")
                    let vRoomName : String = arrRoomCompo.first ?? ""
                    let vRoomTS : String = arrRoomCompo.last ?? "0"
                    if vRoomName.isEmpty { continue }
                    let vRoomTSLongFormat : Int64 = Int64(vRoomTS) ?? 0
                    
                    //APP_DELEGATE.objXMPP.createRoom(roomName: vRoom, withXMPP: self.objXMPP, withStrem: self.objXMPP.xmppStream)
                    APP_DELEGATE.objXMPP.joinRoom(roomName: vRoomName, time: vRoomTSLongFormat, withStrem: self.objXMPP.xmppStream)

                }
                result("SUCCESS")
            } else {
                result("ERROR")
            }
            break
            
        default:
            break
        }
        result("iOS " + UIDevice.current.systemVersion)
    }
    
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
        var dicDate : [String : Any] = [:]
        switch objXMPPConnStatus {
        case .Processing:
            dicDate["type"] = "incoming"
            dicDate["msgtype"] = "Processing"
            break
            
        case .Sucess:
            dicDate["type"] = "incoming"
            dicDate["msgtype"] = "Authenticated"
            break
            
        case .Failed:
            dicDate["type"] = "incoming"
            dicDate["msgtype"] = "Failed"
            break
            
        case .Disconnect,
             .None:
            dicDate["type"] = "incoming"
            dicDate["msgtype"] = "Disconnect"
            break
        }
        
        //TODO: Send data back to flutter event handler.
        if APP_DELEGATE.objEventData != nil {
            APP_DELEGATE.objEventData!(dicDate)
        } else {
            print("\(#function) | Nil data of APP_DELEGATE.objEventData", dicDate)
        }
    }
    
}


extension Notification.Name {
    static let xmpp_ConnectionReq = Notification.Name(rawValue: "xmpp_ConnectionReq")
    static let xmpp_ConnectionStatus = Notification.Name(rawValue: "xmpp_ConnectionStatus")
}

//MARK:- Notifcation Observers
public func postNotification(Name:Notification.Name, withObject: Any? = nil, userInfo:[AnyHashable : Any]? = nil){
    NotificationCenter.default.post(name: Name, object: withObject, userInfo: userInfo)
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
