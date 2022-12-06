import 'package:flutter/material.dart';
import 'package:flutter_xmpp_example/main.dart';

class HomePage extends StatefulWidget {
  final String groupName;
  final Function(String, List<String>) addMembersInGroup;
  final Function(String, List<String>) addAdminsInGroup;
  final Function(String, List<String>) removeMember;
  final Function(String, List<String>) removeAdmin;
  final Function(String, List<String>) addOwner;
  final Function(String, List<String>) removeOwner;
  final Function(String) getMembers;
  final Function(String) getAdmins;
  final Function(String) getOwners;
  final Function(String) getOnlineMemberCount;

  HomePage(
      {required this.groupName,
      required this.addMembersInGroup,
      required this.addAdminsInGroup,
      required this.removeMember,
      required this.removeAdmin,
      required this.addOwner,
      required this.removeOwner,
      required this.getMembers,
      required this.getOwners,
      required this.getAdmins,
      required this.getOnlineMemberCount});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _memberController = TextEditingController();
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
                hintText: 'Member Id',
                textEditController: _memberController,
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () async {
                  widget.addMembersInGroup(widget.groupName, ["${_memberController.text}"]);
                },
                child: Text('Add Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () async {
                  widget.addAdminsInGroup(widget.groupName, ["${_memberController.text}"]);
                },
                child: Text('Add Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
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
                      backgroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      widget.getAdmins(widget.groupName);
                    },
                    child: Text('Get Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.black,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      widget.removeMember(widget.groupName, ["${_memberController.text}"]);
                    },
                    child: Text('Remove Member'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      widget.removeAdmin(widget.groupName, ["${_memberController.text}"]);
                    },
                    child: Text('Remove admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.black,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      widget.addOwner(widget.groupName, ["${_memberController.text}"]);
                    },
                    child: Text('Add owner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      widget.removeOwner(widget.groupName, ["${_memberController.text}"]);
                    },
                    child: Text('Remove owner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
              Divider(
                color: Colors.black,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      widget.getOwners(widget.groupName);
                    },
                    child: Text('List owner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      widget.getOnlineMemberCount(widget.groupName);
                    },
                    child: Text('Get Occupants Size'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
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
      ),
    );
  }

  Future<ListView> _getMemberList(addMemberList) async {
    return ListView.builder(
      itemCount: addMemberList.length,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text("${addMemberList[i]}"),
        );
      },
    );
  }

  Future<ListView> _getAdminList(addAdminList) async {
    return ListView.builder(
      itemCount: addAdminList.length,
      itemBuilder: (context, i) {
        return ListTile(
          title: Text("${addAdminList[i]}"),
        );
      },
    );
  }
}
