/// ElementName : ""
/// ElementNameSpace : ""
/// ChildElement : ""
/// ChildBody : ""

class CustomElement {
  CustomElement({
    String? elementName,
    String? elementNameSpace,
    String? childElement,
    String? childBody,
  }) {
    _elementName = elementName;
    _elementNameSpace = elementNameSpace;
    _childElement = childElement;
    _childBody = childBody;
  }

  CustomElement.fromJson(dynamic json) {
    _elementName = json['ElementName'];
    _elementNameSpace = json['ElementNameSpace'];
    _childElement = json['ChildElement'];
    _childBody = json['ChildBody'];
  }

  String? _elementName;
  String? _elementNameSpace;
  String? _childElement;
  String? _childBody;

  String? get elementName => _elementName;

  String? get elementNameSpace => _elementNameSpace;

  String? get childElement => _childElement;

  String? get childBody => _childBody;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ElementName'] = _elementName;
    map['ElementNameSpace'] = _elementNameSpace;
    map['ChildElement'] = _childElement;
    map['ChildBody'] = _childBody;
    return map;
  }
}
