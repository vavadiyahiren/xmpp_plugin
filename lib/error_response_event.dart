import 'package:xmpp_plugin/ennums/error_response_state.dart';

class ErrorResponseEvent {
  ErrorResponseState? type;
  String? from;
  String? error;

  ErrorResponseEvent({
    this.type,
    this.from,
    this.error,
  });

  Map<String, dynamic> toErrorResponseData() {
    return {
      'type': type,
      'from': from,
      'error': error,
    };
  }

  factory ErrorResponseEvent.fromJson(dynamic eventData) {
    return ErrorResponseEvent(
      type: eventData['type'] != null
          ? eventData['type'].toString().toErrorResponseState()
          : ErrorResponseState.none,
      from: eventData['from'] ?? '',
      error: eventData['exception'] ?? '',
    );
  }
}
