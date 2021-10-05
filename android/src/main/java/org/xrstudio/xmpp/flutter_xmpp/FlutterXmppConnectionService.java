package org.xrstudio.xmpp.flutter_xmpp;

import android.app.Service;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import org.jivesoftware.smack.SmackException;
import org.jivesoftware.smack.XMPPException;

import java.io.IOException;

public class FlutterXmppConnectionService extends Service {

    public static final String READ_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.readmessage";
    public static final String SEND_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.sendmessage";
    public static final String BUNDLE_MESSAGE_BODY = "b_body";
    public static final String BUNDLE_MESSAGE_PARAMS = "b_body_params";
    public static final String BUNDLE_MESSAGE_TYPE = "b_body_type";
    public static final String BUNDLE_MESSAGE_SENDER_JID = "b_sender_jid";
    public static final String BUNDLE_TO = "b_to";
    public static final String MEDIA_URL = "media_url";
    public static final String OUTGOING_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.outgoinmessage";
    public static final String BUNDLE_TO_JID = "c_from";
    public static final String GROUP_SEND_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.sendGroupMessage";
    public static final String JOIN_GROUPS_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.joinAllGroupsMessage";
    public static final String GROUP_IDS = "group_ids";
    public static final String RECEIVE_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.receivemessage";
    public static final String BUNDLE_FROM_JID = "b_from";
    public static final String AUTH_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.authmessage";
    public static final String CONNECTION_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.connmessage";
    private static final String TAG = "flutter_xmpp";
    public static FlutterXmppConnection.ConnectionState sConnectionState;
    public static FlutterXmppConnection.LoggedInState sLoggedInState;
    private boolean mActive;
    private Thread mThread;
    private Handler mTHandler;

    private FlutterXmppConnection mConnection;

    private String jid_user = "";
    private String password = "";
    private String host = "";
    private Integer port;


    public FlutterXmppConnectionService() {
    }

    public static FlutterXmppConnection.ConnectionState getState() {
        if (sConnectionState == null) {
            return FlutterXmppConnection.ConnectionState.DISCONNECTED;
        }
        return sConnectionState;
    }

    public static FlutterXmppConnection.LoggedInState getLoggedInState() {
        if (sLoggedInState == null) {
            return FlutterXmppConnection.LoggedInState.LOGGED_OUT;
        }
        return sLoggedInState;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, "onCreate()");
        }
    }

    private void initConnection() {
        try {

            if (FlutterXmppPlugin.DEBUG) {
                Log.d(TAG, "initConnection()");
            }

            if (mConnection == null) {
                mConnection = new FlutterXmppConnection(this, this.jid_user, this.password, this.host, this.port);
            }

            mConnection.connect();

        } catch (IOException | SmackException | XMPPException e) {
            if (FlutterXmppPlugin.DEBUG) {
                Log.d(TAG, "Something went wrong while connecting ,make sure the credentials are right and try again");
            }
            e.printStackTrace();
            stopSelf();
        }
    }

    public void start() {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, " Service Start() function called.");
        }
        if (!mActive) {
            mActive = true;
            if (mThread == null || !mThread.isAlive()) {
                mThread = new Thread(new Runnable() {
                    @Override
                    public void run() {
                        Looper.prepare();
                        mTHandler = new Handler();
                        initConnection();
                        Looper.loop();
                    }
                });
                mThread.start();
            }
        }

    }

    public void stop() {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, "stop()");
        }
        mActive = false;
        if (mTHandler != null) {
            mTHandler.post(new Runnable() {
                @Override
                public void run() {
                    if (mConnection != null) {
                        mConnection.disconnect();
                    }
                }
            });
        }
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, "onStartCommand()");
        }
        Bundle extras = intent.getExtras();

        if (extras == null) {
            if (FlutterXmppPlugin.DEBUG) {
                Log.d(TAG, "Missing User JID/Password/Host/Port");
            }
        } else {
            this.jid_user = (String) extras.get("jid_user");
            this.password = (String) extras.get("password");
            this.host = (String) extras.get("host");
            this.port = (Integer) extras.get("port");
        }
        start();
        return Service.START_STICKY;
    }

    @Override
    public void onDestroy() {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, "onDestroy()");
        }
        super.onDestroy();
        stop();
    }
}

