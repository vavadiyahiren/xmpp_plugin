package org.xrstudio.xmpp.flutter_xmpp.Connection;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import org.jivesoftware.smack.ConnectionConfiguration;
import org.jivesoftware.smack.ConnectionListener;
import org.jivesoftware.smack.ReconnectionManager;
import org.jivesoftware.smack.SmackException;
import org.jivesoftware.smack.StanzaListener;
import org.jivesoftware.smack.XMPPConnection;
import org.jivesoftware.smack.XMPPException;
import org.jivesoftware.smack.filter.StanzaFilter;
import org.jivesoftware.smack.packet.Message;
import org.jivesoftware.smack.packet.Presence;
import org.jivesoftware.smack.packet.StandardExtensionElement;
import org.jivesoftware.smack.packet.Stanza;
import org.jivesoftware.smack.roster.Roster;
import org.jivesoftware.smack.roster.RosterEntry;
import org.jivesoftware.smack.tcp.XMPPTCPConnection;
import org.jivesoftware.smack.tcp.XMPPTCPConnectionConfiguration;
import org.jivesoftware.smack.util.TLSUtils;
import org.jivesoftware.smackx.iqlast.LastActivityManager;
import org.jivesoftware.smackx.iqlast.packet.LastActivity;
import org.jivesoftware.smackx.muc.Affiliate;
import org.jivesoftware.smackx.muc.MucEnterConfiguration;
import org.jivesoftware.smackx.muc.MultiUserChat;
import org.jivesoftware.smackx.muc.MultiUserChatManager;
import org.jivesoftware.smackx.receipts.DeliveryReceipt;
import org.jivesoftware.smackx.receipts.DeliveryReceiptRequest;
import org.jivesoftware.smackx.xdata.Form;
import org.jxmpp.jid.EntityBareJid;
import org.jxmpp.jid.Jid;
import org.jxmpp.jid.impl.JidCreate;
import org.jxmpp.jid.parts.Resourcepart;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.GROUP_ROLE;
import org.xrstudio.xmpp.flutter_xmpp.FlutterXmppPlugin;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;

import java.io.IOException;
import java.net.InetAddress;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Set;

import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;

public class FlutterXmppConnection implements ConnectionListener {

    private static String mHost;
    private static String mPassword;
    private Context mApplicationContext;
    private static String mUsername = "";
    private static String mResource = "";
    private static Roster rosterConnection;
    private static String mServiceName = "";
    private static XMPPTCPConnection mConnection;
    private static MultiUserChatManager multiUserChatManager;
    private BroadcastReceiver uiThreadMessageReceiver;//Receives messages from the ui thread.

    public FlutterXmppConnection(Context context, String jid_user, String password, String host, Integer port) {

        Utils.printLog(" Connection Constructor called: ");

        mApplicationContext = context.getApplicationContext();
        mPassword = password;
        Constants.PORT_NUMBER = port;
        mHost = host;
        if (jid_user != null && jid_user.contains(Constants.SYMBOL_COMPARE_JID)) {
            String[] jid_list = jid_user.split(Constants.SYMBOL_COMPARE_JID);
            mUsername = jid_list[0];
            if (jid_list[1].contains(Constants.SYMBOL_FORWARD_SLASH)) {
                String[] domain_resource = jid_list[1].split(Constants.SYMBOL_FORWARD_SLASH);
                mServiceName = domain_resource[0];
                mResource = domain_resource[1];
            } else {
                mServiceName = jid_list[1];
                mResource = Constants.ANDROID;
            }
        }
    }

