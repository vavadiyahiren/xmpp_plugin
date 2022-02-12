enum ErrorResponseState { group_creation_failed, group_joined_failed, none }

extension ErrorResponseStateParser on String {
  ErrorResponseState toErrorResponseState() {
    return ErrorResponseState.values.firstWhere((ErrorResponseState e) {
      return e.name.toString().toLowerCase() == this.toLowerCase();
    }, orElse: () {
      return ErrorResponseState.none;
    });
  }
}
