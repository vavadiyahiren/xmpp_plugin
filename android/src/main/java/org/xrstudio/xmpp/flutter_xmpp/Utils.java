package org.xrstudio.xmpp.flutter_xmpp;

import android.os.Environment;
import android.util.Log;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class Utils {

    static String logFilePath = "";
    static String logFileName = "xmpp_logs.txt";

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

    public static String getRoomIdWithDomainName(String groupName, String host) {
        String roomId = groupName;
        if (!groupName.contains(Constants.CONFERENCE)) {
            roomId = groupName + "@" + Constants.CONFERENCE + "." + host;
        }
        return roomId;
    }

    public static void addLogInStorage(String text) {
        if (logFilePath == null || logFilePath.isEmpty()) {
            return;
        }
        text = "Time: " + getTimeMillisecondFormat() + " " + text;
        boolean fileExists = true;
//        checkDirectoryExist(logFilePath);
        try {
            File logFile = new File(logFilePath);

            if (!logFile.exists()) {
                try {
                    fileExists = logFile.createNewFile();
                } catch (IOException e) {
                    fileExists = false;
                    e.printStackTrace();
                }
            }
            if (fileExists) {
                try {
                    BufferedWriter buf = new BufferedWriter(new FileWriter(logFile, true));
                    buf.append(text.trim());
                    buf.append("\n");
                    buf.newLine();
                    buf.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void checkDirectoryExist(String directoryName) {
        File dir = new File(Environment.getExternalStorageDirectory(), directoryName);
        if (!dir.exists()) {
            dir.mkdirs();
        }
    }

    public static String getTimeMillisecondFormat() {
        return convertDate(new Date().getTime(), "dd-MM-yyyy HH:mm:ss.SSS");
    }

    public static String convertDate(long dateToConvert, String ddMmFormat) {
        Date date = new Date(dateToConvert);
        SimpleDateFormat df2 = new SimpleDateFormat(ddMmFormat, Locale.getDefault());
        return df2.format(date);
    }
}
