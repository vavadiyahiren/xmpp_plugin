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
    var bubbleType: Int16 = 0
    var messageDirection: Int16 = 0
    var conversationType: Int16 = 0
    
    var jid: String = ""
    var message : String = ""
    var senderJid : String = ""
    var sortingTime : Int64 = 0 // Set received message current time set
    var displayTime : Int64 = 0 // Set time in TIME Elements in recieved message.
    
    //MARK:-
    private struct keys {
        static let id = "id"
        static let bubbleType = "bubbleType"
        static let messageDirection = "messageDirection"
        static let conversationType = "conversationType"
        static let jid = "jid"
        static let message = "message"
        static let senderJid = "senderJid"
        static let sortingTime = "sortingTime"
        static let displayTime = "displayTime"
    }
    
    //MARK:-
    public init() {
        //super.init()
    }
    
    public init(data: [String: Any]) {
        self.id = data[keys.id] as? String ?? ""
        self.bubbleType = data[keys.bubbleType] as? Int16 ?? 0
        self.messageDirection = data[keys.messageDirection] as? Int16 ?? 0
        self.bubbleType = data[keys.conversationType] as? Int16 ?? 0
        
        self.jid = data[keys.jid] as? String ?? ""
        self.message = data[keys.message] as? String ?? ""
        self.senderJid = data[keys.senderJid] as? String ?? ""
        self.sortingTime = data[keys.sortingTime] as? Int64 ?? 0
        self.displayTime = data[keys.displayTime] as? Int64 ?? 0
    }
    
    public func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict[keys.id] = id
        dict[keys.bubbleType] = bubbleType
        dict[keys.messageDirection] = messageDirection
        dict[keys.conversationType] = bubbleType
        
        dict[keys.jid] = jid
        dict[keys.message] = message
        dict[keys.senderJid] = senderJid
        dict[keys.sortingTime] = sortingTime
        dict[keys.displayTime] = displayTime
        
        return dict
    }
    
    //MARK:-
    public mutating func initWithMessage(message : XMPPMessage)  {
        let vMessType : String = message.getMessageType() ?? ""
        if vMessType == xmppChatType.GROUPCHAT {
            self.conversationType = CONVERSATION_TYPE.CHANNEL
        }
        if vMessType == xmppChatType.CHAT {
            self.conversationType = CONVERSATION_TYPE.NORMAL
        }
        
        let vBubbleType : String = (message.elements(forName: eleBUBBLE.ELEMENT).first?.children?.first?.stringValue ?? "").trim()
        if let value = Int16(vBubbleType) {
            self.bubbleType = value
        }
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
            vSender_ID = (message.from?.resource ?? "").trim()
            vJID = ((message.from?.bare ?? "").components(separatedBy: "@").first ?? "").trim()
        case xmppChatType.CHAT:
            vSender_ID = (message.from?.user ?? "").trim()
            vJID = ((message.to?.bare ?? "").components(separatedBy: "@").first ?? "").trim()
        default:
            vSender_ID = ""
        }
        
        let vMess_Time : String = (message.elements(forName: eleTIME.ELEMENT).first?.children?.first?.stringValue ?? "").trim()
        
        /*
        //MessageID
        if vMessage_ID.count == 0 {
            print("Message_ID not getting.")
            return
        }
        //ChatRoomName
        if vJID.count == 0 {
            print("Chat JID not getting.")
            return
        }
        //SenderID
        if vSender_ID.count == 0 {
            print("SenderID not getting")
            return
        }*/
        
        self.id = vMessage_ID
        self.jid = vJID
        self.senderJid = vSender_ID
        self.displayTime = Int64(vMess_Time) ?? 0
        self.sortingTime = getTimeStamp()
        
        //Message Direction
        let vUser_ID : String = xmpp_UserId.trim()
        var vBubbleDirection : Int16 = 0
        if vSender_ID == vUser_ID {
            vBubbleDirection = MESSAGE_OUT
        } else {
            vBubbleDirection = MESSAGE_IN
        }
        self.messageDirection = vBubbleDirection
    }
    
    private mutating func setText(message: XMPPMessage) {
        let vMess_Body : String = (message.elements(forName: xmppConstants.BODY.lowercased()).first?.children?.first?.stringValue ?? "").trim()
        self.message = vMess_Body
    }
}



