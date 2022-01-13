package org.xrstudio.xmpp.flutter_xmpp.managers;

import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.tcp.XMPPTCPConnection;
import org.jivesoftware.smackx.mam.MamManager;
import org.jxmpp.jid.Jid;
import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnection;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

import java.util.Date;
import java.util.List;

public class MAMManager {


    public static void requestMAM(String userJid, String requestBefore, String requestSince, String limit) {

        XMPPTCPConnection connection = FlutterXmppConnection.getConnection();

        if (connection.isAuthenticated()) {

            try {

                MamManager mamManager = MamManager.getInstanceFor(connection);
                MamManager.MamQueryArgs.Builder queryArgs = MamManager.MamQueryArgs.builder();

                if (requestBefore != null && !requestBefore.isEmpty()) {
                    long requestBeforets = Long.parseLong(requestBefore);
                    if (requestBeforets > 0)
                        queryArgs.limitResultsBefore(new Date(requestBeforets));
                }
                if (requestSince != null && !requestSince.isEmpty()) {
                    long requestAfterts = Long.parseLong(requestSince);
                    if (requestAfterts > 0)
                        queryArgs.limitResultsSince(new Date(requestAfterts));
                }
                if (limit != null && !limit.isEmpty()) {

                    int limitMessage = Integer.parseInt(limit);
                    if (limitMessage > 0) {
                        queryArgs.setResultPageSizeTo(limitMessage);
                    } else {
                        queryArgs.setResultPageSizeTo(Integer.MAX_VALUE);
                    }

                }
                userJid = Utils.getValidJid(userJid);

                if (userJid != null && !userJid.isEmpty()) {
                    Jid jid = Utils.getFullJid(userJid);
                    queryArgs.limitResultsToJid(jid);
                }

                Utils.printLog("MAM query Args " + queryArgs.toString());
                org.jivesoftware.smackx.mam.MamManager.MamQuery query = mamManager.queryArchive(queryArgs.build());
                List<Message> messageList = query.getMessages();

                for (Message message : messageList) {
                    Utils.printLog("Received Message " + message.toXML(null));
                    Utils.broadcastMessageToFlutter(FlutterXmppConnection.getApplicationContext(), message);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }

        }
    }

}
