//
//  XMPPController+Roster.swift
//  xmpp_plugin
//
//  Created by xRStudio on 20/01/22.
//

import Foundation
import XMPPFramework

//MARK: - XMPPRoster
extension XMPPController : XMPPRosterDelegate {
    func createRosters(withUserJid jid: String, withStrem: XMPPStream, objXMPP : XMPPController) {
        printLog("\(#function) | withUserJid: \(jid)")
        if jid.trim().isEmpty {
            print("\(#function) | getting userJid is emtpy.")
            return
        }
        let vJid : XMPPJID? = XMPPJID(string: getJIDNameForUser(jid.trim(), withStrem: withStrem))
        if let vJid = vJid {
            objXMPP.xmppRoster?.subscribePresence(toUser: vJid)
            return
        }
        print("\(#function) | Getting Invalid Jid, not created Roster | userJid : \(jid)")
    }
    
    func getMyRosters(withStrem: XMPPStream, objXMPP : XMPPController) {
        var arrJidString : [String] = []
        guard let arrJid = objXMPP.xmppRosterStorage?.jids(for: withStrem) else {
            printLog("\(#function) | Not getting roster.")
            
            self.sendRosters(withUsersJid: arrJidString)
            return
        }
        
        for jid in arrJid {
            let strJid = jid.description.trim()
            if strJid.isEmpty { continue }
            arrJidString.append(strJid)
        }
        self.sendRosters(withUsersJid: arrJidString)
    }
    
    //MARK: -
    func xmppRoster(_ sender: XMPPRoster, didReceivePresenceSubscriptionRequest presence: XMPPPresence) {
        printLog("\(#function) | presence : \(presence)")
    }
    
    func xmppRoster(_ sender: XMPPRoster, didReceiveRosterPush iq: XMPPIQ) {
        printLog("\(#function) | iq : \(iq)")
    }
    
    func xmppRosterDidBeginPopulating(_ sender: XMPPRoster, withVersion version: String) {
        printLog("\(#function) | version : \(version)")
    }
    
    func xmppRosterDidEndPopulating(_ sender: XMPPRoster) {
        printLog("\(#function) | sender: \(sender)")
    }
    
   
    
}
