enum XmppConnectionState { connected, authenticated, connecting, disconnected, failed }

extension XmppConnectionStateParser on String {
  XmppConnectionState toConnectionState() {
    return XmppConnectionState.values.firstWhere((XmppConnectionState e) {
      return e.name.toString().toLowerCase() == this.toLowerCase();
    }, orElse: () {
      return XmppConnectionState.disconnected;
    });
  }
}
