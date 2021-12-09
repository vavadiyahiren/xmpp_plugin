package org.xrstudio.xmpp.flutter_xmpp;

import java.util.Date;

public class Utils {

    public static String getValidJid(String Jid) {

        if (Jid != null && Jid.contains(Constants.SYMBOL_COMPARE_JID)) {
            Jid = Jid.split(Constants.SYMBOL_COMPARE_JID)[0];
        }
        return Jid != null ? Jid : "";
    }

    public static long getLongDate() {
        return new Date().getTime();
    }

    public static String getJidWithDomainName(String jid, String host) {
        return jid.contains(host) ? jid : jid + Constants.SYMBOL_COMPARE_JID + host;
    }
}
