//
//  XMPPSendMessage.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import XMPPFramework

extension XMPPController {
    func get_JidName_User(_ Jid : String) -> String {
        if Jid.count == 0 { return Jid }
        if Jid.contains(self.hostName) == true { return Jid }
        let vChatRoomName : String = [Jid, "@", self.hostName].joined(separator: "")
        return vChatRoomName
    }
    
    // This method handles sending the message to one-one chat
    func sendMessage(messageBody:String, reciverJID:String, messageId: String, isGroup : Bool = false, withStrem : XMPPStream) {
        let vJid : XMPPJID? = XMPPJID(string: reciverJID)
        
        let vChatType : String = isGroup ? "groupchat" : "chat"
        
        let xmppMessage = XMPPMessage.init(type: vChatType, to: vJid)
        xmppMessage.addAttribute(withName: "xmlns", stringValue: "jabber:client")
        xmppMessage.addAttribute(withName: "id", stringValue: messageId)
        xmppMessage.addBody(messageBody)
        xmppMessage.addReceiptRequest()
        withStrem.send(xmppMessage)
    }
}
