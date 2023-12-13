import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:xmpp_plugin/ennums/xmpp_connection_state.dart';
import 'package:xmpp_plugin/error_response_event.dart';
import 'package:xmpp_plugin/message_event.dart';
import 'package:xmpp_plugin/models/message_model.dart';
import 'package:xmpp_plugin/success_response_event.dart';

import 'models/chat_state_model.dart';
import 'models/connection_event.dart';
import 'models/present_mode.dart';

abstract class DataChangeEvents {
  void onChatMessage(MessageChat messageChat);

  void onGroupMessage(MessageChat messageChat);

  void onNormalMessage(MessageChat messageChat);

  void onPresenceChange(PresentModel message);

  void onChatStateChange(ChatState chatState);

  void onConnectionEvents(ConnectionEvent connectionEvent);

  void onSuccessEvent(SuccessResponseEvent successResponseEvent);

  void onXmppError(ErrorResponseEvent errorResponseEvent);
}

class XmppConnection {
  static const MethodChannel _channel = MethodChannel('flutter_xmpp/method');
  static const EventChannel _eventChannel = EventChannel('flutter_xmpp/stream');
  static const EventChannel _successEventChannel =
      EventChannel('flutter_xmpp/success_event_stream');
  static const EventChannel _connectionEventChannel =
      EventChannel('flutter_xmpp/connection_event_stream');
  static const EventChannel _errorEventChannel =
      EventChannel('flutter_xmpp/error_event_stream');
  static late StreamSubscription streamGetMsg;
  static late StreamSubscription successEventStream;
  static late StreamSubscription connectionEventStream;
  static late StreamSubscription errorEventStream;
  static List<DataChangeEvents> dataChangelist = <DataChangeEvents>[];

  dynamic auth;

  XmppConnection(this.auth);

  static void addListener(DataChangeEvents dataChangeA) {
    if (!dataChangelist.contains(dataChangeA)) {
      dataChangelist.add(dataChangeA);
    }
  }

  static void removeListener(DataChangeEvents dataChangeA) {
    if (dataChangelist.contains(dataChangeA)) {
      dataChangelist.remove(dataChangeA);
    }
  }

  static void removeAllListener(DataChangeEvents dataChangeA) {
    if (dataChangelist.isNotEmpty) {
      dataChangelist.clear();
    }
  }

  Future<void> login() async {
    await _channel.invokeMethod('login', auth);
  }

  Future<void> logout() async {
    await _channel.invokeMethod('logout');
  }

  Future<String> sendMessage(
      String toJid, String body, String id, int time) async {
    final params = {
      "to_jid": toJid,
      "body": body,
      "id": id,
      "time": time.toString(),
    };
    printLogForMethodCall('send_message', params);
    final String status = await _channel.invokeMethod('send_message', params);
    return status;
  }

  Future<String> sendMessageWithType(
    String toJid,
    String body,
    String id,
    int time,
  ) async {
    final params = {
      "to_jid": toJid,
      "body": body,
      "id": id,
      "time": time.toString(),
    };
    printLogForMethodCall('send_message', params);
    final String status = await _channel.invokeMethod('send_message', params);
    return status;
  }

  Future<String> sendGroupMessage(
      String toJid, String body, String id, int time) async {
    final params = {
      "to_jid": toJid,
      "body": body,
      "id": id,
      "time": time.toString(),
    };
    printLogForMethodCall('send_group_message', params);
    final String status =
        await _channel.invokeMethod('send_group_message', params);
    return status;
  }

  Future<String> sendGroupMessageWithType(
    String toJid,
    String body,
    String id,
    int time,
  ) async {
    final params = {
      "to_jid": toJid,
      "body": body,
      "id": id,
      "time": time.toString(),
    };
    printLogForMethodCall('send_group_message', params);
    final String status =
        await _channel.invokeMethod('send_group_message', params);
    return status;
  }

  Future<String> readMessage(String toJid, String id) async {
    final params = {"to_jid": toJid, "id": id};
    printLogForMethodCall('read_message', params);
    final String status = await _channel.invokeMethod('read_message', params);
    return status;
  }

