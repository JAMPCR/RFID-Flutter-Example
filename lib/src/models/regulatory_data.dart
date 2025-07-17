class RegulatoryData {
  String name;
  String regionCode;
  bool hopping;
  List<String> channels;

  RegulatoryData({required this.name, required this.regionCode, required this.hopping, required this.channels});

  @override
  bool operator ==(Object other) => identical(this, other) || other is RegulatoryData && runtimeType == other.runtimeType && name == other.name && regionCode == other.regionCode;

  @override
  int get hashCode => name.hashCode;

  factory RegulatoryData.fromMap(Map<String, dynamic> map) {
    return RegulatoryData(name: map['name'] as String, regionCode: map['regionCode'] as String, hopping: map['hopping'] as bool, channels: List<String>.from(map['channels']));
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'regionCode': regionCode, "hopping": hopping, "channels": channels};
  }

  factory RegulatoryData.initial() {
    return RegulatoryData(name: "", regionCode: "", hopping: false, channels: List<String>.empty());
  }
}
