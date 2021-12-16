import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/services.dart';

import 'custom_element.dart';

class XmppConnection {
  static const MethodChannel _channel = MethodChannel('flutter_xmpp/method');
  static const EventChannel _eventChannel = EventChannel('flutter_xmpp/stream');
  static late StreamSubscription streamGetMsg;

  dynamic auth;

  XmppConnection(this.auth);

  Future<void> login() async {
    print("futurelogin${auth}");
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

  Future<String> currentState() async {
    printLogForMethodCall('current_state', {});
    final String state = await _channel.invokeMethod('current_state');
    return state;
  }

  Future<void> start(void Function(dynamic) _onEvent, Function _onError) async {
    streamGetMsg = _eventChannel
        .receiveBroadcastStream()
        .listen(_onEvent, onError: _onError);
  }

  Future<void> stop() async {
    streamGetMsg.cancel();
  }

  /// Return: "SUCCESS" or "FAIL"
  Future<bool> createMUC(String name, bool persistent) async {
    final params = {"group_name": name, "persistent": "$persistent"};
    bool response = await _channel.invokeMethod('create_muc', params);
    print("createMUC response $response");
    return response;
  }

  /// Return: "SUCCESS" or "FAIL"
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

  Future<String> getPresence(String userJid) async {
    final params = {"user_jid": userJid};
    String presence = await _channel.invokeMethod('get_presence', params);
    print('checkNewFeat getPresence presence: $presence');
    return presence;
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
}
