import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_xmpp/xmpp_plugin.dart';
import 'package:flutter_xmpp_example/event.dart';

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
      "port": '5222'
    };

    flutterXmpp = XmppConnection(auth);
    await flutterXmpp.start(_onReceiveMessage, _onError);
    await flutterXmpp.login();
  }

  Future<void> _onReceiveMessage(dynamic event) async {
    // TODO : Handle the receive event
    print("Event $event");
    events.add(Event.fromJson(event));

    Event e = Event.fromJson(event);

    if (e.msgtype == "connected") {
      connectionStatus = "connected";
    }
    if (e.msgtype == "Authenticated") {
      connectionStatus = "Authenticated";
    }
    if (e.msgtype == "disconnected") {
      connectionStatus = "disconnected";
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

  String dropdownvalue = 'Chat';
  var items = ['Chat', 'Group Chat'];

  TextEditingController _userNameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _hostController = TextEditingController();
  TextEditingController _createMUCNamecontroller = TextEditingController();
  TextEditingController _joinMUCTextController = TextEditingController();
  TextEditingController _joinTimeController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  TextEditingController _toNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                ElevatedButton(
                  onPressed: () async {
                    await createMUC("${_createMUCNamecontroller.text}", false);
                  },
                  child: Text('Create Group'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                  ),
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
