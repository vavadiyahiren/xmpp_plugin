//
//  XMPPReceiveMessage.swift
//  flutter_xmpp
//
//  Created by xRStudio on 17/08/21.
//

import Foundation
import Foundation
import XMPPFramework

extension XMPPController {
    
    func handel_GroupMessage(_ message: XMPPMessage) {
        if APP_DELEGATE.objEventData == nil {
            print("\(#function) | Nil data of APP_DELEGATE.objEventData")
            return
        }
        
        /*
         //----------------------------------------------------
         //Message - Group
         <message xmlns="jabber:client" lang="en" to="testios@chat.enthuziastic.com/iOS" from="testgroup1@conference.chat.enthuziastic.com/testios" type="groupchat" id="1607082016613">
         <BUBBLE xmlns="urn:xmpp:bubble"> <Bubble>1</Bubble> </BUBBLE>
         <TIME xmlns="urn:xmpp:time"> <Time>1607082025520</Time> </TIME>
         <request xmlns="urn:xmpp:receipts"> </request>
         <body>test 1607082016613</body>
         </message>
         */
        var objMess : Message = Message.init()
        objMess.initWithMessage(message: message)
        let vId : String = objMess.id.trim()
        if vId.count == 0 {
            print("\(#function) | Message Id nil")
            return
        }
        
        var vMessType : String = "groupchat"
        //TODO: Send Own Message Receipt
        if self.userId == objMess.senderJid {
            vMessType = "normal"
        }
        
        
        // flutter receive:
        // {from: testgroup1@conference.chat.enthuziastic.com, id: 1607079137493, type: incoming, body: Fri, msgtype: groupchat}
        var vFrom : String = objMess.jid //objMess.senderJid
        vFrom += "@conference." + self.hostName
        let dicDate = ["type" : "incoming",
                       "id" : objMess.id,
                       "from" : vFrom,
                       "body" : objMess.message,
                       "msgtype" : vMessType]
        print("\(#function) | dicDate: \(dicDate)")
        APP_DELEGATE.objEventData!(dicDate)
        
    }
    
    func handel_ChatMessage(_ message: XMPPMessage) {
        if APP_DELEGATE.objEventData == nil {
            print("\(#function) | Nil data of APP_DELEGATE.objEventData")
            return
        }
        
        
        //TODO: Message Received
        /*
         //----------------------------------------------------
         <message
         xmlns="jabber:client" lang="en" to="919876543210@chat.enthuziastic.com/iOS" from="testios@chat.enthuziastic.com/iOS" type="chat">
         <received xmlns="urn:xmpp:receipts" id="1606971792978"> </received>
         </message>
         */
        //if message.hasReceiptRequest {
        let eleReceived = message.elements(forName: eleRECEIVED.ELEMENT)
        if eleReceived.count != 0 {
        
            let dicEle : [String : Any] = eleReceived.first?.attributesAsDictionary() ?? [:]
            let vMessId : String = dicEle["id"] as? String ?? ""
            let vBUUBLE : Int16 = dicEle["bubbleType"] as? Int16 ?? 1
            if vMessId.count == 0 { return }
            
            var objMess : Message = Message.init()
            objMess.initWithMessage(message: message)
            
            let vFrom : String = objMess.senderJid
            let vBody : String = ""
            let dicDate = ["type" : "incoming",
                           "id" : vMessId,
                           "from" : vFrom,
                           "body" : vBody,
                           "bubbleType":vBUUBLE,
                           "msgtype" : "normal"] as [String : Any]
            print("\(#function) | dicDate: \(dicDate)")
            APP_DELEGATE.objEventData!(dicDate)
            return
        }
                
        //TODO: Message - Singal
        /*
         //----------------------------------------------------
         //Message - Chat
         <message
         xmlns=“jabber:client” to=“918866997467@test.chat.fish” id=“1606456491165” type=“chat” from=“919904763022@test.chat.fish/Android”>
         <body>કેટ કેટલી હદ વટાવી ગઈ અને મને કેતુ</body>
         <TIME xmlns=“urn:xmpp:time”> <Time>1606456491294</Time> </TIME>
         <BUBBLE xmlns=“urn:xmpp:bubble”> <Bubble>1</Bubble> </BUBBLE>
         <request xmlns=“urn:xmpp:receipts”> </request>
         </message>
         */
        var objMess : Message = Message.init()
        objMess.initWithMessage(message: message)
        let vId : String = objMess.id.trim()
        if vId.count == 0 {
            print("\(#function) | Message Id nil")
            return
        }
        
        let vMessType : String = "chat"
        let dicDate = ["type" : "incoming",
                       "id" : objMess.id,
                       "from" : objMess.senderJid,
                       "body" : objMess.message,
                       "msgtype" : vMessType,
                       "bubbleType" : "\(objMess.bubbleType)",
                       "senderJid": objMess.senderJid
        ] as [String : Any]
        print("\(#function) | dicDate: \(dicDate)")
        APP_DELEGATE.objEventData!(dicDate)
    }
}
