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
import org.jivesoftware.smackx.muc.Affiliate;
import org.jivesoftware.smackx.muc.MucEnterConfiguration;
import org.jivesoftware.smackx.muc.MultiUserChat;
import org.jivesoftware.smackx.muc.MultiUserChatManager;
import org.jivesoftware.smackx.receipts.DeliveryReceiptRequest;
import org.jivesoftware.smack.packet.StandardExtensionElement;
import org.jivesoftware.smackx.xdata.Form;
import org.jxmpp.jid.EntityBareJid;
import org.jxmpp.jid.Jid;
import org.jxmpp.jid.impl.JidCreate;
import org.jxmpp.jid.parts.Resourcepart;

import java.io.IOException;
import java.net.InetAddress;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.jivesoftware.smackx.receipts.DeliveryReceipt;
import org.jivesoftware.smackx.receipts.DeliveryReceiptManager;
import org.jivesoftware.smackx.receipts.ReceiptReceivedListener;
import org.jivesoftware.smackx.receipts.DeliveryReceiptManager.AutoReceiptMode;
import org.jivesoftware.smackx.receipts.DeliveryReceiptRequest;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;

public class FlutterXmppConnection implements ConnectionListener {

    private static final String TAG = "flutter_xmpp";
    private static final String conferenceDomainName = "@conference";

