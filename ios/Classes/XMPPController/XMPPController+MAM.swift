//
//  XMPPController+MAM.swift
//  xmpp_plugin
//
//  Created by xRStudio on 20/01/22.
//

import Foundation
import XMPPFramework

//MARK: - MAM
extension XMPPController {
    func getMAMMessage(withDMChatJid jid:String,
                       tsBefore : Int64,
                       tsSince : Int64,
                       limit : Int,
                       withStrem : XMPPStream,
                       objXMPP : XMPPController) {
        
        // If set value nil, system taken default value is - 'text-single'
        //let vType : String? = "text-single"
        let vType : String? = nil
        var fields: [XMLElement] = []
        var defaultLimit : Int = 50
        //1
        // Before
        if tsBefore > 0 {
            let date = Date(timeIntervalSince1970: Double(tsBefore)/1000.0)
            let xmppDateString = date.xmppDateTimeString
            
            let dateBefore = XMPPMessageArchiveManagement.field(withVar: "end",
                                                                type: vType,
                                                                andValue: xmppDateString)
            fields.append(dateBefore)
        }
        
        // Since
        if tsSince > 0 {
            let date = Date(timeIntervalSince1970: Double(tsSince)/1000.0)
            let xmppDateString = date.xmppDateTimeString
            
            let dateSince = XMPPMessageArchiveManagement.field(withVar: "start",
                                                               type: vType,
                                                               andValue: xmppDateString)
            fields.append(dateSince)
        }
        
        if(limit > 0) {
            defaultLimit = limit
        }
        
        var jidString : String = jid
        let isEmptyJid : Bool = jid.trim().isEmpty
        if !isEmptyJid {
            let isFullJid : Bool = (jid.components(separatedBy: "@").count == 2)
            if !isFullJid {
                jidString = getJIDNameForUser(jid, withStrem: withStrem)
            }
            let aJIDField = XMPPMessageArchiveManagement.field(withVar: "with",
                                                               type: nil,
                                                               andValue: jidString)
            fields.append(aJIDField)
        }
        printLog("\(#function) | req mam: since \(tsSince) | JIDString: \(jidString) | Limit \(defaultLimit)")
  
         let xmppRS : XMPPResultSet = XMPPResultSet(max: defaultLimit)
         objXMPP.xmppMAM?.retrieveMessageArchive (at: nil, withFields: fields, with:xmppRS)
       
    }
    
    func manageMAMMessage(message: XMPPMessage) {
        printLog("\(#function) | Manange MAMMessage | message: \(message)")
        
        let vMessType : String = (message.type ?? xmppChatType.NORMAL).trim()
        switch vMessType {
        case xmppChatType.CHAT, xmppChatType.GROUPCHAT:
            self.handel_ChatMessage(message, withType: vMessType, withStrem: self.xmppStream)
            
        default:
            break
        }
    }
    
    // MARK: - IQ
    func xmppStream(_ sender: XMPPStream, didSend iq: XMPPIQ) {
        printLog("\(#function) | XMPPStream: \(sender) | iq: \(iq)")
    }
    
    //MARK: -
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didReceiveFormFields iq: XMPPIQ) {
        printLog("\(#function) | xmppMAM | iq: \(String(describing: iq))")
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFailToReceiveFormFields iq: XMPPIQ) {
        printLog("\(#function) | xmppMAM | iq: \(String(describing: iq))")
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFailToReceiveMessages error: XMPPIQ?) {
        printLog("\(#function) | xmppMAM | error: \(String(describing: error))")
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didReceiveMAMMessage message: XMPPMessage) {
        guard let objMessMAM = message.mamResult?.forwardedMessage else {
            printLog("\(#function) | Not getting forwardedMessage in MAM | message: \(message)")
            return
        }
        self.manageMAMMessage(message: objMessMAM)
    }
    
    func xmppMessageArchiveManagement(_ xmppMessageArchiveManagement: XMPPMessageArchiveManagement, didFinishReceivingMessagesWith resultSet: XMPPResultSet) {
        /**
         result set logs | 06-Aug-2021 02:28 pm
         <set
         xmlns="http://jabber.org/protocol/rsm">
         <count>2</count>
         <first>1627725283801060</first>
         <last>1627725313877160</last>
         </set>
         */
        printLog("\(#function) | xmppMAM | resultSet: \(String(describing: resultSet))")
        
    }
}

