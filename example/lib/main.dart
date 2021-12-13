import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_xmpp_example/constants.dart';
import 'package:flutter_xmpp_example/event.dart';
import 'package:flutter_xmpp_example/homepage.dart';
import 'package:flutter_xmpp_example/native_log_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';
import 'package:xmpp_plugin/custom_element.dart';
import 'package:xmpp_plugin/xmpp_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static late XmppConnection flutterXmpp;
  List<Event> events = [];
  String connectionStatus = "Disconnected";

  Future<void> connect() async {
    final auth = {
      "user_jid":
          "${_userNameController.text}@${_hostController.text}/${Platform.isAndroid ? "Android" : "iOS"}",
      "password": "${_passwordController.text}",
      "host": "${_hostController.text}",
      "port": '5222',
      "nativeLogFilePath": NativeLogHelper.logFilePath
    };

    flutterXmpp = XmppConnection(auth);
    await flutterXmpp.start(_onReceiveMessage, _onError);
    await flutterXmpp.login();
  }

  @override
  void initState() {
    super.initState();
    checkStoragePermission();
  }

  void checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      final PermissionStatus _permissionStatus =
          await Permission.storage.request();
      if (_permissionStatus.isGranted) {
        String filePath = await NativeLogHelper().getDefaultLogFilePath();
        print('logFilePath: $filePath');
      } else {
        print('logFilePath: please allow permission');
      }
    } else {
      String filePath = await NativeLogHelper().getDefaultLogFilePath();
      print('logFilePath: $filePath');
    }
  }

  Future<void> _onReceiveMessage(dynamic event) async {
    // TODO : Handle the receive event
    print("Event $event");
    events.add(Event.fromJson(event));

    Event e = Event.fromJson(event);

    if (e.msgtype == "Connected") {
      connectionStatus = "Connected";
    }
    if (e.msgtype == "Authenticated") {
      connectionStatus = "Authenticated";
    }
    if (e.msgtype == "Disconnected") {
      connectionStatus = "Disconnected";
    }

    setState(
      () {},
    );
  }

  void _onError(Object error) {
    // TODO : Handle the Error event
  }

  Future<void> disconnectXMPP() async => await flutterXmpp.logout();

  Future<void> joinMucGroups(List<String> allGroupsId) async {
    await flutterXmpp.joinMucGroups(allGroupsId);
  }

  Future<void> addMembersInGroup(String groupName, List<String> members) async {
    await flutterXmpp.addMembersInGroup(groupName, members);
  }

  Future<void> addAdminsInGroup(
      String groupName, List<String> adminMembers) async {
    await flutterXmpp.addAdminsInGroup(groupName, adminMembers);
  }

  Future<void> getMembers(String groupName) async {
    await flutterXmpp.getMembers(groupName);
  }

  Future<void> getOwners(String groupName) async {
    await flutterXmpp.getOwners(groupName);
  }

  Future<void> getOnlineMemberCount(String groupName) async {
    await flutterXmpp.getOnlineMemberCount(groupName);
  }

  Future<void> removeMember(String groupName, List<String> membersJid) async {
    await flutterXmpp.removeMember(groupName, membersJid);
  }

  Future<void> removeAdmin(String groupName, List<String> membersJid) async {
    await flutterXmpp.removeAdmin(groupName, membersJid);
  }

  Future<void> addOwner(String groupName, List<String> membersJid) async {
    await flutterXmpp.addOwner(groupName, membersJid);
  }

  Future<void> removeOwner(String groupName, List<String> membersJid) async {
    await flutterXmpp.removeOwner(groupName, membersJid);
  }

  Future<void> getAdmins(String groupName) async {
    await flutterXmpp.getAdmins(groupName);
  }

  String dropdownvalue = 'Chat';
  var items = ['Chat', 'Group Chat'];

  TextEditingController _userNameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _hostController = TextEditingController();
  TextEditingController _createMUCNamecontroller = TextEditingController();

  TextEditingController _toReceiptController = TextEditingController();
  TextEditingController _msgIdController = TextEditingController();
  TextEditingController _userJidController = TextEditingController();
  TextEditingController _createRostersController = TextEditingController();
  TextEditingController _receiptIdController = TextEditingController();
  TextEditingController _joinMUCTextController = TextEditingController();
  TextEditingController _joinTimeController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  TextEditingController _custommessageController = TextEditingController();
  TextEditingController _toNameController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  List<CustomElement> customElements = [
    CustomElement(
        childBody: "test",
        childElement: "elem",
        elementName: "Name",
        elementNameSpace: "space")
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('XMPP Plugin'),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              onPressed: () async {
                await disconnectXMPP();
              },
              icon: Icon(Icons.power_settings_new),
            ),
            IconButton(
              onPressed: () async {
                if (await NativeLogHelper().isFileExist()) {
                  Share.shareFiles([NativeLogHelper.logFilePath]);
                } else {
                  if (_scaffoldKey.currentState != null) {
                    _scaffoldKey.currentState!.showSnackBar(
                        new SnackBar(content: new Text('File not found!')));
                  }
                }
              },
              icon: Icon(Icons.share),
            ),
            IconButton(
              onPressed: () async {
                if (await NativeLogHelper().isFileExist()) {
                  NativeLogHelper().deleteLogFile();
                } else {
                  if (_scaffoldKey.currentState != null) {
                    _scaffoldKey.currentState!.showSnackBar(
                        new SnackBar(content: new Text('File not found!')));
                  }
                }
              },
              icon: Icon(Icons.delete),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'User Name',
                  textEditController: _userNameController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Password',
                  textEditController: _passwordController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Host',
                  textEditController: _hostController,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (connectionStatus == 'Authenticated') {
                          await disconnectXMPP();
                        } else {
                          await connect();
                        }
                      },
                      child: Text(connectionStatus == 'Authenticated'
                          ? "Disconnect"
                          : "Connect"),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.black,
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text('$connectionStatus'),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Enter Group',
                  textEditController: _createMUCNamecontroller,
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () async {
                          await createMUC(
                              "${_createMUCNamecontroller.text}", true);
                        },
                        child: Text('Create Group'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 45,
                    ),
                    Builder(builder: (context) {
                      return Flexible(
                        child: ElevatedButton(
                          onPressed: () async {
                            await createMUC(
                                "${_createMUCNamecontroller.text}", true);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HomePage(
                                        groupName:
                                            _createMUCNamecontroller.text,
                                        addMembersInGroup: addMembersInGroup,
                                        addAdminsInGroup: addAdminsInGroup,
                                        removeMember: removeMember,
                                        removeAdmin: removeAdmin,
                                        addOwner: addOwner,
                                        removeOwner: removeOwner,
                                        getAdmins: getAdmins,
                                        getMembers: getMembers,
                                        getOwners: getOwners,
                                        getOnlineMemberCount:
                                            getOnlineMemberCount,
                                      )),
                            );
                          },
                          child: Text('Create Group & Manage'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.black,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Enter Group',
                  textEditController: _joinMUCTextController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Enter Last Message Timestamp',
                  textEditController: _joinTimeController,
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await joinMucGroups([
                      "${_joinMUCTextController.text},${_joinTimeController.text}"
                    ]);
                  },
                  child: Text('Join Group'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "To...",
                  textEditController: _toNameController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Message",
                  textEditController: _messageController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Custom Message",
                  textEditController: _custommessageController,
                ),
                SizedBox(
                  height: 10,
                ),
                DropdownButton(
                  value: dropdownvalue,
                  icon: Icon(Icons.keyboard_arrow_down),
                  items: items.map((String items) {
                    return DropdownMenuItem(
                      value: items,
                      child: Text(items),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      dropdownvalue = val.toString();
                    });
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        int id = DateTime.now().millisecondsSinceEpoch;
                        (dropdownvalue == "Chat")
                            ? await flutterXmpp.sendMessageWithType(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                              )
                            : await flutterXmpp.sendGroupMessageWithType(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                              );
                      },
                      child: Text(" Send "),
                      style: ElevatedButton.styleFrom(
                        primary: (dropdownvalue == "Chat")
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        int id = DateTime.now().millisecondsSinceEpoch;
                        (dropdownvalue == "Chat")
                            ? await flutterXmpp.sendCustomMessage(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                                "${_custommessageController.text}")
                            : await flutterXmpp.sendCustomGroupMessage(
                                "${_toNameController.text}",
                                "${_messageController.text}",
                                "$id",
                                "${_custommessageController.text}");
                      },
                      child: Text(" Send Custom Message "),
                      style: ElevatedButton.styleFrom(
                        primary: (dropdownvalue == "Chat")
                            ? Colors.black
                            : Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "To",
                  textEditController: _toReceiptController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Message Id",
                  textEditController: _msgIdController,
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "Enter Receipt Id",
                  textEditController: _receiptIdController,
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await flutterXmpp.sendDelieveryReceipt(
                      "${_toReceiptController.text}",
                      "${_msgIdController.text}",
                      "${_receiptIdController.text}",
                    );
                  },
                  child: Text(" Send Receipt "),
                  style: ElevatedButton.styleFrom(primary: Colors.black),
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: "User Jid",
                  textEditController: _userJidController,
                ),
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  onPressed: () async {
                    String lastSeenTime =
                        await flutterXmpp.getLastSeen(_userJidController.text);
                    print('lastSeen lastSeenTime: $lastSeenTime');
                    if (lastSeenTime.isNotEmpty) {
                      int last = int.parse(lastSeenTime);

                      if (last < Constants.RESULT_EMPTY) {
                        // online
                      } else if (last > Constants.RESULT_EMPTY) {
                        // not online but need to pass time
                        DateTime dateTime =
                            DateTime.fromMillisecondsSinceEpoch(last);
                      } else {
                        // away
                      }
                    } else {
                      // away
                    }
                  },
                  child: Text("Get Last activity"),
                  style: ElevatedButton.styleFrom(primary: Colors.black),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () async {
                          await flutterXmpp.getPresence(
                            "${_userJidController.text}",
                          );
                        },
                        child: Text(" Get Presence "),
                        style: ElevatedButton.styleFrom(primary: Colors.black),
                      ),
                    ),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: () async {
                          await flutterXmpp.getMyRosters();
                        },
                        child: Text(" Get MyRosters "),
                        style: ElevatedButton.styleFrom(primary: Colors.black),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                customTextField(
                  hintText: "Create MyRosters",
                  textEditController: _createRostersController,
                ),
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await flutterXmpp
                        .createRoster(_createRostersController.text);
                  },
                  child: Text("Create MyRosters"),
                  style: ElevatedButton.styleFrom(primary: Colors.black),
                ),
                SizedBox(
                  height: 15,
                ),
                Container(
                  height: 500,
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) => _buildMessage(index),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _buildMessage(int index) {
    Event event = events[index];

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "from: ${event.from}",
          ),
          Text(
            "id: ${event.id}",
          ),
          Text(
            "Type: ${event.type}",
          ),
          Text(
            "message: ${event.body}",
          ),
          Text(
            "msgtype: ${event.msgtype}",
          ),
          Text(
            "customText: ${event.customText}",
          ),
          Divider(
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  createMUC(String groupName, bool persistent) async {
    await flutterXmpp.createMUC(groupName, persistent);
  }
}

Widget customTextField({
  TextEditingController? textEditController,
  String? hintText,
}) {
  return TextField(
    controller: textEditController,
    cursorColor: Colors.black,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 16,
        color: Colors.grey.withOpacity(0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(5.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: BorderSide(
          color: Colors.grey,
        ),
      ),
    ),
    style: TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontWeight: FontWeight.w500,
    ),
  );
}