  Future<void> start(Function _onError) async {
    streamGetMsg = _eventChannel.receiveBroadcastStream().listen(
      (dataEvent) {
        MessageEvent eventModel = MessageEvent.fromJson(dataEvent);
        MessageChat messageChat = MessageChat.fromJson(dataEvent);
        dataChangelist.forEach((element) {
          if (eventModel.msgtype == 'chat') {
            element.onChatMessage(messageChat);
          } else if (eventModel.msgtype == 'groupchat') {
            element.onGroupMessage(messageChat);
          } else if (eventModel.msgtype == 'normal') {
            element.onNormalMessage(messageChat);
          } else if (eventModel.type == 'presence') {
            PresentModel presentModel = PresentModel.fromJson(dataEvent);
            element.onPresenceChange(presentModel);
          } else if (eventModel.type == 'chatstate') {
            ChatState chatState = ChatState.fromJson(dataEvent);
            element.onChatStateChange(chatState);
          }
        });
      },
    );

    connectionEventStream = _connectionEventChannel
        .receiveBroadcastStream()
        .listen((connectionData) {
      ConnectionEvent connectionEvent =
          ConnectionEvent.fromJson(connectionData);
      dataChangelist.forEach((element) {
        element.onConnectionEvents(connectionEvent);
      });
    }, onError: _onError);

    successEventStream =
        _successEventChannel.receiveBroadcastStream().listen((successData) {
      SuccessResponseEvent eventModel =
          SuccessResponseEvent.fromJson(successData);
      print("success event ${eventModel.toSuccessResponseData()}");
      dataChangelist.forEach((element) {
        element.onSuccessEvent(eventModel);
      });
    }, onError: _onError);

    errorEventStream =
        _errorEventChannel.receiveBroadcastStream().listen((errorData) {
      ErrorResponseEvent eventModel = ErrorResponseEvent.fromJson(errorData);
      print("Error event ${eventModel.toErrorResponseData()}");
      dataChangelist.forEach((element) {
        element.onXmppError(eventModel);
      });
    }, onError: _onError);
  }

  Future<void> stop() async {
    streamGetMsg.cancel();
    successEventStream.cancel();
    errorEventStream.cancel();
    connectionEventStream.cancel();
  }

  /// Return: "SUCCESS" or "FAIL"
  Future<bool> createMUC(String name, bool persistent) async {
    final params = {"group_name": name, "persistent": "$persistent"};
    bool response = await _channel.invokeMethod('create_muc', params);
    print("createMUC response $response");
    return response;
  }

  /// Return: "TRUE" or "FALSE"
  Future<String> joinMucGroups(List<String> allGroupsId) async {
    if (allGroupsId.isNotEmpty) {
      final params = {
        "all_groups_ids": allGroupsId,
      };
      printLogForMethodCall('join_muc_groups', params);
      String response = await _channel.invokeMethod('join_muc_groups', params);
      print("joinMucGroups response $response");
      return response;
    }
    return "SUCCESS";
  }

  /// Return: "TRUE" or "FALSE"
  Future<bool> joinMucGroup(String groupID) async {
    final params = {
      "group_id": groupID,
    };
    printLogForMethodCall('join_muc_group', params);
    return await _channel.invokeMethod('join_muc_group', params);
  }

  Future<void> sendCustomMessage(String toJid, String body, String id,
      String customString, int time) async {
    final params = {
      "to_jid": toJid,
      "body": body,
      "id": id,
      "customText": customString,
      "time": time.toString(),
    };
    await _channel.invokeMethod('send_custom_message', params);
  }

  void printLogForMethodCall(String methodName, dynamic params) {
    log('call method to app from flutter methodName: $methodName: params: $params');
  }

  Future<void> sendCustomGroupMessage(String toJid, String body, String id,
      String customString, int time) async {
    final params = {
      "to_jid": toJid,
      "body": body,
      "id": id,
      "customText": customString,
      "time": time.toString(),
    };
    await _channel.invokeMethod('send_customgroup_message', params);
  }

  Future<void> sendDelieveryReceipt(
      String toJid, String msgId, String receiptID) async {
    final params = {"toJid": toJid, "msgId": msgId, "receiptId": receiptID};
    await _channel.invokeMethod('send_delivery_receipt', params);
  }

  Future<void> addMembersInGroup(String groupName, List<String> members) async {
    final params = {"group_name": groupName, "members_jid": members};
    await _channel.invokeMethod('add_members_in_group', params);
  }

  Future<void> addAdminsInGroup(
      String groupName, List<String> adminMembers) async {
    final params = {"group_name": groupName, "members_jid": adminMembers};
    await _channel.invokeMethod('add_admins_in_group', params);
  }

