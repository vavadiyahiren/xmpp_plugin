//
//  XMPPSendMessage.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import XMPPFramework

extension XMPPController {
    /*func get_JidName_User(_ Jid : String) -> String {
        if Jid.trim().isEmpty { return Jid }
        if Jid.contains(self.hostName) == true { return Jid }
        let vChatRoomName : String = [Jid, "@", self.hostName].joined(separator: "")
        return vChatRoomName
    }*/
    func get_JidName_User(_ jid : String, withStrem: XMPPStream) -> String {
        var vHost : String = ""
        if let value = withStrem.hostName { vHost = value.trim() }
        if jid.contains(vHost) {
            return jid
        }
        return [jid, "@", vHost].joined(separator: "")
    }

    // This method handles sending the message to one-one chat
    func sendMessage(messageBody:String,
                     reciverJID:String,
                     messageId: String,
                     isGroup : Bool = false,
                     customElement : String,
                     withStrem : XMPPStream) {
        let vJid : XMPPJID? = XMPPJID(string: reciverJID)
        
        let vChatType : String = isGroup ? xmppChatType.GROUPCHAT : xmppChatType.CHAT
        
        let xmppMessage = XMPPMessage.init(type: vChatType.lowercased(), to: vJid)
        xmppMessage.addAttribute(withName: "xmlns", stringValue: "jabber:client")
        xmppMessage.addAttribute(withName: "id", stringValue: messageId)
        xmppMessage.addBody(messageBody)
        
        if let ele = self.getCustomELE(withElementName: customElement) {
            xmppMessage.addChild(ele)
        }
        xmppMessage.addReceiptRequest()
        withStrem.send(xmppMessage)
    }
    
    func sentMessageDeliveryReceipt(withReceiptId receiptId: String, jid : String, messageId : String, withStrem : XMPPStream) {
        if receiptId.trim().isEmpty {
            print("\(#function) | ReceiptId is empty/nil.")
            return
        }
        if jid.trim().isEmpty {
            print("\(#function) | jid is empty/nil.")
            return
        }
        if messageId.trim().isEmpty {
            print("\(#function) | MessageId is empty/nil.")
            return
        }
        
        let vJid : XMPPJID? = XMPPJID(string: get_JidName_User(jid, withStrem: withStrem))
        let xmppMessage = XMPPMessage.init(type: xmppChatType.NORMAL, to: vJid)
        xmppMessage.addAttribute(withName: "id", stringValue: receiptId)
        
        let eleReceived: XMLElement = XMLElement.init(name: "received", xmlns: "urn:xmpp:receipts")
        eleReceived.addAttribute(withName: "id", stringValue: messageId)
        xmppMessage.addChild(eleReceived)
        
        xmppMessage.addReceiptRequest()
        withStrem.send(xmppMessage)
    }

    //MARK: - Send Ack
    func sendAck(_ withMessageId : String) {
        let vMessId : String = withMessageId.trim()
        if vMessId.isEmpty {
            print("\(#function) | MessageId is empty/nil.")
            return
        }
        let vFrom : String = ""
        let vBody : String = ""
        let dicDate = ["type" : pluginMessType.ACK,
                       "id" : vMessId,
                       "from" : vFrom,
                       "body" : vBody,
                       "msgtype" : "normal"]
        printLog("\(#function) | data: \(dicDate)")
        if let obj = APP_DELEGATE.objEventData {
            obj(dicDate)
        }
    }
    
    func senAckDeliveryReceipt(withMessageId : String) {
        let vMessId = withMessageId.trim()
        let vFrom : String = ""
        let vBody : String = ""
        let dicDate = ["type" : pluginMessType.ACK_DELIVERY,
                       "id" : vMessId,
                       "from" : vFrom,
                       "body" : vBody,
                       "msgtype" : "normal"]
        print("\(#function) | data: \(dicDate)")
        
        if let obj = APP_DELEGATE.objEventData {
            obj(dicDate)
        }
    }
    
    func sendMemberList(withUsers arrUsers: [String]) {
        printLog("\(#function) | arrUsers: \(arrUsers)")
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(arrUsers)
        }
    }
    
    //MARK: -
    private func getCustomELE(withElementName name :String) -> XMLElement? {
        if name.trim().isEmpty {
            //print("\(#function) | custom element '\(name)' is empty/nil.")
            return nil
        }
        let ele: XMLElement = XMLElement.init(name: eleCustom.Name, xmlns: eleCustom.Namespace)
        ele.addChild(XMLElement.init(name: eleCustom.Kay, stringValue: name))
        return ele
    }
}
