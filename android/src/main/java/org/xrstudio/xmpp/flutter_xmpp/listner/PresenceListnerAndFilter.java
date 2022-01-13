package org.xrstudio.xmpp.flutter_xmpp.listner;

import android.content.Context;
import android.content.Intent;

import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.packet.Presence;
import org.jivesoftware.smack.packet.Stanza;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

public class PresenceListnerAndFilter implements StanzaListener {

    private static Context mApplicationContext;

    public PresenceListnerAndFilter(Context context) {
        mApplicationContext = context;
    }

    @Override
    public void processStanza(Stanza packet) {

        Presence presence = (Presence) packet;

        String jid = presence.getFrom().toString();
        Presence.Type type = presence.getType();
        Presence.Mode mode = presence.getMode();

        Utils.printLog("Type : " + type + " , Mode " + mode);

        Intent intent = new Intent(Constants.PRESENCE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_FROM_JID, jid);
        intent.putExtra(Constants.BUNDLE_PRESENCE_TYPE, type.toString().toLowerCase());
        intent.putExtra(Constants.BUNDLE_PRESENCE_MODE, mode.toString().toLowerCase());

        mApplicationContext.sendBroadcast(intent);


    }
}
