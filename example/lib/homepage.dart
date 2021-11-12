import 'package:flutter/material.dart';
import 'package:flutter_xmpp_example/main.dart';
import 'package:xmpp_plugin/xmpp_plugin.dart';

class HomePage extends StatefulWidget {
  final String groupName;
  Function(String, List<String>) addMembersInGroup;
  Function(String, List<String>) addAdminsInGroup;
  Function(String) getMembers;
  Function(String) getAdmins;

  HomePage(
      {required this.groupName,
      required this.addMembersInGroup,
      required this.addAdminsInGroup,
      required this.getMembers,
      required this.getAdmins});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _addmemberController = TextEditingController();
  TextEditingController _addadminController = TextEditingController();
  List<String?> addMemberList = [];
  List<String?> addAdminList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('HomePage'),
          backgroundColor: Colors.black,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Add Member',
                  textEditController: _addmemberController,
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await widget.addMembersInGroup(
                        widget.groupName, ["${_addmemberController.text}"]);
                  },
                  child: Text('Add Member'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                customTextField(
                  hintText: 'Add Admin',
                  textEditController: _addadminController,
                ),
                SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: () async {
                    await widget.addAdminsInGroup(
                        widget.groupName, ["${_addadminController.text}"]);
                  },
                  child: Text('Add Admin'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                  ),
                ),
                Divider(
                  color: Colors.black,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        widget.getMembers(widget.groupName);
                      },
                      child: Text('Get Member'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.black,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        widget.getAdmins(widget.groupName);
                      },
                      child: Text('Get Admin'),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ));
  }

  Future<ListView> _getMemberList(addMemberList) async {
    return ListView.builder(
        itemCount: addMemberList.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text("${addMemberList[i]}"),
          );
        });
  }

  Future<ListView> _getAdminList(addAdminList) async {
    return ListView.builder(
        itemCount: addAdminList.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text("${addAdminList[i]}"),
          );
        });
  }
}
