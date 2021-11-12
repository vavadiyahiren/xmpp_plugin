class Event {
  String? from;
  String? senderJid;
  String? id;
  String? type;
  String? body;
  String? msgtype;
  String? customText;

  Event(
      {this.from,
      this.senderJid,
      this.id,
      this.type,
      this.body,
      this.msgtype,
      this.customText});

  Event.fromJson(dynamic json) {
    from = json["from"];
    senderJid = json["senderJid"];
    id = json["id"];
    type = json["type"];
    body = json["body"];
    msgtype = json["msgtype"];
    customText = json["customText"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["from"] = from;
    map["senderJid"] = senderJid;
    map["id"] = id;
    map["type"] = type;
    map["body"] = body;
    map["msgtype"] = msgtype;
    map["customText"] = customText;
    return map;
  }
}
