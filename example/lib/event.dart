class Event {
  String? from;
  String? senderJid;
  String? id;
  String? type;
  String? body;
  String? msgtype;

  Event(
      {this.from, this.senderJid, this.id, this.type, this.body, this.msgtype});

  Event.fromJson(dynamic json) {
    from = json["from"];
    senderJid = json["senderJid"];
    id = json["id"];
    type = json["type"];
    body = json["body"];
    msgtype = json["msgtype"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["from"] = from;
    map["senderJid"] = senderJid;
    map["id"] = id;
    map["type"] = type;
    map["body"] = body;
    map["msgtype"] = msgtype;
    return map;
  }
}