  Future<void> removeMember(String groupName, List<String> membersJid) async {
    final params = {"group_name": groupName, "members_jid": membersJid};
    print('checkGroups removeMember params: $params');
    await _channel.invokeMethod('remove_members_from_group', params);
  }

  Future<void> removeAdmin(String groupName, List<String> membersJid) async {
    final params = {"group_name": groupName, "members_jid": membersJid};
    print('checkGroups removeAdmin params: $params');
    await _channel.invokeMethod('remove_admins_from_group', params);
  }

  Future<void> addOwner(String groupName, List<String> membersJid) async {
    final params = {"group_name": groupName, "members_jid": membersJid};
    print('checkGroups addOwner params: $params');
    await _channel.invokeMethod('add_owners_in_group', params);
  }

  Future<void> removeOwner(String groupName, List<String> membersJid) async {
    final params = {"group_name": groupName, "members_jid": membersJid};
    print('checkGroups removeOwner params: $params');
    await _channel.invokeMethod('remove_owners_from_group', params);
  }

  Future<List<dynamic>> getOwners(String groupName) async {
    final params = {"group_name": groupName};
    print('group_name: $groupName');
    List<dynamic> owners = await _channel.invokeMethod('get_owners', params);
    print('checkGroups getOwners owners: $owners');
    return owners;
  }

  Future<int> getOnlineMemberCount(String groupName) async {
    final params = {"group_name": groupName};
    int memberCount =
        await _channel.invokeMethod('get_online_member_count', params);
    print('checkGroups getOccupantsSize: $memberCount');
    return memberCount;
  }

  Future<String> getLastSeen(String userJid) async {
    final params = {"user_jid": userJid};
    String lastSeenTime = await _channel.invokeMethod('get_last_seen', params);
    print('checkNewFeat getLastSeen lastSeenTime: $lastSeenTime');
    return lastSeenTime;
  }

  Future<void> createRoster(String userJid) async {
    final params = {"user_jid": userJid};
    await _channel.invokeMethod('create_roster', params);
    print('checkNewFeat create roster success');
  }

  Future<dynamic> getMyRosters() async {
    List<dynamic> myRosters = await _channel.invokeMethod('get_my_rosters');
    print('checkNewFeat getRosters myRosters: $myRosters');
    return myRosters;
  }

  Future<List<dynamic>> getMembers(String groupName) async {
    final params = {"group_name": groupName};
    print('group_name: $groupName');
    List<dynamic> members = await _channel.invokeMethod('get_members', params);
    print('checkGroups getMembers members: $members');
    return members;
  }

  Future<List<dynamic>> getAdmins(String groupName) async {
    final params = {"group_name": groupName};
    List<dynamic> admins = await _channel.invokeMethod('get_admins', params);
    print('checkGroups getAdmins admins: $admins');
    return admins;
  }

  Future<void> requestMamMessages(String userJid, String requestSince,
      String requestBefore, String limit) async {
    print(
        " Plugin : User Jid : $userJid , Request since : $requestSince , Request Before : $requestBefore, Limit : $limit ");
    final params = {
      "userJid": userJid,
      "requestBefore": requestBefore,
      "requestSince": requestSince,
      "limit": limit
    };
    await _channel.invokeMethod('request_mam', params);
  }

  Future<void> changeTypingStatus(
    String userJid,
    String typingstatus,
  ) async {
    print(" Plugin : User Jid : $userJid , Typing Status : $typingstatus ");
    final params = {
      "userJid": userJid,
      "typingStatus": typingstatus,
    };
    await _channel.invokeMethod('change_typing_status', params);
  }

  Future<void> changePresenceType(
      String presenceType, String presenceMode) async {
    print(
        " Plugin : presenceType : $presenceType , presenceMode : $presenceMode");
    final params = {"presenceType": presenceType, "presenceMode": presenceMode};
    await _channel.invokeMethod('change_presence_type', params);
  }

  Future<XmppConnectionState> getConnectionStatus() async {
    printLogForMethodCall('get_connection_status', '');
    String connectionState =
        await _channel.invokeMethod('get_connection_status');
    return connectionState.toConnectionState();
  }

  Future<String> currentState() async {
    printLogForMethodCall('current_state', {});
    final String state = await _channel.invokeMethod('current_state');
    return state;
  }
}
