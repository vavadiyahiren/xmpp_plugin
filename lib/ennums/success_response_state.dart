enum SuccessResponseState { group_created_success, group_joined_success, none }

extension SuccessResponseStateParser on String {
  SuccessResponseState toSuccessResponseState() {
    return SuccessResponseState.values.firstWhere((SuccessResponseState e) {
      return e.name.toString().toLowerCase() == this.toLowerCase();
    }, orElse: () {
      return SuccessResponseState.none;
    });
  }
}
