package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;
import android.content.Intent;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.StandardExtensionElement;
import org.jivesoftware.smack.packet.Stanza;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class StanzaAckListener implements StanzaListener {

    private static Context mApplicationContext;

    public StanzaAckListener(Context context) {
        mApplicationContext = context;
    }

    @Override
    public void processStanza(Stanza packet) {


        if (packet instanceof Message) {

            Message ackMessage = (Message) packet;

            Utils.addLogInStorage(" Action: receiveStanzaAckFromServer, Content: " + ackMessage.toXML().toString());

            String time = Constants.ZERO;
            if (ackMessage.getExtension(Constants.URN_XMPP_TIME) != null) {
                StandardExtensionElement timeElement = (StandardExtensionElement) ackMessage
                        .getExtension(Constants.URN_XMPP_TIME);
                if (timeElement != null && timeElement.getFirstElement(Constants.TS) != null) {
                    time = timeElement.getFirstElement(Constants.TS).getText();
                }
            }

            //Bundle up the intent and send the broadcast.
            Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
            intent.setPackage(mApplicationContext.getPackageName());
            intent.putExtra(Constants.BUNDLE_FROM_JID, ackMessage.getTo().toString());
            intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, ackMessage.getBody());
            intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, ackMessage.getStanzaId());
            intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, ackMessage.getType().toString());
            intent.putExtra(Constants.META_TEXT, Constants.ACK);
            intent.putExtra(Constants.time, time);
            mApplicationContext.sendBroadcast(intent);
        }

    }
}