    private static XMPPTCPConnection mConnection;
    private static MultiUserChatManager multiUserChatManager;
    private Context mApplicationContext;
    private static String mUsername = "";
    private static String mPassword;
    private static String mServiceName = "";
    private static String mResource = "";
    private static String mHost;
    private static Integer mPort = 5222;
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
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, ackMessage.getType().toString());
                        intent.putExtra(FlutterXmppConnectionService.META_TEXT, Constants.ACK);
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
                    String META_TEXT = "Message";
                    String body = message.getBody();
                    String from = message.getFrom().toString();
                    String msgId = message.getStanzaId();
                    String customText = "";
                    StandardExtensionElement customElement = (StandardExtensionElement) message
                            .getExtension("urn:xmpp:custom");
                    if (customElement != null && customElement.getFirstElement("custom") != null) {
                        customText = customElement.getFirstElement("custom").getText();
                    }

                    if (message.hasExtension(DeliveryReceipt.ELEMENT, DeliveryReceipt.NAMESPACE)) {
                        DeliveryReceipt dr = DeliveryReceipt.from((Message) message);
                        msgId = dr.getId();
                        META_TEXT = Constants.DELIVERY_ACK;
                        System.out.println("Delivery receipt received" + dr.getId());
                    }

                    String mediaURL = "";

                    if (!from.equals(mUsername)) {
                        //Bundle up the intent and send the broadcast.
                        Intent intent = new Intent(FlutterXmppConnectionService.RECEIVE_MESSAGE);
                        intent.setPackage(mApplicationContext.getPackageName());
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID, from);
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, body);
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, msgId);
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE, message.getType().toString());
                        intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_SENDER_JID, from);
                        intent.putExtra(FlutterXmppConnectionService.MEDIA_URL, mediaURL);
                        intent.putExtra(FlutterXmppConnectionService.CUSTOM_TEXT, customText);
                        intent.putExtra(FlutterXmppConnectionService.META_TEXT, META_TEXT);

                        mApplicationContext.sendBroadcast(intent);
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
                Log.d(TAG, " action " + action);
                if (action.equals(FlutterXmppConnectionService.SEND_MESSAGE)
                        || action.equals(FlutterXmppConnectionService.GROUP_SEND_MESSAGE)) {
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

            DeliveryReceiptRequest.addTo(xmppMessage);

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

    public static void sendCustomMessage(String body, String toJid, String msgId, String customText, boolean isDm) {

        try {

            Message xmppMessage = new Message();
            xmppMessage.setStanzaId(msgId);

            xmppMessage.setBody(body);
            xmppMessage.setType(isDm ? Message.Type.chat : Message.Type.groupchat);
            DeliveryReceiptRequest.addTo(xmppMessage);

            StandardExtensionElement element = StandardExtensionElement.builder("CUSTOM", "urn:xmpp:custom")
                    .addElement("custom", customText).build();
            xmppMessage.addExtension(element);

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

    public static void send_delivery_receipt(String toJid, String msgId, String receiptId) {

        try {

            if (!toJid.contains(mHost)) {
                toJid = toJid + "@" + mHost;
            }

            Message deliveryMessage = new Message();
            deliveryMessage.setStanzaId(receiptId);
            deliveryMessage.setTo(JidCreate.from(toJid));

            DeliveryReceipt deliveryReceipt = new DeliveryReceipt(msgId);
            deliveryMessage.addExtension(deliveryReceipt);

            mConnection.sendStanza(deliveryMessage);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }


    public static void manageAddMembersInGroup(GROUP_ROLE groupRole, String groupName, ArrayList<String> membersJid) {

        try {

            List<Jid> jidList = new ArrayList<>();
            for (String memberJid : membersJid) {
                if (!memberJid.contains(mHost)) {
                    memberJid = memberJid + "@" + mHost;
                }
                Jid jid = JidCreate.from(memberJid);
                jidList.add(jid);
            }

            String roomId = groupName;
            if (!groupName.contains(Constants.CONFERENCE)) {
                roomId = groupName + "@" + Constants.CONFERENCE + "." + mHost;
            }

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(roomId));
            if (groupRole == GROUP_ROLE.ADMIN) {
                muc.grantAdmin(jidList);
            } else if (groupRole == GROUP_ROLE.MEMBER) {
                muc.grantMembership(jidList);
            } else {

            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void manageRemoveFromGroup(GROUP_ROLE groupRole, String groupName, ArrayList<String> membersJid) {

        try {

            List<Jid> jidList = new ArrayList<>();
            for (String memberJid : membersJid) {
                if (!memberJid.contains(mHost)) {
                    memberJid = memberJid + "@" + mHost;
                }
                Jid jid = JidCreate.from(memberJid);
                jidList.add(jid);
            }

            String roomId = groupName;
            if (!groupName.contains(Constants.CONFERENCE)) {
                roomId = groupName + "@" + Constants.CONFERENCE + "." + mHost;
            }

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(roomId));
            if (groupRole == GROUP_ROLE.ADMIN) {

                for (Jid jid : jidList) {
                    muc.revokeAdmin(jid.asEntityJidOrThrow());
                }

            } else if (groupRole == GROUP_ROLE.MEMBER) {
                muc.revokeMembership(jidList);
            } else {
                // OWNERS
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static List<String> getMembersOrAdminsOrOwners(GROUP_ROLE groupRole, String groupName) {
        List<String> jidList = new ArrayList<>();

        try {
            List<Affiliate> affiliates;
            String roomId = groupName;
            if (!groupName.contains(Constants.CONFERENCE)) {
                roomId = groupName + "@" + Constants.CONFERENCE + "." + mHost;
            }

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(roomId));
            if (groupRole == GROUP_ROLE.ADMIN) {
                affiliates = muc.getAdmins();
            } else if (groupRole == GROUP_ROLE.MEMBER) {
                affiliates = muc.getMembers();
            } else if (groupRole == GROUP_ROLE.OWNER) {
                affiliates = muc.getOwners();
            } else {
                affiliates = new ArrayList<>();
            }
            if (affiliates.size() > 0) {
                for (Affiliate affiliate : affiliates) {
                    String jid = affiliate.getJid().toString();
                    jidList.add(jid);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
        return jidList;
    }

    public static int getOccupantsSize(String groupName) {

        try {
            String roomId = groupName;
            if (!groupName.contains(Constants.CONFERENCE)) {
                roomId = groupName + "@" + Constants.CONFERENCE + "." + mHost;
            }

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(roomId));
            return muc.getOccupants().size();

        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
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

    public static String createMUC(String groupName, String persistent) {

        String response = "FAIL";
        try {

            String roomId = groupName;
            if (!groupName.contains(Constants.CONFERENCE)) {
                roomId = groupName + "@" + Constants.CONFERENCE + "." + mHost;
            }

            MultiUserChat multiUserChat = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(roomId));
            multiUserChat.create(Resourcepart.from(mUsername));

            if (persistent.equals(Constants.TRUE)) {
                Form form = multiUserChat.getConfigurationForm();
                Form answerForm = form.createAnswerForm();
                answerForm.setAnswer("muc#roomconfig_persistentroom", true);
                answerForm.setAnswer("muc#roomconfig_membersonly", true);
                multiUserChat.sendConfigurationForm(answerForm);
            }

            response = "SUCCESS";

        } catch (Exception e) {
            e.printStackTrace();
        }
        return response;

    }

    private void joinAllGroups(ArrayList<String> allGroupsIds) {

        try {

            for (String groupId : allGroupsIds) {

                String[] groupData = groupId.split(",");
                String groupName = groupData[0];
                String lastMsgTime = groupData[1];

                String roomId = groupName + conferenceDomainName + "." + mHost;
                MultiUserChat multiUserChat = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(roomId));
                Resourcepart resourcepart = Resourcepart.from(mUsername);

                long currentTime = new Date().getTime();
                long lastMessageTime = Long.valueOf(lastMsgTime);
                long diff = currentTime - lastMessageTime;

                MucEnterConfiguration mucEnterConfiguration = multiUserChat.getEnterConfigurationBuilder(resourcepart)
                        .requestHistorySince((int) diff)
                        .build();

                if (!multiUserChat.isJoined()) {
                    multiUserChat.join(mucEnterConfiguration);
                }

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
