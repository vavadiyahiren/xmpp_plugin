import '../ennums/typing_status.dart';
import 'package:collection/collection.dart';

class ChatState {
  String? from;
  String? senderJid;
  String? id;
  String? type;
  String? msgtype;
  TypingStatus? chatStateType;

  ChatState({
    this.from,
    this.senderJid,
    this.id,
    this.type,
    this.msgtype,
    this.chatStateType,
  });

  Map<String, dynamic> toEventData() {
    return {
      'from': from,
      'senderJid': senderJid,
      'id': id,
      'type': type,
      'msgtype': msgtype,
      'chatStateType': chatStateType?.name ?? '',
    };
  }

  factory ChatState.fromJson(dynamic eventData) {
    return ChatState(
      from: eventData['from'] ?? '',
      senderJid: eventData['senderJid'] ?? '',
      id: eventData['id'] ?? '',
      type: eventData['type'] ?? '',
      msgtype: eventData['msgtype'] ?? '',
      chatStateType: TypingStatus.values.firstWhereOrNull(
              (e) => e.name == (eventData['chatStateType'] ?? ''))
    );
  }
}
