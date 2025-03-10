
class MessageEvent {
  String? customText;
  String? from;
  String? to;
  String? senderJid;
  String? time;
  String? id;
  String? type;
  String? body;
  String? msgtype;
  String? bubbleType;
  String? mediaURL;
  String? presenceType;
  String? presenceMode;
  String? chatStateType;
  int? isReadSent;

  MessageEvent({
    this.customText,
    this.from,
    this.to,
    this.senderJid,
    this.time,
    this.id,
    this.type,
    this.body,
    this.msgtype,
    this.bubbleType,
    this.mediaURL,
    this.presenceType,
    this.presenceMode,
    this.chatStateType,
    this.isReadSent,
  });

  Map<String, dynamic> toEventData() {
    return {
      'customText': customText,
      'to': to,
      'from': from,
      'senderJid': senderJid,
      'time': time,
      'id': id,
      'type': type,
      'body': body,
      'msgtype': msgtype,
      'bubbleType': bubbleType,
      'mediaURL': mediaURL,
      'presenceType': presenceType,
      'presenceMode': presenceMode,
      'isReadSent': isReadSent,
      'chatStateType': chatStateType,

    };
  }

  factory MessageEvent.fromJson(dynamic eventData) {
    return MessageEvent(
      customText: eventData['customText'] ?? '',
      to: eventData['to'] ?? '',
      from: eventData['from'] ?? '',
      senderJid: eventData['senderJid'] ?? '',
      time: eventData['time'] ?? '0',
      isReadSent: eventData['isReadSent'] ?? 0,
      id: eventData['id'] ?? '',
      type: eventData['type'] ?? '',
      body: eventData['body'] ?? '',
      msgtype: eventData['msgtype'] ?? '',
      bubbleType: eventData['bubbleType'] ?? '',
      mediaURL: eventData['mediaURL'] ?? '',
      presenceType: eventData['presenceType'] ?? '',
      presenceMode: eventData['presenceMode'] ?? '',
      chatStateType: eventData['chatStateType'] ?? '',
    );
  }
}
