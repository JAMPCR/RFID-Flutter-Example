class TagData {
  final String epc;
  final int antenna;
  final int rssi;
  int seenCount;
  final int distance;
  final int seen;
  final int channelIndex;
  final int phase;

  TagData({required this.epc, required this.seenCount, required this.antenna, required this.rssi, required this.distance, required this.seen, required this.channelIndex, required this.phase});

  @override
  bool operator ==(Object other) => identical(this, other) || other is TagData && runtimeType == other.runtimeType && epc == other.epc;

  @override
  int get hashCode => epc.hashCode;

  factory TagData.fromMap(Map<String, dynamic> map) {
    return TagData(
      epc: map['epc'] as String,
      seenCount: map['seenCount'] as int,
      antenna: map['antenna'] as int,
      rssi: map['rssi'] as int,
      distance: map['distance'] as int,
      seen: map['seen'] as int,
      channelIndex: map['channelIndex'] as int,
      phase: map['phase'] as int,
    );
  }
}
