package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;
import android.content.Intent;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.Stanza;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class StanzaAckListner implements StanzaListener {

    private static Context mApplicationContext;

    public StanzaAckListner(Context context) {
        mApplicationContext = context;
    }

    @Override
    public void processStanza(Stanza packet) {


        if (packet instanceof Message) {

            Message ackMessage = (Message) packet;

            Utils.addLogInStorage(" Action: receiveStanzaAckFromServer, Content: " + ackMessage.toXML(null).toString());

            //Bundle up the intent and send the broadcast.
            Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
            intent.setPackage(mApplicationContext.getPackageName());
            intent.putExtra(Constants.BUNDLE_FROM_JID, ackMessage.getTo().toString());
            intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, ackMessage.getBody());
            intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, ackMessage.getStanzaId());
            intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, ackMessage.getType().toString());
            intent.putExtra(Constants.META_TEXT, Constants.ACK);
            mApplicationContext.sendBroadcast(intent);
        }

    }
}
