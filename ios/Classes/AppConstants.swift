//
//  AppConstants.swift
//  Runner
//
//  Created by iMac on 25/11/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation

//let APP_DELEGATE = UIApplication.shared.delegate as! FlutterXmppPlugin
var APP_DELEGATE = FlutterXmppPlugin() as! FlutterXmppPlugin

public var xmpp_HostName: String = ""
public var xmpp_HostPort: Int16 = 0
public var xmpp_UserId: String = ""
public var xmpp_UserPass: String = ""
 
let default_isPersistent : Bool = false

//MARK:- Struct's
struct pluginMethod {
    static let login : String                       = "login"
    static let sendMessage : String                 = "send_message"
    static let sendMessageInGroup : String          = "send_group_message"
    static let sendCustomMessage : String           = "send_custom_message"
    static let sendCustomMessageInGroup : String    = "send_customgroup_message"
    static let createMUC : String                   = "create_muc"
    static let joinMUC : String                     = "join_muc_groups"
    static let sendReceiptDelivery : String         = "send_delivery_receipt"
}

struct xmppChatType {
    static let GROUPCHAT : String = "groupchat"
    static let CHAT : String = "chat"
    static let NORMAL : String = "normal"
}
struct xmppConstants {
    static let ERROR : String = "ERROR"
    static let SUCCESS : String = "SUCCESS"
    
    static let Resource : String = "iOS"
    static let BODY : String = "body"
    static let ID : String = "id"
    static let TO : String = "to"
    static let FROM : String = "from"
    
    static let ACK : String = "Ack";
    static let ACK_DELIVERY : String = "Delivery-Ack";
    static let ACK_READ : String = "Read-Ack";
}

struct groupInfo {
    var name : String = ""
    var isPersistent : Bool = default_isPersistent
}

struct eleCustom {
    static let Name : String = "CUSTOM"
    static let Namespace : String = "urn:xmpp:custom"
    static let Kay : String = "custom"
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

//MARK:- Extension
extension String {
    var boolValue: Bool {
        return (self as NSString).boolValue
    }
    
    func trim() -> String {
        self.trimmingCharacters(in: .whitespaces)
    }
}

func printLog(_ message : String) {
    print(message)
}
