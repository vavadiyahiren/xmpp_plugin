package org.xrstudio.xmpp.flutter_xmpp;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import androidx.annotation.NonNull;

public class FlutterXmppPlugin implements MethodCallHandler, FlutterPlugin,ActivityAware ,EventChannel.StreamHandler {

    public static final Boolean DEBUG = true;

    private static final String TAG = "flutter_xmpp";
    private static final String CHANNEL = "flutter_xmpp/method";
    private static final String CHANNEL_STREAM = "flutter_xmpp/stream";
    private static Context activity;
    private String jid_user = "";
    private String password = "";
    private String host = "";
    private Integer port = 5222;
    private BroadcastReceiver mBroadcastReceiver = null;
    private String current_stat = "STOP";

             private MethodChannel method_channel;
    private EventChannel event_channel ;

//    public static void registerWith(Registrar registrar) {
//
//        //method channel
//        final MethodChannel method_channel = new MethodChannel(registrar.messenger(), CHANNEL);
//        method_channel.setMethodCallHandler(new FlutterXmppPlugin(registrar.context()));
//
//        //event channel
//        final EventChannel event_channel = new EventChannel(registrar.messenger(), CHANNEL_STREAM);
//        event_channel.setStreamHandler(new FlutterXmppPlugin(registrar.context()));
//
//    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        method_channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL);
        method_channel.setMethodCallHandler(this);

