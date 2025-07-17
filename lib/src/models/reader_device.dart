enum ConnectionStatus { connected, disconnected, connecting, notConnected, failed }

class ReaderDevice {
  final ConnectionStatus connectionStatus;
  final String? name;
  final int batteryLevel;
  final String? message;
  final String? firmwareVersion;
  final String? modelName;
  final String? serialNumber;
  final int minPower;
  final int maxPower;
  final bool canLocate;

  ReaderDevice({required this.connectionStatus, required this.batteryLevel, this.name, this.message, this.firmwareVersion, this.serialNumber, this.modelName, required this.minPower, required this.maxPower, required this.canLocate});

  factory ReaderDevice.fromMap(Map<String, dynamic> map) {
    return ReaderDevice(
      connectionStatus: ConnectionStatus.values.firstWhere((e) => e.name.toLowerCase() == '${map['connectionStatus']}'.toString().toLowerCase(), orElse: () => ConnectionStatus.notConnected),
      name: map['name'] as String?,
      batteryLevel: map['batteryLevel'] as int,
      message: map['message'] as String?,
      serialNumber: map['serialNumber'] as String?,
      modelName: map['modelName'] as String?,
      firmwareVersion: map['firmwareVersion'] as String?,
      minPower: map['minPower'] as int,
      maxPower: map['maxPower'] as int,
      canLocate: map['canLocate'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'connectionStatus': connectionStatus.name,
      'batteryLevel': batteryLevel,
      'message': message,
      'firmwareVersion': firmwareVersion,
      'serialNumber': serialNumber,
      'modelName': modelName,
      'minPower': minPower,
      "maxPower": maxPower,
      'canLocate': canLocate,
    };
  }

  factory ReaderDevice.initial() {
    return ReaderDevice(connectionStatus: ConnectionStatus.notConnected, name: '', batteryLevel: 0, minPower: 0, maxPower: 0, canLocate: false);
  }
}
