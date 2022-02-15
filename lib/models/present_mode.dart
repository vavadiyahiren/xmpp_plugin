class PresentModel {
  PresentModel({
    this.presenceMode,
    this.presenceType,
    this.from,
  });

  String? presenceMode;
  String? presenceType;
  String? from;

  factory PresentModel.fromJson(dynamic json) => PresentModel(
        presenceMode: json["presenceMode"] ?? '',
        presenceType: json["presenceType"] ?? '',
        from: json["from"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "presenceMode": presenceMode,
        "presenceType": presenceType,
        "from": from,
      };
}
