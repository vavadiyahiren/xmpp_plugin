//
//  XMPPSendMessage.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import XMPPFramework

extension XMPPController {
    /// This method handles sending the message to one-one chat
    func sendMessage(messageBody:String,
                     time:String,
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
        
        /// Time
        if let eleTime = self.getTimeElement(withTime: time) {
            xmppMessage.addChild(eleTime)
        }
        /// Custom Element
        var isCustom : Bool = false
        if let ele = self.getCustomELE(withElementName: customElement) {
            xmppMessage.addChild(ele)
            isCustom = true
        }
        
        if xmpp_AutoDeliveryReceipt {
            xmppMessage.addReceiptRequest()
        }
        withStrem.send(xmppMessage)
        
        addLogger(isCustom ? .sentCustomMessageToServer : .sentMessageToServer, xmppMessage)
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
        
        let vJid : XMPPJID? = XMPPJID(string: getJIDNameForUser(jid, withStrem: withStrem))
        let xmppMessage = XMPPMessage.init(type: xmppChatType.NORMAL, to: vJid)
        xmppMessage.addAttribute(withName: "id", stringValue: receiptId)
        
        let eleReceived: XMLElement = XMLElement.init(name: "received", xmlns: "urn:xmpp:receipts")
        eleReceived.addAttribute(withName: "id", stringValue: messageId)
        xmppMessage.addChild(eleReceived)
        
        xmppMessage.addReceiptRequest()
        withStrem.send(xmppMessage)
        
        addLogger(.sentDeliveryReceiptToServer, xmppMessage)
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
        addLogger(.sentMessageToFlutter, dicDate)
        
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
        printLog("\(#function) | data: \(dicDate)")
        addLogger(.sentMessageToFlutter, dicDate)
        
        if let obj = APP_DELEGATE.objEventData {
            obj(dicDate)
        }
    }
    
    func sendMemberList(withUsers arrUsers: [String]) {
        printLog("\(#function) | arrUsers: \(arrUsers)")
        addLogger(.sentMessageToFlutter, arrUsers)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(arrUsers)
        }
    }
    
    func sendRosters(withUsersJid arrJid : [String]) {
        printLog("\(#function) | arrJid: \(arrJid)")
        addLogger(.sentMessageToFlutter, arrJid)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(arrJid)
        }
    }
    
    func sendLastActivity(withTime vTime: String) {
        printLog("\(#function) | time: \(vTime)")
        addLogger(.sentMessageToFlutter, vTime)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(vTime)
        }
    }
    
    func sendMUCJoinStatus(_ isSuccess: Bool) {
        printLog("\(#function) | isSuccess: \(isSuccess)")
        addLogger(.sentMessageToFlutter, isSuccess)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(isSuccess)
        }
    }
    
    func sendMUCCreateStatus(_ isSuccess: Bool) {
        printLog("\(#function) | isSuccess: \(isSuccess)")
        addLogger(.sentMessageToFlutter, isSuccess)
        
        if let callBack = APP_DELEGATE.singalCallBack {
            callBack(isSuccess)
        }
    }
    
    //MARK: -
    private func getTimeElement(withTime time :String) -> XMLElement? {
        let ele: XMLElement = XMLElement.init(name: eleTIME.Name, xmlns: eleTIME.Namespace)
        ele.addChild(XMLElement.init(name: eleTIME.Kay, stringValue: time))
        return ele
    }
    
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
