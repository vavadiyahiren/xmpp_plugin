class MessageEvent {
  String? customText;
  String? from;
  String? senderJid;
  int? time;
  String? id;
  String? type;
  String? body;
  String? msgtype;
  String? bubbleType;
  String? mediaURL;
  String? presence;
  String? chatStateType;

  MessageEvent({
    this.customText,
    this.from,
    this.senderJid,
    this.time,
    this.id,
    this.type,
    this.body,
    this.msgtype,
    this.bubbleType,
    this.mediaURL,
    this.presence,
    this.chatStateType
  });

  Map<String, dynamic> toEventData() {
    return {
      'customText': customText,
      'from': from,
      'senderJid': senderJid,
      'time': time,
      'id': id,
      'type': type,
      'body': body,
      'msgtype': msgtype,
      'bubbleType': bubbleType,
      'mediaURL': mediaURL,
      'chatStateType': chatStateType
    };
  }

  factory MessageEvent.fromJson(dynamic eventData) {
    return MessageEvent(
      customText: eventData['customText'] ?? '',
      from: eventData['from'] ?? '',
      senderJid: eventData['senderJid'] ?? '',
      time: eventData['time'] ?? 0,
      id: eventData['id'] ?? '',
      type: eventData['type'] ?? '',
      body: eventData['body'] ?? '',
      msgtype: eventData['msgtype'] ?? '',
      bubbleType: eventData['bubbleType'] ?? '',
      mediaURL: eventData['mediaURL'] ?? '',
      presence: eventData['presence'] ?? '',
      chatStateType: eventData['chatStateType'] ?? '',
    );
  }
}
