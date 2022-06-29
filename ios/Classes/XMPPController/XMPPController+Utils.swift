//
//  XMPPController+Utils.swift
//  xmpp_plugin
//
//  Created by xR Studio Mac on 29/06/22.
//

import Foundation
import XMPPFramework

func manage_MucSubMesage(_ message : XMPPMessage) -> XMPPMessage? {
    var newMessage: XMPPMessage?
    
    let arrMI = message.elements(forName: "event")
    if (arrMI.first != nil) {
        printLog("\(#function) | Mucsub Message")
        
        let mess1 =  message.element(forName: "event")?.element(forName: "items")?.element(forName: "item")?.element(forName: "message");
        printLog("\(#function) | didReceive MucSubMessage: \(String(describing: mess1))")
        
        guard let objMess = getXMPPMesage(usingXMPPMessageString: mess1?.xmlString ?? "") else { return newMessage }
        newMessage = objMess
        printLog("\(#function) | Getting Mucsub XMPPMessage: \(String(describing: newMessage))")
    }
    return newMessage
}

func getXMPPMesage(usingXMPPMessageString mess : String) -> XMPPMessage? {
    /*

    printLog("\(#function) | Muc sub Message")
    let mess1 =  message.element(forName: "event")?.element(forName: "items")?.element(forName: "item")?.element(forName: "message");


    printLog("\(#function) | didReceive message: \(mess1)")
    
    var elem: XMPPElement?
    
    do {
        try elem = XMPPElement.init(xmlString: mess1?.xmlString ??  "")
        newMessage = mess1?.forwardedMessage
    } catch {
        printLog("Couldn't parse the message ")
    }
    */
    
    printLog("\(#function) | Getting XMPPMessage String: \(mess)")
    if mess.trim().isEmpty {
        return nil
    }
    
    var xmppMess : XMPPMessage?
    do {
        try xmppMess = XMPPMessage.init(xmlString: mess.trim())
        printLog("\(#function) | Getting XMPPMessage Message: \(xmppMess?.body ?? "--Nil--")")
    }
    catch let error {
        printLog("\(#function) | Couldn't parse the message | Getting error: \(error.localizedDescription)")
    }
    return xmppMess
    
}
