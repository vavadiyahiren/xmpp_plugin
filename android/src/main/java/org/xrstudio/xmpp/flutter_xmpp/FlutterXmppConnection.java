package org.xrstudio.xmpp.flutter_xmpp;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import org.jivesoftware.smack.ConnectionConfiguration;
import org.jivesoftware.smack.ConnectionListener;
import org.jivesoftware.smack.ReconnectionManager;
import org.jivesoftware.smack.SmackException;
import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.XMPPConnection;
import org.jivesoftware.smack.XMPPException;
import org.jivesoftware.smack.filter.StanzaFilter;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.Stanza;
import org.jivesoftware.smack.tcp.XMPPTCPConnection;
import org.jivesoftware.smack.tcp.XMPPTCPConnectionConfiguration;
import org.jivesoftware.smack.util.TLSUtils;
import org.jivesoftware.smackx.muc.MucEnterConfiguration;
import org.jivesoftware.smackx.muc.MultiUserChat;
import org.jivesoftware.smackx.muc.MultiUserChatManager;
import org.jivesoftware.smackx.receipts.DeliveryReceiptRequest;
import org.jxmpp.jid.EntityBareJid;
import org.jxmpp.jid.impl.JidCreate;
import org.jxmpp.jid.parts.Resourcepart;

import java.io.IOException;
import java.net.InetAddress;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;

public class FlutterXmppConnection implements ConnectionListener {

    private static final String TAG = "flutter_xmpp";
    private static final String conferenceDomainName = "@conference.test.chat.fish";

    private static XMPPTCPConnection mConnection;
    private static MultiUserChatManager multiUserChatManager;
    private Context mApplicationContext;
    private String mUsername = "";
    private String mPassword;
    private String mServiceName = "";
    private String mResource = "";
    private String mHost;
    private Integer mPort = 5222;
    private BroadcastReceiver uiThreadMessageReceiver;//Receives messages from the ui thread.

