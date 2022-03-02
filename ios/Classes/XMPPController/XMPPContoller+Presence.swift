//
//  XMPPContoller+Presence.swift
//  xmpp_plugin
//
//  Created by xRStudio on 20/01/22.
//

import Foundation
import XMPPFramework

//MARK: - XMPPPresence
extension XMPPController {
    
    func getPresenceOfUser(withJid jid : String, withStrem: XMPPStream, objXMPP : XMPPController) {
        /**
         https://stackoverflow.com/questions/56713245/xmpp-how-to-query-specific-rosters-presence
         
         https://stackoverflow.com/questions/4029924/xmpp-how-to-request-server-for-presence-status-of-a-users-contacts?rq=1
         
         
        */
        //let objPresence : XMPPPresence = XMPPPresence.init()
        //objPresence.
        let vJid : XMPPJID? = XMPPJID(string: getJIDNameForUser(jid.trim(), withStrem: withStrem))
        guard vJid != nil else {
            if let callBack = APP_DELEGATE.singalCallBack {
                callBack(xmppConstants.DataNil)
            }
            return
        }
        let obj = objXMPP.xmppRosterStorage?.user(for: vJid, xmppStream: withStrem, managedObjectContext: nil)
        printLog("obj: \(obj)")
    }
    
    //MARK: -
    func xmppStream(_ sender: XMPPStream, didSend presence: XMPPPresence) {
        printLog("\(#function) | XMPPPresence | presence: \(presence)")
    }
    
    func xmppStream(_ sender: XMPPStream, didFailToSend presence: XMPPPresence, error: Error) {
        printLog("\(#function) | XMPPPresence | presence: \(presence) | error: \(error)")
    }
    
    func xmppStream(_ sender: XMPPStream, didReceive presence: XMPPPresence) {
        printLog("\(#function) | XMPPPresence | presence: \(presence)")
        
        if presence.isErrorPresence {
            print("\(#function) | getting error Presence | presence: \(presence)")
           // let customElement : String = presence.gete(withKey: errorCustom.Key)
            let error = presence.getElements(withKey: "error").first?.getValue(withKey: "text") ?? ""
            print("error isErrorPresence \(error)")
            APP_DELEGATE.updateMUCJoinStatus(withRoomname: presence.fromStr ?? "", status: false, error : error ?? "")
            return
        }
        /**
         <presence xmlns="jabber:client" from="test@xrstudio.in/iOS" to="test@xrstudio.in/iOS" type="available"></presence>
         
         <presence xmlns="jabber:client" from="test1@xrstudio.in/iOS" to="test@xrstudio.in/iOS" type="available"><delay xmlns="urn:xmpp:delay" stamp="2022-01-20T09:10:51Z" from="test1@xrstudio.in/iOS"></delay></presence>
         */
        let vFrom : String = presence.fromStr ?? ""
        let vType : String = presence.type ?? ""
        var vMode : String = presence.show ?? ""
        if vMode.trim().isEmpty { vMode = vType }
        self.sendPresence(withJid: vFrom, type: vType, move: vMode)
    }
}
