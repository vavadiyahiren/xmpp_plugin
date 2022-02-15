import 'package:xmpp_plugin/ennums/xmpp_connection_state.dart';

class Utils {}

extension ConnectionStateToString on XmppConnectionState {
  String toConnectionName() {
    return this.toString().split('.').last;
  }
}
