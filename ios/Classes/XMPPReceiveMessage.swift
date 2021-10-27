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
    
    func handel_ChatMessage(_ message: XMPPMessage) {
        if APP_DELEGATE.objEventData == nil {
            print("\(#function) | Nil data of APP_DELEGATE.objEventData")
            return
        }
        
        //TODO: Message - Singal
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
                       "senderJid": objMess.senderJid] as [String : Any]
        APP_DELEGATE.objEventData!(dicDate)
    }
}