        event_channel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_STREAM);
        event_channel.setStreamHandler(this);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        // The Activity your plugin was associated with has been
        // destroyed due to config changes. It will be right back
        // but your plugin must clean up any references to that
        // Activity and associated resources.
    }
    @Override
    public void onReattachedToActivityForConfigChanges(
            ActivityPluginBinding binding
    ) {
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

            this.activity = binding.getActivity();



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
        method_channel.setMethodCallHandler(null);
        System.out.println("onDetachedFromEngine");
    }


    private static BroadcastReceiver get_message(final EventChannel.EventSink events) {
        return new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                switch (action) {

                    // Handle the connection events.
                    case FlutterXmppConnectionService.CONNECTION_MESSAGE:

                        Map<String, Object> connectionBuild = new HashMap<>();
                        connectionBuild.put("type", "connection");
                        connectionBuild.put("status", "connected");

                        Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + connectionBuild.toString());

                        events.success(connectionBuild);
                        break;

                    // Handle the auth status events.
                    case FlutterXmppConnectionService.AUTH_MESSAGE:

                        Map<String, Object> authBuild = new HashMap<>();
                        authBuild.put("type", "connection");
                        authBuild.put("status", "authenticated");

                        Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + authBuild.toString());

                        events.success(authBuild);
                        break;

                    // Handle receiving message events.
                    case FlutterXmppConnectionService.RECEIVE_MESSAGE:

                        String from = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_FROM_JID);
                        String body = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY);
                        String msgId = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS);
                        String type = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE);
                        String customText = intent.getStringExtra(FlutterXmppConnectionService.CUSTOM_TEXT);
                        String metaInfo = intent.getStringExtra(FlutterXmppConnectionService.META_TEXT);
                        String senderJid = intent.hasExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_SENDER_JID)
                                ? intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_SENDER_JID) : "";
                        String time = intent.hasExtra(FlutterXmppConnectionService.TIME)
                                ? intent.getStringExtra(FlutterXmppConnectionService.TIME) : "0";

                        Map<String, Object> build = new HashMap<>();
                        build.put("type", metaInfo);
                        build.put("id", msgId);
                        build.put("from", from);
                        build.put("body", body);
                        build.put("msgtype", type);
                        build.put("senderJid", senderJid);
                        build.put("customText", customText);
                        build.put("time", time);

                        Utils.addLogInStorage("Action: sentMessageToFlutter, Content: " + build.toString());

                        events.success(build);

                        break;

                    // Handle the sending message events.
                    case FlutterXmppConnectionService.OUTGOING_MESSAGE:

                        String to = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_TO_JID);
                        String bodyTo = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY);
                        String idOutgoing = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS);
                        String typeTo = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_TYPE);

                        Map<String, Object> buildTo = new HashMap<>();
                        buildTo.put("type", "outgoing");
                        buildTo.put("id", idOutgoing);
                        buildTo.put("to", to);
                        buildTo.put("body", bodyTo);
                        buildTo.put("msgtype", typeTo);

                        events.success(buildTo);

                        break;

                    // Handle the auth status events.
                    case FlutterXmppConnectionService.PRESENCE_MESSAGE:

                        String jid = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_TO_JID);
                        String presence = intent.getStringExtra(FlutterXmppConnectionService.BUNDLE_PRESENCE);

                        Map<String, Object> presenceBuild = new HashMap<>();
                        presenceBuild.put("type", "presence");
                        presenceBuild.put("from", jid);
                        presenceBuild.put("presence", presence);

                        Log.d("presenceTest", "presenceBuild: " + presenceBuild);

                        events.success(presenceBuild);
                        break;

                }
            }
        };
    }

    // Sending a message to one-one chat.
    public static void send_message(String body, String toUser, String msgId, String method, String time) {

        if (FlutterXmppConnectionService.getState().equals(FlutterXmppConnection.ConnectionState.CONNECTED)) {

            if (method.equals("send_group_message")) {
                Intent intent = new Intent(FlutterXmppConnectionService.GROUP_SEND_MESSAGE);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, body);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_TO, toUser);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, msgId);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_SENDER_TIME, time);

                activity.sendBroadcast(intent);
            } else {
                Intent intent = new Intent(FlutterXmppConnectionService.SEND_MESSAGE);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_BODY, body);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_TO, toUser);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_PARAMS, msgId);
                intent.putExtra(FlutterXmppConnectionService.BUNDLE_MESSAGE_SENDER_TIME, time);

                activity.sendBroadcast(intent);
            }
        } else {
            //TODO : handle connection failure events.
        }
    }

    public static void send_custom_message(String body, String toUser, String msgId, String customText, String time) {
        FlutterXmppConnection.sendCustomMessage(body, toUser, msgId, customText, true, time);
    }

    public static void send_customgroup_message(String body, String toUser, String msgId, String customText, String time) {
        FlutterXmppConnection.sendCustomMessage(body, toUser, msgId, customText, false, time);
    }


    // ****************************************
    // stream
    @Override
    public void onListen(Object auth, EventChannel.EventSink eventSink) {

        if (mBroadcastReceiver == null) {
            if (DEBUG) {
                Log.w(TAG, "adding listener");
            }
            mBroadcastReceiver = get_message(eventSink);
            IntentFilter filter = new IntentFilter();
            filter.addAction(FlutterXmppConnectionService.RECEIVE_MESSAGE);
            filter.addAction(FlutterXmppConnectionService.OUTGOING_MESSAGE);
            filter.addAction(FlutterXmppConnectionService.PRESENCE_MESSAGE);
            activity.registerReceiver(mBroadcastReceiver, filter);
        }

    }

    @Override
    public void onCancel(Object o) {
        if (mBroadcastReceiver != null) {
            if (DEBUG) {
                Log.w(TAG, "cancelling listener");
            }
            activity.unregisterReceiver(mBroadcastReceiver);
            mBroadcastReceiver = null;
        }
    }

    // Handles the call invocation from the flutter plugin
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Log.d("loginTest", "onMethodCall call: " + call.method);
        // Check if login method was called.
        Utils.addLogInStorage("Action: methodReceiveFromFlutter, NativeMethod: " + call.method.toString() + " Content: " + call.arguments + "");
        if (call.method.equals("login")) {
            if (!call.hasArgument("user_jid") || !call.hasArgument("password") || !call.hasArgument("host")) {
                result.error("MISSING", "Missing auth.", null);
            }
            this.jid_user = call.argument("user_jid").toString();
            this.password = call.argument("password").toString();
            this.host = call.argument("host").toString();
            if (call.hasArgument("port")) {
                this.port = Integer.parseInt(call.argument("port").toString());
            }

            if (call.hasArgument("nativeLogFilePath")) {
                Utils.logFilePath = call.argument("nativeLogFilePath").toString();
            }

            // Start authentication.
            doLogin();

            result.success("SUCCESS");

        } else if (call.method.equals("logout")) {

            // Doing logout from xmpp.
            logout();
            result.success("SUCCESS");

        } else if (call.method.equals("send_message") || call.method.equals("send_group_message")) {

            // Handle sending message.
            if (!call.hasArgument("to_jid") || !call.hasArgument("body") || !call.hasArgument("id")) {
                result.error("MISSING", "Missing argument to_jid / body / id chat.", null);
            }

            String to_jid = call.argument("to_jid");
            String body = call.argument("body");
            String id = call.argument("id");
            String time = "0";

            if (call.hasArgument("time")) {
                time = call.argument("time");
            }

            send_message(body, to_jid, id, call.method, time);

            result.success("SUCCESS");

            // still development for group message
        } else if (call.method.equals("current_state")) {
            String state = "UNKNOWN";
            switch (FlutterXmppConnectionService.getState()) {
                case CONNECTED:
                    state = "CONNECTED";
                    break;
                case AUTHENTICATED:
                    state = "AUTHENTICATED";
                    break;
                case CONNECTING:
                    state = "CONNECTING";
                    break;
                case DISCONNECTING:
                    state = "DISCONNECTING";
                    break;
                case DISCONNECTED:
                    state = "DISCONNECTED";
                    break;
            }

            result.success(state);

        } else if (call.method.equals("join_muc_groups")) {

            if (!call.hasArgument("all_groups_ids")) {
                result.error("MISSING", "Missing argument all_groups_ids.", null);
            }
            ArrayList<String> allGroupsIds = call.argument("all_groups_ids");

            String response = joinAllGroups(allGroupsIds);
            result.success(response);


        } else if (call.method.equals("join_muc_group")) {

            boolean isJoined = false;
            if (!call.hasArgument("group_id")) {
                result.error("MISSING", "Missing argument group_id.", null);
            }
            String group_id = call.argument("group_id");

            if (!group_id.isEmpty()) {
                isJoined = joinGroup(group_id);
            }
            result.success(isJoined);

        } else if (call.method.equals(Constants.CREATE_MUC)) {

            String group_name = call.argument("group_name");
            String persistent = call.argument("persistent");

            boolean response = createMUC(group_name, persistent);
            result.success(response);

        } else if (call.method.equals(Constants.CUSTOM_MESSAGE)) {

            // Handle sending message.
            if (!call.hasArgument("to_jid") || !call.hasArgument("body") || !call.hasArgument("id")) {
                result.error("MISSING", "Missing argument to_jid / body / id chat.", null);
            }

            String to_jid = call.argument("to_jid");
            String body = call.argument("body");
            String id = call.argument("id");
            String customString = call.argument("customText");
            String time = "0";

            if (call.hasArgument("time")) {
                time = call.argument("time");
            }

            send_custom_message(body, to_jid, id, customString, time);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.CUSTOM_GROUP_MESSAGE)) {

            // Handle sending message.
            if (!call.hasArgument("to_jid") || !call.hasArgument("body") || !call.hasArgument("id")) {
                result.error("MISSING", "Missing argument to_jid / body / id chat.", null);
            }

            String to_jid = call.argument("to_jid");
            String body = call.argument("body");
            String id = call.argument("id");
            String customString = call.argument("customText");
            String time = "0";

            if (call.hasArgument("time")) {
                time = call.argument("time");
            }

            send_customgroup_message(body, to_jid, id, customString, time);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.SEND_DELIVERY_ACK)) {

            String toJid = call.argument("toJid");
            String msgId = call.argument("msgId");
            String receiptId = call.argument("receiptId");

            FlutterXmppConnection.send_delivery_receipt(toJid, msgId, receiptId);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.ADD_MEMBERS_IN_GROUP)) {

            String groupName = call.argument("group_name");
            ArrayList<String> membersJid = call.argument("members_jid");

            FlutterXmppConnection.manageAddMembersInGroup(GROUP_ROLE.MEMBER, groupName, membersJid);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.ADD_ADMINS_IN_GROUP)) {

            String groupName = call.argument("group_name");
            ArrayList<String> membersJid = call.argument("members_jid");

            FlutterXmppConnection.manageAddMembersInGroup(GROUP_ROLE.ADMIN, groupName, membersJid);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.REMOVE_MEMBERS_FROM_GROUP)) {

            String groupName = call.argument("group_name");
            ArrayList<String> membersJid = call.argument("members_jid");

            FlutterXmppConnection.manageRemoveFromGroup(GROUP_ROLE.MEMBER, groupName, membersJid);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.REMOVE_ADMINS_FROM_GROUP)) {

            String groupName = call.argument("group_name");
            ArrayList<String> membersJid = call.argument("members_jid");

            FlutterXmppConnection.manageRemoveFromGroup(GROUP_ROLE.ADMIN, groupName, membersJid);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.ADD_OWNERS_IN_GROUP)) {

            String groupName = call.argument("group_name");
            ArrayList<String> membersJid = call.argument("members_jid");

            FlutterXmppConnection.manageAddMembersInGroup(GROUP_ROLE.OWNER, groupName, membersJid);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.REMOVE_OWNERS_FROM_GROUP)) {

            String groupName = call.argument("group_name");
            ArrayList<String> membersJid = call.argument("members_jid");

            FlutterXmppConnection.manageRemoveFromGroup(GROUP_ROLE.OWNER, groupName, membersJid);

            result.success("SUCCESS");

        } else if (call.method.equals(Constants.GET_OWNERS)) {

            String groupName = call.argument("group_name");

            List<String> jidList = FlutterXmppConnection.getMembersOrAdminsOrOwners(GROUP_ROLE.OWNER, groupName);

            result.success(jidList);

        } else if (call.method.equals(Constants.GET_ADMINS)) {

            String groupName = call.argument("group_name");

            List<String> jidList = FlutterXmppConnection.getMembersOrAdminsOrOwners(GROUP_ROLE.ADMIN, groupName);

            result.success(jidList);

        } else if (call.method.equals(Constants.GET_MEMBERS)) {

            String groupName = call.argument("group_name");

            List<String> jidList = FlutterXmppConnection.getMembersOrAdminsOrOwners(GROUP_ROLE.MEMBER, groupName);

            result.success(jidList);

        } else if (call.method.equals(Constants.GET_ONLINE_MEMBER_COUNT)) {

            String groupName = call.argument("group_name");

            int occupantsSize = FlutterXmppConnection.getOnlineMemberCount(groupName);

            result.success(occupantsSize);

        } else if (call.method.equals(Constants.GET_LAST_SEEN)) {

            String userJid = call.argument("user_jid");

            long userLastActivity = FlutterXmppConnection.getLastSeen(userJid);
            result.success(userLastActivity + "");

        } else if (call.method.equals(Constants.GET_PRESENCE)) {

            String userJid = call.argument("user_jid");

            HashMap<String, String> getPresence = FlutterXmppConnection.getPresence(userJid);
            result.success(getPresence.toString());

        } else if (call.method.equals(Constants.GET_MY_ROSTERS)) {
            List<String> getMyRosters = FlutterXmppConnection.getMyRosters();
            result.success(getMyRosters);

        } else if (call.method.equals(Constants.CREATE_ROSTER)) {

            String userJid = call.argument("user_jid");

            FlutterXmppConnection.createRosterEntry(userJid);

            result.success("SUCCESS");

        } else {
            result.notImplemented();
        }
    }

    private boolean createMUC(String group_name, String persistent) {
        return FlutterXmppConnection.createMUC(group_name, persistent);
    }

    private String joinAllGroups(ArrayList<String> allGroupsIds) {
        return FlutterXmppConnection.joinAllGroups(allGroupsIds);
    }

    // login
    private void doLogin() {

        // Check if the user is already connected or not ? if not then start login process.
        if (FlutterXmppConnectionService.getState().equals(FlutterXmppConnection.ConnectionState.DISCONNECTED)) {
            Intent i = new Intent(activity, FlutterXmppConnectionService.class);
            i.putExtra("jid_user", jid_user);
            i.putExtra("password", password);
            i.putExtra("host", host);
            i.putExtra("port", port);
            activity.startService(i);
        }
    }

    private void logout() {
        // Check if user is connected to xmpp ? if yes then break connection.
        if (FlutterXmppConnectionService.getState().equals(FlutterXmppConnection.ConnectionState.CONNECTED)) {
            Intent i1 = new Intent(activity, FlutterXmppConnectionService.class);
            activity.stopService(i1);
        }
    }

    // Join the muc.
    private boolean joinGroup(String groupID) {
        return FlutterXmppConnection.joinGroupWithResponse(groupID);
    }

}