//
//  AppConstants.swift
//  Runner
//
//  Created by iMac on 25/11/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import XMPPFramework

//let APP_DELEGATE = UIApplication.shared.delegate as! FlutterXmppPlugin
var APP_DELEGATE = FlutterXmppPlugin() as! FlutterXmppPlugin

public var xmpp_HostName: String = ""
public var xmpp_HostPort: Int16 = 0
public var xmpp_UserId: String = ""
public var xmpp_UserPass: String = ""
public var xmpp_Resource: String = ""
public var xmpp_RequireSSLConnection: Bool = false
public var xmpp_AutoDeliveryReceipt: Bool = false
public var xmpp_AutoReConnection: Bool = true
public var xmpp_UseStream: Bool = true

let default_isPersistent : Bool = false

//MARK:- Struct's
struct pluginMethod {
    static let login : String                       = "login"
    static let logout : String                      = "logout"
    static let sendMessage : String                 = "send_message"
    static let sendMessageInGroup : String          = "send_group_message"
    static let sendCustomMessage : String           = "send_custom_message"
    static let sendCustomMessageInGroup : String    = "send_customgroup_message"
    static let createMUC : String                   = "create_muc"
    static let joinMUCGroups : String               = "join_muc_groups"
    static let joinMUCGroup : String                = "join_muc_group"
    static let sendReceiptDelivery : String         = "send_delivery_receipt"
    static let addMembersInGroup : String           = "add_members_in_group"
    static let addAdminsInGroup : String            = "add_admins_in_group"
    static let addOwnersInGroup : String            = "add_owners_in_group"
    static let removeMembersInGroup : String        = "remove_members_from_group"
    static let removeAdminsInGroup : String         = "remove_admins_from_group"
    static let removeOwnersInGroup : String         = "remove_owners_from_group"
    static let getMembers : String                  = "get_members"
    static let getAdmins : String                   = "get_admins"
    static let getOwners : String                   = "get_owners"
    static let getLastSeen : String                 = "get_last_seen"
    static let createRosters : String               = "create_roster"
    static let getMyRosters : String                = "get_my_rosters"
    static let reqMAM : String                      = "request_mam"
    static let getPresence : String                 = "get_presence"
    static let changeTypingStatus : String          = "change_typing_status"
    static let changePresenceType : String          = "change_presence_type"
    static let getConnectionStatus : String         = "get_connection_status"
}

struct pluginMessType {
    static let Incoming : String = "incoming"
    static let Message : String = "Message"
    static let ACK : String = "Ack";
    static let ACK_DELIVERY : String = "Delivery-Ack";
    static let ACK_READ : String = "Read-Ack";
}

struct xmppChatType {
    static let GROUPCHAT : String = "groupchat"
    static let CHAT : String = "chat"
    static let NORMAL : String = "normal"
}
struct xmppConstants {
    static let Conference : String = "conference"
    
    static let ERROR : String = "ERROR"
    static let SUCCESS : String = "SUCCESS"
    
    static let Resource : String = "iOS"
    static let BODY : String = "body"
    static let ID : String = "id"
    static let TO : String = "to"
    static let FROM : String = "from"
    
    static let DataNil : String = "Data nil"
    
    static let errorMessOfMUC : String = "Owner privileges required"
    
    static let presence : String = "presence"
}
struct xmppConnStatus {
    static let Processing : String = "Processing"
    static let Authenticated : String = "Authenticated"
    static let Failed : String = "Failed"
    static let Disconnect : String = "Disconnected"
}
struct xmppMUCRole {
    /*
     https://github.com/robbiehanson/XMPPFramework/issues/521#issuecomment-155471382
     moderator
     participant
     visitor
     moderator
     participant
     visitor
     */
    static let Owner : String = "owner"
    static let Admin : String = "admin"
    static let Member : String = "member"
    static let None : String = "none"
}

struct xmppTypingStatus {
    static let Active : String = "active"
    static let Composing : String = "composing"
    static let Paused : String = "paused"
    static let Inactive : String = "inactive"
    static let Gone : String = "gone"
}

class groupInfo {
    var name : String = ""
    var isPersistent : Bool = default_isPersistent
    var objRoomXMPP : XMPPRoom?
    
    func `init`() {
    }
    func initWith(name: String, isPersistent: Bool) {
        self.name = name
        self.isPersistent = isPersistent
    }
    func initWith(name: String, isPersistent: Bool, objRoomXMPP : XMPPRoom?) {
        self.initWith(name: name, isPersistent: isPersistent)
        self.objRoomXMPP = objRoomXMPP
    }
}

class xmppLoggerInfo {
    var isLogEnable : Bool = false
    var logPath : String = ""
    
    func `init`() {
    }
}

struct eleTIME {
    /// Value - TIME
    static let Name : String = "TIME"
    /// Value - urn:xmpp:time
    static let Namespace : String = "urn:xmpp:time"
    /// Value - ts
    static let Kay : String = "ts"
}

struct eleCustom {
    /// Value - CUSTOM
    static let Name : String = "CUSTOM"
    /// Value - urn:xmpp:custom
    static let Namespace : String = "urn:xmpp:custom"
    /// Value - custom
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
enum xmppMUCUserType {
    case Owner
    case Admin
    case Member
}
enum xmppMUCUserActionType {
    case Add
    case Remove
}
enum Status {
    case Online
    case Offline
}
enum LogType : String {
    case none = "default"
    
    case receiveFromFlutter             = "methodReceiveFromFlutter" //----
    case receiveStanzaAckFromServer     = "receiveStanzaAckFromServer" //---
    case receiveMessageFromServer       = "receiveMessageFromServer" //---
    
    case sentMessageToFlutter           = "sentMessageToFlutter" //---
    case sentMessageToServer            = "sentMessageToServer" //--
    case sentCustomMessageToServer      = "sentCustomMessageToServer" //--
    case sentDeliveryReceiptToServer    = "sentDeliveryReceiptToServer" //--
}

//MARK:- Extension
extension Notification.Name {
    static let xmpp_ConnectionReq = Notification.Name(rawValue: "xmpp_ConnectionReq")
    static let xmpp_ConnectionStatus = Notification.Name(rawValue: "xmpp_ConnectionStatus")
}

extension String {
    var boolValue: Bool {
        return (self as NSString).boolValue
    }
    
    func trim() -> String {
        self.trimmingCharacters(in: .whitespaces)
    }
    
    var containsWhitespace : Bool {
        return(self.rangeOfCharacter(from: .whitespacesAndNewlines) != nil)
    }
}
