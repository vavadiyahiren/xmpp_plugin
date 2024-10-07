package org.xrstudio.xmpp.flutter_xmpp.Connection;

import android.app.Service;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

import org.jivesoftware.smack.SmackException;
import org.jivesoftware.smack.XMPPException;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.LoggedInState;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

import java.io.IOException;

public class FlutterXmppConnectionService extends Service {

    public static LoggedInState sLoggedInState;
    public static ConnectionState sConnectionState;
    private Integer port;
    private Thread mThread;
    private boolean mActive;
    private String host = "";
    private Handler mTHandler;
    private String jid_user = "";
    private String password = "";
    private boolean requireSSLConnection = false, autoDeliveryReceipt = false, useStreamManagement = true,
            automaticReconnection = true, registerUser = false;
    private FlutterXmppConnection mConnection;

    public FlutterXmppConnectionService() {
    }

    public static ConnectionState getState() {
        if (sConnectionState == null) {
            return ConnectionState.DISCONNECTED;
        }
        return sConnectionState;
    }

    public static LoggedInState getLoggedInState() {
        if (sLoggedInState == null) {
            return LoggedInState.LOGGED_OUT;
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

        Utils.printLog(" onCreate(): ");

    }

    private void initConnection() {
        try {

            Utils.printLog(" initConnection(): ");

            if (mConnection == null) {
                mConnection = new FlutterXmppConnection(this, this.jid_user, this.password, this.host, this.port,
                        requireSSLConnection, autoDeliveryReceipt, useStreamManagement, automaticReconnection,
                        registerUser, this);
            }

            mConnection.connect();

        } catch (IOException | SmackException | XMPPException e) {
            FlutterXmppConnectionService.sConnectionState = ConnectionState.FAILED;
            Utils.broadcastConnectionMessageToFlutter(this, ConnectionState.FAILED,
                    "Something went wrong while connecting ,make sure the credentials are right and try again.");
            Utils.printLog(
                    " Something went wrong while connecting ,make sure the credentials are right and try again: ");
            e.printStackTrace();
            stopSelf();
        }
    }

    public void start() {

        Utils.printLog(" Service Start() function called: " + mActive);

        if (!mActive) {
            mActive = true;
            if (mThread == null || !mThread.isAlive()) {
                mThread = new Thread(() -> {
                    Looper.prepare();
                    mTHandler = new Handler();
                    initConnection();
                    Looper.loop();
                });
                mThread.start();
            }
        }

    }

    public void stop() {

        Utils.printLog(" stop() :");

        mActive = false;
        if (mThread.isAlive() && mThread != null) {
            mThread.interrupt();
            mThread = null;
        }
        if (mTHandler != null) {
            mTHandler.post(() -> {
                if (mConnection != null) {
                    mConnection.disconnect();
                    mConnection = null;
                }
            });
        }

    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {

        Utils.printLog(" onStartCommand(): ");

        Bundle extras = intent.getExtras();

        if (extras == null) {

            Utils.printLog(" Missing User JID/Password/Host/Port: ");

        } else {
            this.jid_user = extras.getString(Constants.JID_USER);
            this.password = extras.getString(Constants.PASSWORD);
            this.host = extras.getString(Constants.HOST);
            this.port = extras.getInt(Constants.PORT, 5222);
            this.requireSSLConnection = extras.getBoolean(Constants.REQUIRE_SSL_CONNECTION, false);
            this.autoDeliveryReceipt = extras.getBoolean(Constants.AUTO_DELIVERY_RECEIPT, false);
            this.useStreamManagement = extras.getBoolean(Constants.USER_STREAM_MANAGEMENT, true);
            this.automaticReconnection = extras.getBoolean(Constants.AUTOMATIC_RECONNECTION, true);
            this.registerUser = extras.getBoolean(Constants.REGISTER_USER, false);

        }
        start();
        return Service.START_STICKY;
    }

    @Override
    public void onDestroy() {

        Utils.printLog(" onDestroy(): ");
        super.onDestroy();
        stop();
    }
}
