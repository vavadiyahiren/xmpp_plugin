//
//  Message.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import XMPPFramework

struct Message {
    var id: String = ""
    var jid: String = ""
    var message : String = ""
    var senderJid : String = ""
    
    //MARK:-
    private struct keys {
        static let id = "id"
        static let jid = "jid"
        static let message = "message"
        static let senderJid = "senderJid"
    }
    
    //MARK:-
    public init() {
        //super.init()
    }
    
    public init(data: [String: Any]) {
        self.id = data[keys.id] as? String ?? ""
        self.jid = data[keys.jid] as? String ?? ""
        self.message = data[keys.message] as? String ?? ""
        self.senderJid = data[keys.senderJid] as? String ?? ""
    }
    
    public func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict[keys.id] = id
        dict[keys.jid] = jid
        dict[keys.message] = message
        dict[keys.senderJid] = senderJid
        return dict
    }
    
    //MARK:-
    public mutating func initWithMessage(message : XMPPMessage)  {
        self.setSenderReciver(message: message)
        self.setText(message: message)
    }
    
    private mutating func setSenderReciver(message: XMPPMessage) {
        let vMessage_ID : String = (message.elementID ?? "").trim()
        var vSender_ID : String = ""
        var vJID : String = ""
        
        let vMessType : String = message.type ?? ""
        switch vMessType {
        case xmppChatType.GROUPCHAT:
            vSender_ID = (message.fromStr ?? "").trim()
            vJID = (message.toStr ?? "").trim()
        case xmppChatType.CHAT:
            vSender_ID = (message.fromStr ?? "").trim()
            vJID = (message.toStr ?? "").trim()
        default:
            vSender_ID = ""
        }
        
        self.id = vMessage_ID
        self.jid = vJID
        self.senderJid = vSender_ID
    }
    
    private mutating func setText(message: XMPPMessage) {
        let vMess_Body : String = (message.elements(forName: xmppConstants.BODY.lowercased()).first?.children?.first?.stringValue ?? "").trim()
        self.message = vMess_Body
    }
}



