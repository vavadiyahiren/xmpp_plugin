//
//  XMPPController+LastActivity.swift
//  xmpp_plugin
//
//  Created by xRStudio on 20/01/22.
//

import Foundation
import XMPPFramework

extension XMPPController : XMPPLastActivityDelegate {
    
    
    //MARK: -
    func numberOfIdleTimeSeconds(for sender: XMPPLastActivity!, queryIQ iq: XMPPIQ!, currentIdleTimeSeconds idleSeconds: UInt) -> UInt {
        printLog("\(#function) | response : \(String(describing: iq)) | idleSeconds : \(idleSeconds)")
        return 0
    }
    
    func xmppLastActivity(_ sender: XMPPLastActivity!, didReceiveResponse response: XMPPIQ!) {

        printLog("\(#function) | response : \(String(describing: response))")
        var vTimeInSec : String = "-1"
        let isErrorResponse : Bool = response.isErrorIQ
        if isErrorResponse {
            print("\(#function) | Getting error in XMPPLastActivity IQ | response: \(String(describing: response))")
            
            self.sendLastActivity(withTime: vTimeInSec)
            return
        }
        
        guard let eleQuery = response.children?.first else {
            print("\(#function) | Not getting Valid XMPPLastActivity IQ-Query | response-iq: \(String(describing: response))")
            
            self.sendLastActivity(withTime: vTimeInSec)
            return
        }
        guard let ele = eleQuery as? DDXMLElement else {
            print("\(#function) | Not getting Valid IQ-Query | elementQuery: \(eleQuery)")
            
            self.sendLastActivity(withTime: vTimeInSec)
            return
        }
        if let value = ele.attribute(forName: "seconds")?.stringValue {
            vTimeInSec = value.trim()
        }
        self.sendLastActivity(withTime: vTimeInSec)
    }
    
    func xmppLastActivity(_ sender: XMPPLastActivity!, didNotReceiveResponse queryID: String!, dueToTimeout timeout: TimeInterval) {
        printLog("\(#function) | queryID : \(String(describing: queryID)) | timeout : \(timeout)")
        self.sendLastActivity(withTime: "-1")
    }
    
    //MARK: -
    func getLastActivity(withUserJid jid: String, withStrem: XMPPStream, objXMPP : XMPPController) {
        printLog("\(#function) | withUserJid : \(jid)")
        guard let vJid = XMPPJID(string: getJIDNameForUser(jid.trim(), withStrem: withStrem)) else {
            print("\(#function) | Getting invalid UserJid : \(jid)")
            return
        }
        objXMPP.xmppLastActivity.sendQuery(to: vJid)
    }
}
