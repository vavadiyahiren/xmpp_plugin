package org.xrstudio.xmpp.flutter_xmpp;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import androidx.annotation.NonNull;

import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnection;
import org.xrstudio.xmpp.flutter_xmpp.Connection.FlutterXmppConnectionService;
import org.xrstudio.xmpp.flutter_xmpp.Enum.ConnectionState;
import org.xrstudio.xmpp.flutter_xmpp.Enum.GroupRole;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Constants;
import org.xrstudio.xmpp.flutter_xmpp.Utils.Utils;
import org.xrstudio.xmpp.flutter_xmpp.managers.MAMManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class FlutterXmppPlugin implements MethodCallHandler, FlutterPlugin, ActivityAware, EventChannel.StreamHandler {

    public static final Boolean DEBUG = true;
    private static Context activity;
    private String id;
    private String time;
    private String body;
    private String to_jid;
    private String userJid;
    private String groupName;
    private String host = "";
    private String customString;
    private List<String> jidList;
    private String jid_user = "";
    private String password = "";
    private EventChannel event_channel;
    private ArrayList<String> membersJid;
    private MethodChannel method_channel;
    private EventChannel success_channel;
    private EventChannel error_channel;
    private EventChannel connection_channel;
    private BroadcastReceiver mBroadcastReceiver = null;
    private BroadcastReceiver successBroadcastReceiver = null;
    private BroadcastReceiver errorBroadcastReceiver = null;
    private BroadcastReceiver connectionBroadcastReceiver = null;
    private boolean requireSSLConnection = false, autoDeliveryReceipt = false, automaticReconnection = true, useStreamManagement = true;

    private static BroadcastReceiver get_message(final EventChannel.EventSink events) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                switch (action) {

                    // Handle the connection events.
                    case Constants.CONNECTION_MESSAGE:

                        Map<String, Object> connectionBuild = new HashMap<>();
                        connectionBuild.put(Constants.TYPE, Constants.CONNECTION);
                        connectionBuild.put(Constants.STATUS, Constants.connected);

                        Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + connectionBuild.toString());

                        events.success(connectionBuild);
                        break;

                    // Handle the auth status events.
                    case Constants.AUTH_MESSAGE:

                        Map<String, Object> authBuild = new HashMap<>();
                        authBuild.put(Constants.TYPE, Constants.CONNECTION);
                        authBuild.put(Constants.STATUS, Constants.authenticated);

                        Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + authBuild.toString());

                        events.success(authBuild);
                        break;

                    // Handle receiving message events.
                    case Constants.RECEIVE_MESSAGE:

                        String from = intent.getStringExtra(Constants.BUNDLE_FROM_JID);
                        String body = intent.getStringExtra(Constants.BUNDLE_MESSAGE_BODY);
                        String msgId = intent.getStringExtra(Constants.BUNDLE_MESSAGE_PARAMS);
                        String type = intent.getStringExtra(Constants.BUNDLE_MESSAGE_TYPE);
                        String customText = intent.getStringExtra(Constants.CUSTOM_TEXT);
                        String metaInfo = intent.getStringExtra(Constants.META_TEXT);
                        String senderJid = intent.hasExtra(Constants.BUNDLE_MESSAGE_SENDER_JID) ? intent.getStringExtra(Constants.BUNDLE_MESSAGE_SENDER_JID) : "";
                        String time = intent.hasExtra(Constants.time) ? intent.getStringExtra(Constants.time) : Constants.ZERO;
                        String chatStateType = intent.hasExtra(Constants.CHATSTATE_TYPE) ? intent.getStringExtra(Constants.CHATSTATE_TYPE) : Constants.EMPTY;
                        String delayTime = intent.hasExtra(Constants.DELAY_TIME) ? intent.getStringExtra(Constants.DELAY_TIME) : Constants.ZERO;

                        Map<String, Object> build = new HashMap<>();
                        build.put(Constants.TYPE, metaInfo);
                        build.put(Constants.ID, msgId);
                        build.put(Constants.FROM, from);
                        build.put(Constants.BODY, body);
                        build.put(Constants.MSG_TYPE, type);
                        build.put(Constants.SENDER_JID, senderJid);
                        build.put(Constants.CUSTOM_TEXT, customText);
                        build.put(Constants.time, time);
                        build.put(Constants.CHATSTATE_TYPE, chatStateType);
                        build.put(Constants.DELAY_TIME, delayTime);

                        Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + build.toString());
                        Log.d("TAG", " RECEIVE_MESSAGE-->> " + build.toString());

                        events.success(build);

                        break;

                    // Handle the sending message events.
                    case Constants.OUTGOING_MESSAGE:

                        String to = intent.getStringExtra(Constants.BUNDLE_TO_JID);
                        String bodyTo = intent.getStringExtra(Constants.BUNDLE_MESSAGE_BODY);
                        String idOutgoing = intent.getStringExtra(Constants.BUNDLE_MESSAGE_PARAMS);
                        String typeTo = intent.getStringExtra(Constants.BUNDLE_MESSAGE_TYPE);

                        Map<String, Object> buildTo = new HashMap<>();
                        buildTo.put(Constants.TYPE, Constants.OUTGOING);
                        buildTo.put(Constants.ID, idOutgoing);
                        buildTo.put(Constants.TO, to);
                        buildTo.put(Constants.BODY, bodyTo);
                        buildTo.put(Constants.MSG_TYPE, typeTo);

                        events.success(buildTo);

                        break;

                    // Handle the auth status events.

                    case Constants.PRESENCE_MESSAGE:

                        String jid = intent.getStringExtra(Constants.BUNDLE_FROM_JID);
                        String presenceType = intent.getStringExtra(Constants.BUNDLE_PRESENCE_TYPE);
                        String presenceMode = intent.getStringExtra(Constants.BUNDLE_PRESENCE_MODE);

                        Map<String, Object> presenceBuild = new HashMap<>();
                        presenceBuild.put(Constants.TYPE, Constants.PRESENCE);
                        presenceBuild.put(Constants.FROM, jid);
                        presenceBuild.put(Constants.PRESENCE_TYPE, presenceType);
                        presenceBuild.put(Constants.PRESENCE_MODE, presenceMode);

                        Utils.printLog("presenceBuild: " + presenceBuild);

                        events.success(presenceBuild);
                        break;

                }
            }
        };
    }

    // Sending a message to one-one chat.
    public static void sendMessage(String body, String toUser, String msgId, String method, String time) {

        if (FlutterXmppConnectionService.getState().equals(ConnectionState.AUTHENTICATED)) {

            if (method.equals(Constants.SEND_GROUP_MESSAGE)) {
                Intent intent = new Intent(Constants.GROUP_SEND_MESSAGE);
                intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, body);
                intent.putExtra(Constants.BUNDLE_TO, toUser);
                intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, msgId);
                intent.putExtra(Constants.BUNDLE_MESSAGE_SENDER_TIME, time);

                activity.sendBroadcast(intent);
            } else {
                Intent intent = new Intent(Constants.X_SEND_MESSAGE);
                intent.putExtra(Constants.BUNDLE_MESSAGE_BODY, body);
                intent.putExtra(Constants.BUNDLE_TO, toUser);
                intent.putExtra(Constants.BUNDLE_MESSAGE_PARAMS, msgId);
                intent.putExtra(Constants.BUNDLE_MESSAGE_SENDER_TIME, time);

                activity.sendBroadcast(intent);
            }
        }
    }

    public static void sendCustomMessage(String body, String toUser, String msgId, String customText, String time) {
        FlutterXmppConnection.sendCustomMessage(body, toUser, msgId, customText, true, time);
    }

    public static void sendCustomGroupMessage(String body, String toUser, String msgId, String customText, String time) {
        FlutterXmppConnection.sendCustomMessage(body, toUser, msgId, customText, false, time);
    }

    private static BroadcastReceiver getSuccessBroadCast(final EventChannel.EventSink events) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                switch (action) {

                    case Constants.SUCCESS_MESSAGE:

                        String successType = intent.getStringExtra(Constants.BUNDLE_SUCCESS_TYPE);
                        String from = intent.getStringExtra(Constants.FROM);

                        Map<String, Object> successBuild = new HashMap<>();
                        successBuild.put(Constants.TYPE, successType);
                        successBuild.put(Constants.FROM, from);

                        Utils.addLogInStorage("Action: sentSuccessMessageToFlutter, Content: " + successBuild.toString());

                        events.success(successBuild);
                        break;

                }
            }
        };
    }

    private static BroadcastReceiver getErrorBroadCast(final EventChannel.EventSink errorEvents) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                switch (action) {

                    case Constants.ERROR_MESSAGE:

                        String from = intent.getStringExtra(Constants.FROM);
                        String error = intent.getStringExtra(Constants.BUNDLE_EXCEPTION);
                        String errorType = intent.getStringExtra(Constants.BUNDLE_ERROR_TYPE);

                        Map<String, Object> errorBuild = new HashMap<>();
                        errorBuild.put(Constants.FROM, from);
                        errorBuild.put(Constants.EXCEPTION, error);
                        errorBuild.put(Constants.TYPE, errorType);

                        Utils.addLogInStorage("Action: sentErrorMessageToFlutter, Content: " + errorBuild.toString());

                        errorEvents.success(errorBuild);
                        break;

                }
            }
        };
    }

    private static BroadcastReceiver getConnectionBroadCast(final EventChannel.EventSink connectionEvents) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                switch (action) {

                    case Constants.CONNECTION_STATE_MESSAGE:

                        String connectionType = intent.getStringExtra(Constants.BUNDLE_CONNECTION_TYPE);
                        String connectionError = intent.getStringExtra(Constants.BUNDLE_CONNECTION_ERROR);

                        Map<String, Object> connectionStateBuild = new HashMap<>();
                        connectionStateBuild.put(Constants.TYPE, connectionType);
                        connectionStateBuild.put(Constants.ERROR, connectionError);

                        Utils.addLogInStorage("Action: sentConnectionMessageToFlutter, Content: " + connectionStateBuild.toString());

                        connectionEvents.success(connectionStateBuild);
                        break;

                }
            }
        };
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        method_channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), Constants.CHANNEL);
        method_channel.setMethodCallHandler(this);
        event_channel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), Constants.CHANNEL_STREAM);
        event_channel.setStreamHandler(this);

        success_channel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), Constants.CHANNEL_SUCCESS_EVENT_STREAM);
        success_channel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object args, EventChannel.EventSink events) {
                if (successBroadcastReceiver == null) {
                    Utils.printLog(" adding success listener: ");
                    successBroadcastReceiver = getSuccessBroadCast(events);
                    IntentFilter filter = new IntentFilter();
                    filter.addAction(Constants.SUCCESS_MESSAGE);
                    activity.registerReceiver(successBroadcastReceiver, filter, Context.RECEIVER_EXPORTED);
                }
            }

            @Override
            public void onCancel(Object o) {
                if (successBroadcastReceiver != null) {
                    Utils.printLog(" cancelling success listener: ");
                    activity.unregisterReceiver(successBroadcastReceiver);
                    successBroadcastReceiver = null;
                }
            }
        });

        error_channel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), Constants.CHANNEL_ERROR_EVENT_STREAM);
        error_channel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object args, EventChannel.EventSink errorEvents) {
                if (errorBroadcastReceiver == null) {
                    Utils.printLog(" adding error listener: ");
                    errorBroadcastReceiver = getErrorBroadCast(errorEvents);
                    IntentFilter filter = new IntentFilter();
                    filter.addAction(Constants.ERROR_MESSAGE);
                    activity.registerReceiver(errorBroadcastReceiver, filter, Context.RECEIVER_EXPORTED);
                }
            }

            @Override
            public void onCancel(Object o) {
                if (errorBroadcastReceiver != null) {
                    Utils.printLog(" cancelling error listener: ");
                    activity.unregisterReceiver(errorBroadcastReceiver);
                    errorBroadcastReceiver = null;
                }
            }
        });

        connection_channel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), Constants.CHANNEL_CONNECTION_EVENT_STREAM);
        connection_channel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object args, EventChannel.EventSink connectionEvents) {
                if (connectionBroadcastReceiver == null) {
                    Utils.printLog(" adding connection listener: ");
                    connectionBroadcastReceiver = getConnectionBroadCast(connectionEvents);
                    IntentFilter filter = new IntentFilter();
                    filter.addAction(Constants.CONNECTION_STATE_MESSAGE);
                    activity.registerReceiver(connectionBroadcastReceiver, filter, Context.RECEIVER_EXPORTED);
                }
            }

            @Override
            public void onCancel(Object o) {
                if (connectionBroadcastReceiver != null) {
                    Utils.printLog(" cancelling connection listener: ");
                    activity.unregisterReceiver(connectionBroadcastReceiver);
                    connectionBroadcastReceiver = null;
                }
            }
        });

    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // The Activity your plugin was associated with has been
        // destroyed due to config changes. It will be right back
        // but your plugin must clean up any references to that
        // Activity and associated resources.
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        // Your plugin is now associated with a new Activity instance
        // after config changes took place. You may now re-establish
        // a reference to the Activity and associated resources.
    }

    @Override
    public void onDetachedFromActivity() {
        // Your plugin is no longer associated with an Activity.
        // You must clean up all resources and references. Your
        // plugin may, or may not ever be associated with an Activity
        // again.
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        // Your plugin is now associated with an Android Activity.
        //
        // If this method is invoked, it is always invoked after
        // onAttachedToFlutterEngine().
        //
        // You can obtain an Activity reference with

        activity = binding.getActivity();

        //
        // You can listen for Lifecycle changes with
        // binding.getLifecycle()
        //
        // You can listen for Activity results, new Intents, user
        // leave hints, and state saving callbacks by using the
        // appropriate methods on the binding.
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        logout();
        method_channel.setMethodCallHandler(null);
        Utils.printLog(" onDetachedFromEngine: ");
    }

    // stream
    @Override
    public void onListen(Object auth, EventChannel.EventSink eventSink) {

        if (mBroadcastReceiver == null) {
            Utils.printLog(" adding listener: ");
            mBroadcastReceiver = get_message(eventSink);
            IntentFilter filter = new IntentFilter();
            filter.addAction(Constants.RECEIVE_MESSAGE);
            filter.addAction(Constants.OUTGOING_MESSAGE);
            filter.addAction(Constants.PRESENCE_MESSAGE);
            activity.registerReceiver(mBroadcastReceiver, filter, Context.RECEIVER_EXPORTED);
        }

    }

    @Override
    public void onCancel(Object o) {

        if (mBroadcastReceiver != null) {
            Utils.printLog(" cancelling listener: ");
            activity.unregisterReceiver(mBroadcastReceiver);
            mBroadcastReceiver = null;
        }

    }

    // Handles the call invocation from the flutter plugin
    @Override
    public void onMethodCall(MethodCall call, Result result) {

        Utils.printLog(" onMethodCall call: " + call.method);
        // Check if login method was called.

        Utils.addLogInStorage("Action: methodReceiveFromFlutter, NativeMethod: " + call.method.toString() + " Content: " + call.arguments + "");

        switch (call.method) {

            case Constants.LOGIN:

                if (!call.hasArgument(Constants.USER_JID) || !call.hasArgument(Constants.PASSWORD) || !call.hasArgument(Constants.HOST)) {
                    result.error("MISSING", "Missing auth.", null);
                }

                jid_user = call.argument(Constants.USER_JID).toString();
                password = call.argument(Constants.PASSWORD).toString();
                host = call.argument(Constants.HOST).toString();
                if (call.hasArgument(Constants.PORT)) {
                    Constants.PORT_NUMBER = Integer.parseInt(call.argument(Constants.PORT).toString());
                }

                if (call.hasArgument(Constants.NAVIGATE_FILE_PATH)) {
                    Utils.logFilePath = call.argument(Constants.NAVIGATE_FILE_PATH).toString();
                }

                if (call.hasArgument(Constants.AUTO_DELIVERY_RECEIPT)) {
                    autoDeliveryReceipt = call.argument(Constants.AUTO_DELIVERY_RECEIPT);
                }

                if (call.hasArgument(Constants.REQUIRE_SSL_CONNECTION)) {
                    requireSSLConnection = call.argument(Constants.REQUIRE_SSL_CONNECTION);
                }

                if (call.hasArgument(Constants.AUTOMATIC_RECONNECTION)) {
                    automaticReconnection = call.argument(Constants.AUTOMATIC_RECONNECTION);
                }

                if (call.hasArgument(Constants.USER_STREAM_MANAGEMENT)) {
                    useStreamManagement = call.argument(Constants.USER_STREAM_MANAGEMENT);
                }

                // Start authentication.
                doLogin();

                result.success(Constants.SUCCESS);
                break;

            case Constants.LOGOUT:
                // Doing logout from xmpp.
                logout();
                result.success(Constants.SUCCESS);
                break;

            case Constants.SEND_MESSAGE:
            case Constants.SEND_GROUP_MESSAGE:
                // Handle sending message.
                if (!call.hasArgument(Constants.TO_JID) || !call.hasArgument(Constants.BODY) || !call.hasArgument(Constants.ID)) {
                    result.error("MISSING", "Missing argument to_jid / body / id chat.", null);
                }

                to_jid = call.argument(Constants.TO_JID);
                body = call.argument(Constants.BODY);
                id = call.argument(Constants.ID);
                time = Constants.ZERO;

                if (call.hasArgument(Constants.time)) {
                    time = call.argument(Constants.time);
                }

                sendMessage(body, to_jid, id, call.method, time);

                result.success(Constants.SUCCESS);
                break;

            case Constants.JOIN_MUC_GROUPS:

                if (!call.hasArgument(Constants.ALL_GROUPS_IDS)) {
                    result.error("MISSING", "Missing argument all_groups_ids.", null);
                }
                ArrayList<String> allGroupsIds = call.argument(Constants.ALL_GROUPS_IDS);

                String response = FlutterXmppConnection.joinAllGroups(allGroupsIds);
                result.success(response);
                break;

            case Constants.JOIN_MUC_GROUP:

                boolean isJoined = false;
                if (!call.hasArgument(Constants.GROUP_ID)) {
                    result.error("MISSING", "Missing argument group_id.", null);
                }
                String group_id = call.argument(Constants.GROUP_ID);

                if (!group_id.isEmpty()) {
                    isJoined = FlutterXmppConnection.joinGroupWithResponse(group_id);
                }
                result.success(isJoined);
                break;

            case Constants.CREATE_MUC:

                String group_name = call.argument(Constants.GROUP_NAME);
                String persistent = call.argument(Constants.PERSISTENT);

                boolean responses = FlutterXmppConnection.createMUC(group_name, persistent);
                result.success(responses);
                break;

            case Constants.CUSTOM_MESSAGE:
                // Handle sending message.
                if (!call.hasArgument(Constants.TO_JID) || !call.hasArgument(Constants.BODY) || !call.hasArgument(Constants.ID)) {
                    result.error("MISSING", "Missing argument to_jid / body / id chat.", null);
                }

                to_jid = call.argument(Constants.TO_JID);
                body = call.argument(Constants.BODY);
                id = call.argument(Constants.ID);
                customString = call.argument(Constants.CUSTOM_TEXT);
                time = Constants.ZERO;

                if (call.hasArgument(Constants.time)) {
                    time = call.argument(Constants.time);
                }

                sendCustomMessage(body, to_jid, id, customString, time);

                result.success(Constants.SUCCESS);
                break;

            case Constants.CUSTOM_GROUP_MESSAGE:
                // Handle sending message.
                if (!call.hasArgument(Constants.TO_JID) || !call.hasArgument(Constants.BODY) || !call.hasArgument(Constants.ID)) {
                    result.error("MISSING", "Missing argument to_jid / body / id chat.", null);
                }

                to_jid = call.argument(Constants.TO_JID);
                body = call.argument(Constants.BODY);
                id = call.argument(Constants.ID);
                customString = call.argument(Constants.CUSTOM_TEXT);
                time = Constants.ZERO;

                if (call.hasArgument(Constants.time)) {
                    time = call.argument(Constants.time);
                }

                sendCustomGroupMessage(body, to_jid, id, customString, time);

                result.success(Constants.SUCCESS);
                break;

            case Constants.SEND_DELIVERY_ACK:

                String toJid = call.argument(Constants.TO_JID_1);
                String msgId = call.argument(Constants.MESSAGE_ID);
                String receiptId = call.argument(Constants.RECEIPT_ID);

                FlutterXmppConnection.send_delivery_receipt(toJid, msgId, receiptId);

                result.success(Constants.SUCCESS);
                break;

            case Constants.ADD_MEMBERS_IN_GROUP:

                groupName = call.argument(Constants.GROUP_NAME);
                membersJid = call.argument(Constants.MEMBERS_JID);

                FlutterXmppConnection.manageAddMembersInGroup(GroupRole.MEMBER, groupName, membersJid);

                result.success(Constants.SUCCESS);
                break;

            case Constants.ADD_ADMINS_IN_GROUP:

                groupName = call.argument(Constants.GROUP_NAME);
                membersJid = call.argument(Constants.MEMBERS_JID);

                FlutterXmppConnection.manageAddMembersInGroup(GroupRole.ADMIN, groupName, membersJid);

                result.success(Constants.SUCCESS);
                break;

            case Constants.REMOVE_MEMBERS_FROM_GROUP:

                groupName = call.argument(Constants.GROUP_NAME);
                membersJid = call.argument(Constants.MEMBERS_JID);

                FlutterXmppConnection.manageRemoveFromGroup(GroupRole.MEMBER, groupName, membersJid);

                result.success(Constants.SUCCESS);
                break;

            case Constants.REMOVE_ADMINS_FROM_GROUP:

                groupName = call.argument(Constants.GROUP_NAME);
                membersJid = call.argument(Constants.MEMBERS_JID);

                FlutterXmppConnection.manageRemoveFromGroup(GroupRole.ADMIN, groupName, membersJid);

                result.success(Constants.SUCCESS);
                break;

            case Constants.ADD_OWNERS_IN_GROUP:

                groupName = call.argument(Constants.GROUP_NAME);
                membersJid = call.argument(Constants.MEMBERS_JID);

                FlutterXmppConnection.manageAddMembersInGroup(GroupRole.OWNER, groupName, membersJid);

                result.success(Constants.SUCCESS);
                break;

            case Constants.REMOVE_OWNERS_FROM_GROUP:

                groupName = call.argument(Constants.GROUP_NAME);
                membersJid = call.argument(Constants.MEMBERS_JID);

                FlutterXmppConnection.manageRemoveFromGroup(GroupRole.OWNER, groupName, membersJid);

                result.success(Constants.SUCCESS);
                break;

            case Constants.GET_OWNERS:

                groupName = call.argument(Constants.GROUP_NAME);
                jidList = FlutterXmppConnection.getMembersOrAdminsOrOwners(GroupRole.OWNER, groupName);
                result.success(jidList);
                break;

            case Constants.GET_ADMINS:

                groupName = call.argument(Constants.GROUP_NAME);
                jidList = FlutterXmppConnection.getMembersOrAdminsOrOwners(GroupRole.ADMIN, groupName);
                result.success(jidList);
                break;

            case Constants.GET_MAM:

                String userJid = call.argument(Constants.userJid);
                String requestBefore = call.argument(Constants.requestBefore);
                String requestSince = call.argument(Constants.requestSince);
                String limit = call.argument(Constants.limit);
                Utils.printLog("userJId " + userJid + " Before : " + requestBefore + " since " + requestSince + " limit " + limit);
                MAMManager.requestMAM(userJid, requestBefore, requestSince, limit);
                result.success("SUCCESS");

                break;

            case Constants.CHANGE_TYPING_STATUS:

                String typingJid = call.argument(Constants.userJid);
                String typingStatus = call.argument(Constants.typingStatus);
                Utils.printLog("userJId " + typingJid + " Typing Status : " + typingStatus);
                FlutterXmppConnection.updateChatState(typingJid, typingStatus);
                result.success("SUCCESS");
                break;

            case Constants.CHANGE_PRESENCE_TYPE:

                String presenceType = call.argument(Constants.PRESENCE_TYPE);
                String presenceMode = call.argument(Constants.PRESENCE_MODE);
                Utils.printLog("presenceType : " + presenceType + " , Presence Mode : " + presenceMode);
                FlutterXmppConnection.updatePresence(presenceType, presenceMode);
                result.success("SUCCESS");
                break;

            case Constants.GET_CONNECTION_STATUS:

                ConnectionState connectionStatus = FlutterXmppConnectionService.getState();
                result.success(connectionStatus.toString());
                break;

            case Constants.GET_MEMBERS:

                groupName = call.argument(Constants.GROUP_NAME);
                jidList = FlutterXmppConnection.getMembersOrAdminsOrOwners(GroupRole.MEMBER, groupName);
                result.success(jidList);
                break;

            case Constants.CURRENT_STATE:

                String state = Constants.STATE_UNKNOWN;
                switch (FlutterXmppConnectionService.getState()) {
                    case CONNECTED:
                        state = Constants.STATE_CONNECTED;
                        break;
                    case AUTHENTICATED:
                        state = Constants.STATE_AUTHENTICATED;
                        break;
                    case CONNECTING:
                        state = Constants.STATE_CONNECTING;
                        break;
                    case DISCONNECTING:
                        state = Constants.STATE_DISCONNECTING;
                        break;
                    case DISCONNECTED:
                        state = Constants.STATE_DISCONNECTED;
                        break;
                }
                result.success(state);
                break;

            case Constants.GET_ONLINE_MEMBER_COUNT:

                groupName = call.argument(Constants.GROUP_NAME);
                int occupantsSize = FlutterXmppConnection.getOnlineMemberCount(groupName);
                result.success(occupantsSize);
                break;

            case Constants.GET_LAST_SEEN:

                userJid = call.argument(Constants.USER_JID);
                long userLastActivity = FlutterXmppConnection.getLastSeen(userJid);
                result.success(userLastActivity + "");
                break;


            case Constants.GET_MY_ROSTERS:

                List<String> getMyRosters = FlutterXmppConnection.getMyRosters();
                result.success(getMyRosters);
                break;

            case Constants.CREATE_ROSTER:

                userJid = call.argument(Constants.USER_JID);
                FlutterXmppConnection.createRosterEntry(userJid);
                result.success(Constants.SUCCESS);
                break;

            default:
                result.notImplemented();
                break;
        }

    }

    // login
    private void doLogin() {
        // Check if the user is already connected or not ? if not then start login process.
        final ConnectionState connState = FlutterXmppConnectionService.getState();
        if (connState.equals(ConnectionState.DISCONNECTED) || connState.equals(ConnectionState.FAILED)) {
            Intent i = new Intent(activity, FlutterXmppConnectionService.class);
            i.putExtra(Constants.JID_USER, jid_user);
            i.putExtra(Constants.PASSWORD, password);
            i.putExtra(Constants.HOST, host);
            i.putExtra(Constants.PORT, Constants.PORT_NUMBER);
            i.putExtra(Constants.AUTO_DELIVERY_RECEIPT, autoDeliveryReceipt);
            i.putExtra(Constants.REQUIRE_SSL_CONNECTION, requireSSLConnection);
            i.putExtra(Constants.USER_STREAM_MANAGEMENT, useStreamManagement);
            i.putExtra(Constants.AUTOMATIC_RECONNECTION, automaticReconnection);
            activity.startService(i);
        }
    }

    private void logout() {
        // Check if user is connected to xmpp ? if yes then break connection.
        if (FlutterXmppConnectionService.getState().equals(ConnectionState.AUTHENTICATED)) {
            Intent i1 = new Intent(activity, FlutterXmppConnectionService.class);
            activity.stopService(i1);
        }
    }

}
