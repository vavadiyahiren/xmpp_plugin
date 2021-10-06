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
    
    func getStanza_BubbleType(_ BubbleType : String) -> XMLElement {
        let elements_BUBBLE: XMLElement = XMLElement.init(name: eleBUBBLE.ELEMENT, xmlns: eleBUBBLE.NAMESPACE)
        elements_BUBBLE.addChild(XMLElement.init(name: eleBUBBLE.Bubble, stringValue: BubbleType))
        return elements_BUBBLE
    }
    
    func getStanza_Time(_ Time : String) -> XMLElement {
        let elements_TIME: XMLElement = XMLElement.init(name: eleTIME.ELEMENT, xmlns: eleTIME.NAMESPACE)
        elements_TIME.addChild(XMLElement.init(name: eleTIME.Time, stringValue: Time))
        return elements_TIME
    }
    
    //MARK:- Send Message (Singal)
    func sendMessage( messageBody:String, reciverJID:String, messageId: String, MessageType : String, vBUBBLE : Int16) {
        let vTIME : String = getTimeStamp().description
        let vJid : XMPPJID? = XMPPJID(string: reciverJID)
        
        var vChatType : String = ""
        switch MessageType.trim() {
        case "1":
            vChatType = xmppChatType.GROUPCHAT
            break
            
        case "0":
            vChatType = xmppChatType.CHAT
            break
            
        default:
            break
        }
        
        self.xmppMessage = XMPPMessage.init(type: vChatType, to: vJid)
        self.xmppMessage.addBody(messageBody)
        self.xmppMessage.addAttribute(withName: xmppConstants.ID, stringValue: messageId)
        
        //BUBBLE
        self.xmppMessage.addChild(self.getStanza_BubbleType(vBUBBLE.description))
        
        //TIME
        self.xmppMessage.addChild(self.getStanza_Time(vTIME))
        
        self.xmppMessage.addReceiptRequest()
        
        self.xmppStream.send(self.xmppMessage)
    }
}

//MARK:- Struct's
struct eleBUBBLE {
    static let ELEMENT : String = "BUBBLE"
    static let NAMESPACE : String = "urn:xmpp:bubble"
    static let Bubble : String = "Bubble"
}
struct eleTIME {
    static let ELEMENT : String = "TIME"
    static let NAMESPACE : String = "urn:xmpp:time"
    static let Time : String = "Time"
}