    public void connect() throws IOException, XMPPException, SmackException {

        XMPPTCPConnectionConfiguration.Builder conf = XMPPTCPConnectionConfiguration.builder();
        conf.setXmppDomain(mServiceName);

        // Check if the Host address is the ip then set up host and host address.
        if (Utils.validIP(mHost)) {

            Utils.printLog(" connecting via ip: " + Utils.validIP(mHost));

            InetAddress address = InetAddress.getByName(mHost);
            conf.setHostAddress(address);
            conf.setHost(mHost);
        } else {

            Utils.printLog(" not valid host: ");

            conf.setHost(mHost);
        }

        if (Constants.PORT_NUMBER != 0) {
            conf.setPort(Constants.PORT_NUMBER);
        }

        conf.setUsernameAndPassword(mUsername, mPassword);
        conf.setResource(mResource);
        conf.setCompressionEnabled(true);


        SSLContext context = null;
        try {
            context = SSLContext.getInstance(Constants.TLS);
            context.init(null, new TrustManager[]{new TLSUtils.AcceptAllTrustManager()}, new SecureRandom());
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (KeyManagementException e) {
            e.printStackTrace();
        }
        conf.setCustomSSLContext(context);

        conf.setKeystoreType(null);
        conf.setSecurityMode(ConnectionConfiguration.SecurityMode.ifpossible);

        Utils.printLog(" connect 1 mServiceName: " + mServiceName + " mHost: " + mHost + " mPort: " + Constants.PORT_NUMBER + " mUsername: " + mUsername + " mPassword: " + mPassword + " mResource:" + mResource);
        //Set up the ui thread broadcast message receiver.

        mConnection = new XMPPTCPConnection(conf.build());
        mConnection.addConnectionListener(this);

        try {

            Utils.printLog(" Calling connect(): ");
            mConnection.connect();

            rosterConnection = Roster.getInstanceFor(mConnection);
            rosterConnection.setSubscriptionMode(Roster.SubscriptionMode.accept_all);

            mConnection.login();

        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        mConnection.addSyncStanzaListener(new StanzaListener() {
            @Override
            public void processStanza(Stanza packet) {
                Presence presence = (Presence) packet;
                String jid = presence.getFrom().toString();
                Presence.Type type = presence.getType();
                Intent intent = new Intent(Constants.PRESENCE_MESSAGE);
                intent.setPackage(mApplicationContext.getPackageName());
                intent.putExtra(Constants.BUNDLE_FROM_JID, jid);
                intent.putExtra(Constants.BUNDLE_PRESENCE, type == Presence.Type.available ? Constants.ONLINE : Constants.OFFLINE);
                mApplicationContext.sendBroadcast(intent);
            }
        }, new StanzaFilter() {
            @Override
            public boolean accept(Stanza stanza) {
                return stanza instanceof Presence;
            }
        });

        mConnection.addStanzaAcknowledgedListener(new StanzaListener() {
            @Override
            public void processStanza(Stanza packet) throws SmackException.NotConnectedException, InterruptedException, SmackException.NotLoggedInException {
                if (FlutterXmppPlugin.DEBUG) {

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
        });

        setupUiThreadBroadCastMessageReceiver();

        mConnection.addSyncStanzaListener(new StanzaListener() {
            @Override
            public void processStanza(Stanza packet) throws SmackException.NotConnectedException, InterruptedException, SmackException.NotLoggedInException {

                try {

                    Message message = (Message) packet;

                    Utils.addLogInStorage(" Action: receiveMessageFromServer, Content: " + message.toXML(null).toString());

                    String META_TEXT = Constants.MESSAGE;
                    String body = message.getBody();
                    String from = message.getFrom().toString();
                    String msgId = message.getStanzaId();
                    String customText = "";
                    StandardExtensionElement customElement = (StandardExtensionElement) message
                            .getExtension(Constants.URN_XMPP_CUSTOM);
                    if (customElement != null && customElement.getFirstElement(Constants.custom) != null) {
                        customText = customElement.getFirstElement(Constants.custom).getText();
                    }

                    String time = Constants.ZERO;
                    if (message.getExtension(Constants.URN_XMPP_TIME) != null) {
                        StandardExtensionElement timeElement = (StandardExtensionElement) message
                                .getExtension(Constants.URN_XMPP_TIME);
                        if (timeElement != null && timeElement.getFirstElement(Constants.TS) != null) {
                            time = timeElement.getFirstElement(Constants.TS).getText();
                        }
                    }

                    if (message.hasExtension(DeliveryReceipt.ELEMENT, DeliveryReceipt.NAMESPACE)) {
                        DeliveryReceipt dr = DeliveryReceipt.from((Message) message);
                        msgId = dr.getId();
                        META_TEXT = Constants.DELIVERY_ACK;
                    }

                    String mediaURL = "";

                    if (!from.equals(mUsername)) {
                        //Bundle up the intent and send the broadcast.
                        Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
                        intent.setPackage(mApplicationContext.getPackageName());
                        intent.putExtra(Constants.BUNDLE_FROM_JID, from);
                        intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, body);
                        intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, msgId);
                        intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, message.getType().toString());
                        intent.putExtra(Constants.BUNDLE_MESSAGE_SENDER_JID, from);
                        intent.putExtra(Constants.MEDIA_URL, mediaURL);
                        intent.putExtra(Constants.CUSTOM_TEXT, customText);
                        intent.putExtra(Constants.META_TEXT, META_TEXT);
                        intent.putExtra(Constants.time, time);

                        mApplicationContext.sendBroadcast(intent);
                    }

                } catch (Exception e) {
                    Utils.printLog(" Main Exception : " + e.getLocalizedMessage());
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
                Utils.printLog(" action: " + action);
                if (action.equals(Constants.X_SEND_MESSAGE)
                        || action.equals(Constants.GROUP_SEND_MESSAGE)) {
                    //Send the message.
                    sendMessage(intent.getStringExtra(Constants.BUNDLE_MESSAGE_BODY),
                            intent.getStringExtra(Constants.BUNDLE_TO),
                            intent.getStringExtra(Constants.BUNDLE_MESSAGE_PARAMS),
                            action.equals(Constants.X_SEND_MESSAGE),
                            intent.getStringExtra(Constants.BUNDLE_MESSAGE_SENDER_TIME));

                }
            }
        };

        IntentFilter filter = new IntentFilter();
        filter.addAction(Constants.X_SEND_MESSAGE);
        filter.addAction(Constants.READ_MESSAGE);
        filter.addAction(Constants.GROUP_SEND_MESSAGE);
        mApplicationContext.registerReceiver(uiThreadMessageReceiver, filter);

    }

    private void sendMessage(String body, String toJid, String msgId, boolean isDm, String time) {

        try {

            Message xmppMessage = new Message();
            xmppMessage.setStanzaId(msgId);

            xmppMessage.setBody(body);
            xmppMessage.setType(isDm ? Message.Type.chat : Message.Type.groupchat);

            StandardExtensionElement timeElement = StandardExtensionElement.builder(Constants.TIME, Constants.URN_XMPP_TIME)
                    .addElement(Constants.TS, time).build();
            xmppMessage.addExtension(timeElement);

            DeliveryReceiptRequest.addTo(xmppMessage);

            if (isDm) {
                xmppMessage.setTo(JidCreate.from(toJid));
                mConnection.sendStanza(xmppMessage);
            } else {
                EntityBareJid jid = JidCreate.entityBareFrom(toJid);
                xmppMessage.setTo(jid);
                EntityBareJid mucJid = (EntityBareJid) JidCreate.bareFrom(Utils.getRoomIdWithDomainName(toJid, mHost));
                MultiUserChat muc = multiUserChatManager.getMultiUserChat(mucJid);
                muc.sendMessage(xmppMessage);
            }

            Utils.addLogInStorage("Action: sentMessageToServer, Content: " + xmppMessage.toXML(null).toString());

            Utils.printLog(" Sent message from: " + xmppMessage.toXML(null) + "  sent.");

        } catch (SmackException.NotConnectedException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void sendCustomMessage(String body, String toJid, String msgId, String customText, boolean isDm, String time) {

        try {

            Message xmppMessage = new Message();
            xmppMessage.setStanzaId(msgId);

            xmppMessage.setBody(body);
            xmppMessage.setType(isDm ? Message.Type.chat : Message.Type.groupchat);
            DeliveryReceiptRequest.addTo(xmppMessage);

            StandardExtensionElement timeElement = StandardExtensionElement.builder(Constants.TIME, Constants.URN_XMPP_TIME)
                    .addElement(Constants.TS, time).build();
            xmppMessage.addExtension(timeElement);

            StandardExtensionElement element = StandardExtensionElement.builder(Constants.CUSTOM, Constants.URN_XMPP_CUSTOM)
                    .addElement(Constants.custom, customText).build();
            xmppMessage.addExtension(element);

            if (isDm) {
                xmppMessage.setTo(JidCreate.from(toJid));
                mConnection.sendStanza(xmppMessage);
            } else {
                EntityBareJid jid = JidCreate.entityBareFrom(toJid);
                xmppMessage.setTo(jid);
                EntityBareJid mucJid = (EntityBareJid) JidCreate.bareFrom(Utils.getRoomIdWithDomainName(toJid, mHost));
                MultiUserChat muc = multiUserChatManager.getMultiUserChat(mucJid);
                muc.sendMessage(xmppMessage);
            }

            Utils.addLogInStorage("Action: sentCustomMessageToServer, Content: " + xmppMessage.toXML(null).toString());

            Utils.printLog(" Sent custom message from: " + xmppMessage.toXML(null) + "  sent.");

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
                toJid = toJid + Constants.SYMBOL_COMPARE_JID + mHost;
            }

            Message deliveryMessage = new Message();
            deliveryMessage.setStanzaId(receiptId);
            deliveryMessage.setTo(JidCreate.from(toJid));

            DeliveryReceipt deliveryReceipt = new DeliveryReceipt(msgId);
            deliveryMessage.addExtension(deliveryReceipt);

            mConnection.sendStanza(deliveryMessage);

            Utils.addLogInStorage("Action: sentDeliveryReceiptToServer, Content: " + deliveryMessage.toXML(null).toString());

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void manageAddMembersInGroup(GROUP_ROLE groupRole, String groupName, ArrayList<String> membersJid) {

        try {

            List<Jid> jidList = new ArrayList<>();
            for (String memberJid : membersJid) {
                if (!memberJid.contains(mHost)) {
                    memberJid = memberJid + Constants.SYMBOL_COMPARE_JID + mHost;
                }
                Jid jid = JidCreate.from(memberJid);
                jidList.add(jid);
            }

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(Utils.getRoomIdWithDomainName(groupName, mHost)));
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
                    memberJid = memberJid + Constants.SYMBOL_COMPARE_JID + mHost;
                }
                Jid jid = JidCreate.from(memberJid);
                jidList.add(jid);
            }

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(Utils.getRoomIdWithDomainName(groupName, mHost)));
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

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(Utils.getRoomIdWithDomainName(groupName, mHost)));
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

    public static int getOnlineMemberCount(String groupName) {
        try {

            MultiUserChat muc = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(Utils.getRoomIdWithDomainName(groupName, mHost)));
            return muc.getOccupants().size();

        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public static long getLastSeen(String userJid) {
        long userLastActivity = Constants.RESULT_DEFAULT;
        try {
            LastActivityManager lastActivityManager = LastActivityManager.getInstanceFor(mConnection);
            LastActivity lastActivity = lastActivityManager.getLastActivity(JidCreate.from(Utils.getJidWithDomainName(userJid, mHost)));
            userLastActivity = lastActivity.lastActivity;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return userLastActivity;
    }

    public static HashMap<String, String> getPresence(String userJid) {
        HashMap<String, String> presenceMap = new HashMap<>();
        try {

            Presence presence = rosterConnection.getPresence(JidCreate.bareFrom(Utils.getJidWithDomainName(userJid, mHost)));
            presenceMap.put(Constants.TYPE, presence.getType().toString());
            presenceMap.put(Constants.MODE, presence.getMode().toString());

        } catch (Exception e) {
            e.printStackTrace();
        }
        return presenceMap;
    }

    public static List<String> getMyRosters() {
        List<String> muRosterList = new ArrayList<>();
        try {
            Set<RosterEntry> allRoster = rosterConnection.getEntries();
            for (RosterEntry rosterEntry : allRoster) {
                muRosterList.add(rosterEntry.toString());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return muRosterList;
    }

    public static void createRosterEntry(String userJid) {
        try {
            rosterConnection.createEntry(JidCreate.bareFrom(Utils.getJidWithDomainName(userJid, mHost)), userJid, null);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void disconnect() {

        Utils.printLog(" Disconnecting from server: " + mServiceName);

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
        Utils.printLog(" Connected Successfully: ");

        FlutterXmppConnectionService.sConnectionState = ConnectionState.CONNECTED;

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_FROM_JID, mUsername);
        intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, Constants.CONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, Constants.CONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, Constants.CONNECTED);
        mApplicationContext.sendBroadcast(intent);

    }

    @Override
    public void authenticated(XMPPConnection connection, boolean resumed) {
        Utils.printLog(" Flutter Authenticated Successfully: ");

        multiUserChatManager = MultiUserChatManager.getInstanceFor(connection);
        FlutterXmppConnectionService.sConnectionState = ConnectionState.CONNECTED;
//        showContactListActivityWhenAuthenticated();

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_FROM_JID, mUsername);
        intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, Constants.AUTHENTICATED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, Constants.AUTHENTICATED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, Constants.AUTHENTICATED);
        mApplicationContext.sendBroadcast(intent);

    }

    @Override
    public void connectionClosed() {
        Utils.printLog(" ConnectionClosed(): ");

        FlutterXmppConnectionService.sConnectionState = ConnectionState.DISCONNECTED;

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_FROM_JID, Constants.DISCONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, Constants.DISCONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, Constants.DISCONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, Constants.DISCONNECTED);
        mApplicationContext.sendBroadcast(intent);

    }

    @Override
    public void connectionClosedOnError(Exception e) {
        Utils.printLog(" ConnectionClosedOnError, error:  " + e.toString());

        FlutterXmppConnectionService.sConnectionState = ConnectionState.DISCONNECTED;

        //Bundle up the intent and send the broadcast.
        Intent intent = new Intent(Constants.RECEIVE_MESSAGE);
        intent.setPackage(mApplicationContext.getPackageName());
        intent.putExtra(Constants.BUNDLE_FROM_JID, Constants.DISCONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, Constants.DISCONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, Constants.DISCONNECTED);
        intent.putExtra(Constants.BUNDLE_MESSAGE_TYPE, Constants.DISCONNECTED);
        mApplicationContext.sendBroadcast(intent);

    }

    public static boolean createMUC(String groupName, String persistent) {

        boolean isGroupCreatedSuccessfully = false;
        try {

            MultiUserChat multiUserChat = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(Utils.getRoomIdWithDomainName(groupName, mHost)));
            multiUserChat.create(Resourcepart.from(mUsername));

            if (persistent.equals(Constants.TRUE)) {
                Form form = multiUserChat.getConfigurationForm();
                Form answerForm = form.createAnswerForm();
                answerForm.setAnswer(Constants.MUC_PERSISTENT_ROOM, true);
                answerForm.setAnswer(Constants.MUC_MEMBER_ONLY, true);
                multiUserChat.sendConfigurationForm(answerForm);
            }

            isGroupCreatedSuccessfully = true;

        } catch (Exception e) {
            e.printStackTrace();
        }
        return isGroupCreatedSuccessfully;

    }

    public static String joinAllGroups(ArrayList<String> allGroupsIds) {
        String response = "FAIL";
        for (String groupId : allGroupsIds) {
            try {

                String groupName = groupId;
                String lastMsgTime = "0";

                if (groupName.contains(",")) {
                    String[] groupData = groupName.split(",");
                    groupName = groupData[0];
                    lastMsgTime = groupData[1];
                }

                MultiUserChat multiUserChat = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(Utils.getRoomIdWithDomainName(groupName, mHost)));
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
            } catch (Exception e) {
                Utils.printLog(" exception: " + e.getLocalizedMessage());
                e.printStackTrace();
            }

        }
        response = Constants.SUCCESS;
        return response;
    }

    public static boolean joinGroupWithResponse(String groupId) {

        boolean isJoinedSuccessfully = false;
        try {

            String groupName = groupId;
            String lastMsgTime = "0";

            if (groupName.contains(",")) {
                String[] groupData = groupName.split(",");
                groupName = groupData[0];
                lastMsgTime = groupData[1];
            }

            MultiUserChat multiUserChat = multiUserChatManager.getMultiUserChat((EntityBareJid) JidCreate.from(Utils.getRoomIdWithDomainName(groupName, mHost)));
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

            isJoinedSuccessfully = true;
        } catch (Exception e) {
            Utils.printLog(" groupID : exception: " + e.getLocalizedMessage());
            e.printStackTrace();
        }

        return isJoinedSuccessfully;
    }

}