    public FlutterXmppConnection(Context context, String jid_user, String password, String host, Integer port) {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, "Connection Constructor called.");
        }
        mApplicationContext = context.getApplicationContext();
        String jid = jid_user;
        mPassword = password;
        mPort = port;
        mHost = host;
        if (jid != null) {
            String[] jid_list = jid.split("@");
            mUsername = jid_list[0];
            if (jid_list[1].contains("/")) {
                String[] domain_resource = jid_list[1].split("/");
                mServiceName = domain_resource[0];
                mResource = domain_resource[1];
            } else {
                mServiceName = jid_list[1];
                mResource = "Android";
            }
        }
    }

    public static boolean validIP(String ip) {
        try {
            if (ip == null || ip.isEmpty()) {
                return false;
            }

            String[] parts = ip.split("\\.");
            if (parts.length != 4) {
                return false;
            }

            for (String s : parts) {
                int i = Integer.parseInt(s);
                if ((i < 0) || (i > 255)) {
                    return false;
                }
            }
            return !ip.endsWith(".");
        } catch (NumberFormatException nfe) {
            return false;
        }
    }

    public void connect() throws IOException, XMPPException, SmackException {
        XMPPTCPConnectionConfiguration.Builder conf = XMPPTCPConnectionConfiguration.builder();
        conf.setXmppDomain(mServiceName);

        // Check if the Host address is the ip then set up host and host address.
        if (validIP(mHost)) {

            Log.d("validhost", "connecting via ip :" + validIP(mHost));

            InetAddress addr = InetAddress.getByName(mHost);
            conf.setHostAddress(addr);
            conf.setHost(mHost);
        } else {

            Log.d("validhost", "not valid host");

            conf.setHost(mHost);
        }

        if (mPort != 0) {
            conf.setPort(mPort);
        }

        conf.setUsernameAndPassword(mUsername, mPassword);
        conf.setResource(mResource);
        conf.setCompressionEnabled(true);


        SSLContext context = null;
        try {
            context = SSLContext.getInstance("TLS");
            context.init(null, new TrustManager[]{new TLSUtils.AcceptAllTrustManager()}, new SecureRandom());
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (KeyManagementException e) {
            e.printStackTrace();
        }
        conf.setCustomSSLContext(context);

        conf.setKeystoreType(null);
        conf.setSecurityMode(ConnectionConfiguration.SecurityMode.ifpossible);

        Log.d("loginTest", "connect 1 mServiceName: " + mServiceName + " mHost: " + mHost + " mPort: " + mPort + " mUsername: " + mUsername + " mPassword: " + mPassword + " mResource:" + mResource);


        //Set up the ui thread broadcast message receiver.

        mConnection = new XMPPTCPConnection(conf.build());
        mConnection.addConnectionListener(this);

        try {

            if (FlutterXmppPlugin.DEBUG) {
                Log.d(TAG, "Calling connect() ");
            }
            mConnection.connect();
            mConnection.login(/*mUsername, mPassword*/);

        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        mConnection.addStanzaAcknowledgedListener(new StanzaListener() {
            @Override
            public void processStanza(Stanza packet) throws SmackException.NotConnectedException, InterruptedException, SmackException.NotLoggedInException {
                if (FlutterXmppPlugin.DEBUG) {


                    if (packet instanceof Message) {

                        Message ackMessage = (Message) packet;
                        //Bundle up the intent and send the broadcast.
                        Intent intent = new Intent(FlutterXmppConnectionService.RECEIVE_MESSAGE);
                        intent.setPackage(mApplicationContext.getPackageName());
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID, ackMessage.getTo().toString());
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, ackMessage.getBody());
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, ackMessage.getStanzaId());
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, "normal");
                        mApplicationContext.sendBroadcast(intent);
                    }

                }
            }
        });

        setupUiThreadBroadCastMessageReceiver();

        mConnection.addSyncStanzaListener(new StanzaListener() {
            @Override
            public void processStanza(Stanza packet) throws SmackException.NotConnectedException, InterruptedException, SmackException.NotLoggedInException {

                try {

                    Message message = (Message) packet;
                    String body = message.getBody();

                    if (!body.isEmpty()) {

                        String from = message.getFrom().toString();
                        String contactJid = "";

                        if (from.toLowerCase().contains("/")) {
                            contactJid = from.split("/")[0];
                            if (FlutterXmppPlugin.DEBUG) {
                                Log.d(TAG, "The real jid is :" + contactJid + " || The message is from :" + from);
                            }
                        } else {
                            contactJid = from;
                        }

                        String msgId = message.getStanzaId();
                        String mediaURL = "";

                        if (!from.equals(mUsername)) {
                            //Bundle up the intent and send the broadcast.
                            Intent intent = new Intent(FlutterXmppConnectionService.RECEIVE_MESSAGE);
                            intent.setPackage(mApplicationContext.getPackageName());
                            intent.putExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID, contactJid);
                            intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, body);
                            intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, msgId);
                            intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, message.getType().toString());
                            intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_SENDER_JID, from);
                            intent.putExtra(FlutterXmppConnectionService.MEDIA_URL, mediaURL);

                            mApplicationContext.sendBroadcast(intent);
                        }

                    }
                } catch (Exception e) {
                    Log.d(TAG, "Main Exception : " + e.getLocalizedMessage());
                }

            }
        }, new StanzaFilter() {
            @Override
            public boolean accept(Stanza stanza) {
                return stanza instanceof Message;
            }
        });

        ReconnectionManager reconnectionManager = ReconnectionManager.getInstanceFor(mConnection);
        ReconnectionManager.setEnabledPerDefault(true);
        reconnectionManager.enableAutomaticReconnection();

    }

    private void setupUiThreadBroadCastMessageReceiver() {

        uiThreadMessageReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {

                //Check if the Intents purpose is to send the message.
                String action = intent.getAction();

                if (action.equals(FlutterXmppConnectionService.SEND_MESSAGE) || action.equals(FlutterXmppConnectionService.GROUP_SEND_MESSAGE)) {
                    //Send the message.
                    sendMessage(intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY),
                            intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_TO),
                            intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS),
                            action.equals(FlutterXmppConnectionService.SEND_MESSAGE));

                } else if (action.equals(FlutterXmppConnectionService.JOIN_GROUPS_MESSAGE)) {

                    // Join all group
                    joinAllGroups(intent.getStringArrayListExtra(FlutterXmppConnectionService.GROUP_IDS));
                }
            }
        };

        IntentFilter filter = new IntentFilter();
        filter.addAction(FlutterXmppConnectionService.SEND_MESSAGE);
        filter.addAction(FlutterXmppConnectionService.READ_MESSAGE);
        filter.addAction(FlutterXmppConnectionService.GROUP_SEND_MESSAGE);
        filter.addAction(FlutterXmppConnectionService.JOIN_GROUPS_MESSAGE);
        mApplicationContext.registerReceiver(uiThreadMessageReceiver, filter);

    }


    private void sendMessage(String body, String toJid, String msgId, boolean isDm) {

        try {

            Message xmppMessage = new Message();
            xmppMessage.setStanzaId(msgId);

            xmppMessage.setBody(body);
            xmppMessage.setType(isDm ? Message.Type.chat : Message.Type.groupchat);

            DeliveryReceiptRequest deliveryReceiptRequest = new DeliveryReceiptRequest();
            xmppMessage.addExtension(deliveryReceiptRequest);

            if (isDm) {
                xmppMessage.setTo(JidCreate.from(toJid));
                mConnection.sendStanza(xmppMessage);
            } else {
                EntityBareJid jid = JidCreate.entityBareFrom(toJid);
                xmppMessage.setTo(jid);
                EntityBareJid mucJid = (EntityBareJid) JidCreate.bareFrom(toJid);
                MultiUserChat muc = multiUserChatManager.getMultiUserChat(mucJid);
                muc.sendMessage(xmppMessage);
            }

            if (FlutterXmppPlugin.DEBUG) {
                Log.d(TAG, "Sent message from :" + xmppMessage.toXML(null) + "  sent.");
            }

        } catch (SmackException.NotConnectedException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public void disconnect() {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, "Disconnecting from server " + mServiceName);
        }
        if (mConnection != null) {
            mConnection.disconnect();
            mConnection = null;
        }

        // Unregister the message broadcast receiver.
        if (uiThreadMessageReceiver != null) {
            mApplicationContext.unregisterReceiver(uiThreadMessageReceiver);
            uiThreadMessageReceiver = null;
        }
    }

    @Override
    public void connected(XMPPConnection connection) {
        Log.d(TAG, "Connected Successfully");

        FlutterXmppConnectionService.sConnectionState = ConnectionState.CONNECTED;

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(FlutterXmppConnectionService.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID, mUsername);
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, "Connected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, "Connected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, "Connected");
        mApplicationContext.sendBroadcast(intent);

    }

    @Override
    public void authenticated(XMPPConnection connection, boolean resumed) {
        Log.d(TAG, "Flutter Authenticated Successfully");

        multiUserChatManager = MultiUserChatManager.getInstanceFor(connection);

        FlutterXmppConnectionService.sConnectionState = ConnectionState.CONNECTED;
//        showContactListActivityWhenAuthenticated();

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(FlutterXmppConnectionService.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID, mUsername);
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, "Authenticated");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, "Authenticated");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, "Authenticated");
        mApplicationContext.sendBroadcast(intent);

    }

    @Override
    public void connectionClosed() {
        Log.d(TAG, "Connectionclosed()");

        FlutterXmppConnectionService.sConnectionState = ConnectionState.DISCONNECTED;

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(FlutterXmppConnectionService.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID, "Disconnected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, "Disconnected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, "Disconnected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, "Disconnected");
        mApplicationContext.sendBroadcast(intent);

    }

    @Override
    public void connectionClosedOnError(Exception e) {
        Log.d(TAG, "ConnectionClosedOnError, error " + e.toString());

        FlutterXmppConnectionService.sConnectionState = ConnectionState.DISCONNECTED;

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(FlutterXmppConnectionService.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID, "Disconnected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, "Disconnected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, "Disconnected");
        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, "Disconnected");
        mApplicationContext.sendBroadcast(intent);

    }

    private void joinAllGroups(ArrayList<String> allGroupsIds) {

        try {

            printLog("joinAllGroups: size : " + allGroupsIds.size());

            for (String groupId : allGroupsIds) {

                String roomId = groupId + conferenceDomainName;
                printLog("joinAllGroups: join groupId: " + roomId);

                MultiUserChat multiUserChat = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(roomId));
                Resourcepart resourcepart = Resourcepart.from(mUsername);

                MucEnterConfiguration mucEnterConfiguration = multiUserChat.getEnterConfigurationBuilder(resourcepart)
                        .requestHistorySince(5000)
                        .build();

                // Join function is Working on Android to iOS messaging

                printLog("joinAllGroups: join for 1 " + groupId);
                multiUserChat.join(mucEnterConfiguration);
                printLog("joinAllGroups: join for 2 " + groupId);

//                if (!multiUserChat.isJoined()) {
//                    printLog("joinAllGroups: join for " + roomId);
//                    multiUserChat.createOrJoin(mucEnterConfiguration);
//                }

            }

        } catch (Exception e) {
            printLog("joinAllGroups: exception: " + e.getLocalizedMessage());
            e.printStackTrace();
        }
    }

    void printLog(String message) {
        if (FlutterXmppPlugin.DEBUG) {
            Log.d(TAG, message);
        }
    }

    public enum ConnectionState {
        CONNECTED, AUTHENTICATED, CONNECTING, DISCONNECTING, DISCONNECTED
    }

    public enum LoggedInState {
        LOGGED_IN, LOGGED_OUT
    }
}
