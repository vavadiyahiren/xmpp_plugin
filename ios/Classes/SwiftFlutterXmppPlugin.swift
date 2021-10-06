import Flutter
import UIKit

public class SwiftFlutterXmppPlugin: NSObject, FlutterPlugin {
    
    static var  objEventChannel : FlutterEventChannel  =  FlutterEventChannel.init()
    var objEventData : FlutterEventSink?
    var objXMPP : XMPPController = XMPPController.sharedInstance
    var objXMPPConnStatus : xmppConnectionStatus = xmppConnectionStatus.None {
        didSet {
//            postNotification(Name: .xmpp_ConnectionStatus)
        }
    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_xmpp", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterXmppPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    //====> EVENT LISTNER
        objEventChannel = FlutterEventChannel(name: "flutter_xmpp/stream", binaryMessenger: registrar.messenger())
        objEventChannel.setStreamHandler(SwiftStreamHandler())
        
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
//    (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
    print("\(#function) | Method : \(call.method) | arguments: \(call.arguments.debugDescription)")
    print("call argument \(call.arguments as? [String : Any])")
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
            print("\(#function) | Data: \([vHost, vPort, vUserId, vPassword])")

            if APP_DELEGATE.objXMPP.isSendMessage() {
                result("SUCCESS")
                return
            }
            xmpp_HostName = vHost
            xmpp_HostPort = Int16(vPort) ?? 0
            xmpp_UserId = vUserId
            xmpp_UserPass = vPassword
            self.perform_connectToXMPP()

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
            let vType : String = "0" //(vData["conversation_type"] as? String ?? "").trim()
            let vBUBBLE : Int16 = vData["bubble_type"] as? Int16 ?? 1
            APP_DELEGATE.objXMPP.sendMessage(messageBody: body, reciverJID: toJid, messageId: id, MessageType: vType, vBUBBLE: vBUBBLE)
        } else {
            result("ERROR")
        }
        break

    case "send_group_message":
        /*
         methodName: send_group_message: params: {to_jid: ios1@conference.chat.enthuziastic.com, body: A, id: 1607083038903}
         application(_:didFinishLaunchingWithOptions:) | Method : send_group_message | arguments: Optional({
             body = A;
             id = 1607083038903;
             "to_jid" = "ios1@conference.chat.enthuziastic.com";
         })
         */
        if let vData = call.arguments as? [String : Any] {
            let toJid : String = (vData["to_jid"] as? String ?? "").trim()
            let body : String = vData["body"] as? String ?? ""
            let id : String = (vData["id"] as? String ?? "").trim()
            let vType : String = "1" //(vData["conversation_type"] as? String ?? "").trim()
            let vBUBBLE : Int16 = vData["bubble_type"] as? Int16 ?? 1
            APP_DELEGATE.objXMPP.sendMessage(messageBody: body, reciverJID: toJid, messageId: id, MessageType: vType, vBUBBLE: vBUBBLE)
        } else {
            result("ERROR")
        }
        break
        
    case "join_muc_groups":
        /*
         arguments: Optional({
             "all_groups_ids" =     (
                 "ios1@conference.chat.enthuziastic.com"
             );
         })
         */
        if let vData = call.arguments as? [String : Any] {
            //var vRoom = vData["all_groups_ids"] as? String ?? ""
            //vRoom = vRoom.replacingOccurrences(of: "[", with: "")
            //vRoom = vRoom.replacingOccurrences(of: "]", with: "")
            //APP_DELEGATE.objXMPP.joinRoom(roomName: vRoom, time: 0)
                                
            let arrRooms = vData["all_groups_ids"] as? [String] ?? []
            for vRoom  in arrRooms {
                //APP_DELEGATE.objXMPP.joinRoom(roomName: vRoom, time: 0)
                APP_DELEGATE.objXMPP.createRoom(roomName: vRoom)
            }
        } else {
            result("ERROR")
        }
        break
        
    default:
        break
    }
    result("iOS " + UIDevice.current.systemVersion)
  }
    
    func perform_connectToXMPP() {
            print("\(#function) | perform xmpp Connection")
            
            switch APP_DELEGATE.objXMPPConnStatus {
            case .None,
                 .Failed:
                APP_DELEGATE.objXMPPConnStatus = .Processing
                do {
                    try self.objXMPP = XMPPController.init(hostName: xmpp_HostName, hostPort: xmpp_HostPort, userId: xmpp_UserId, password: xmpp_UserPass)
                    self.objXMPP.xmppStream.addDelegate(self, delegateQueue: DispatchQueue.main)
                    self.objXMPP.connect()
                } catch {
                    APP_DELEGATE.perform_connectToXMPP()
                }
                break
                
            case .Processing:
                break
                
            case .Disconnect:
                APP_DELEGATE.objXMPPConnStatus = .None
                APP_DELEGATE.perform_connectToXMPP()
                break
                
            default:
                break
            }
        }
    
    func manange_NotifcationObservers()  {
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(self, selector: #selector(notiObs_LoginReq(notfication:)), name: .xmpp_ConnectionReq, object: nil)
            notificationCenter.addObserver(self, selector: #selector(notiObs_XMPPConnectionStatus(notfication:)), name: .xmpp_ConnectionStatus, object: nil)
        }
        
        @objc func notiObs_LoginReq(notfication: NSNotification) {
            if let vData = notfication.object {
                print("notfication data : \(vData)")
            }
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
                //APP_DELEGATE.objXMPP.sendMessage(messageBody: "Hello12", reciverJID: "919484634752")
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
                print("Nil data of APP_DELEGATE.objEventData", dicDate)
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
