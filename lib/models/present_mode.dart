import '../ennums/presence_type.dart';

class PresentModel {
  PresentModel({
    this.presenceMode,
    this.presenceType,
    this.from,
  });

  PresenceMode? presenceMode;
  PresenceType? presenceType;
  String? from;

  factory PresentModel.fromJson(dynamic json) => PresentModel(
        presenceMode: json["presenceMode"] ?? '',
        presenceType: json["presenceType"] ?? '',
        from: json["from"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "presenceMode": presenceMode?.name ?? '',
        "presenceType": presenceType?.name ?? '',
        "from": from,
      };
}
