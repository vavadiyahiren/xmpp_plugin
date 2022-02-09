package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.Stanza;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class MessageListener implements StanzaListener {

    private static Context mApplicationContext;

    public MessageListener(Context context) {
        mApplicationContext = context;
    }

    @Override
    public void processStanza(Stanza packet) {

        Message message = (Message) packet;
        Utils.broadcastMessageToFlutter(mApplicationContext, message);
    }
}
