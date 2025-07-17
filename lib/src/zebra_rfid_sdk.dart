import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zebra_rfid_sdk/src/models/reader_device.dart';
import 'package:zebra_rfid_sdk/src/models/tag_data.dart';
import 'package:zebra_rfid_sdk/src/models/regulatory_data.dart';

enum BeeperVolume { quiet, low, medium, high }

// ignore: constant_identifier_names
enum Session { S0, S1, S2, S3 }

// ignore: constant_identifier_names
enum InvState { State_A, State_B, State_AB }

// ignore: constant_identifier_names
enum Memory { RESERVED, EPC, TID, USER }

class ZebraRfidSdk {
  static const MethodChannel _methodchannel = MethodChannel("ZebraRFIDSDK/Methods");
  static const EventChannel _eventchannel = EventChannel("ZebraRFIDSDK/Events");
  static StreamSubscription? _subscription;
  static final List<void Function(ReaderDevice)> _deviceHandlers = [];
  static final List<void Function(bool)> _triggerHandlers = [];
  static final List<void Function(bool)> _inventoryHandlers = [];
  static final List<void Function(List<TagData>)> _tagHandlers = [];

  //************************
  static Future<List<ReaderDevice>> getAvailableReaderList() async {
    final result = await _methodchannel.invokeMethod<List<dynamic>>('getAvailableReaderList') ?? [];
    List<ReaderDevice> readers = [];
    for (var i = 0; i < result.length; i++) {
      readers.add(ReaderDevice.fromMap(Map<String, dynamic>.from(result[i])));
    }
    return readers;
  }

  //************************
  static Future<void> connect(String deviceName) async {
    await _methodchannel.invokeMethod<void>('connect', {"deviceName": deviceName});
  }

  //************************
  static Future<void> disconnect() async {
    await _methodchannel.invokeMethod<void>('disconnect');
  }

  static Future<ReaderDevice> getConnectedReader() async {
    final map = await _methodchannel.invokeMethod<dynamic>('getConnectedReader');
    var result = ReaderDevice.initial();
    if (map != null) result = ReaderDevice.fromMap(Map<String, dynamic>.from(map));
    return result;
  }

  //************************
  static Future<void> startInventory() async {
    await _methodchannel.invokeMethod<void>('startInventory');
  }

  //************************
  static Future<void> stopInventory() async {
    await _methodchannel.invokeMethod<void>('stopInventory');
  }

  //************************
  static Future<void> startLocationing(String tagId) async {
    await _methodchannel.invokeMethod<void>('startLocationing', {'tagId': tagId});
  }

  //************************
  static Future<void> stopLocationing() async {
    await _methodchannel.invokeMethod<void>('stopLocationing');
  }

  //************************
  static Future<bool> isReaderConnected() async {
    final result = await _methodchannel.invokeMethod<bool>('isReaderConnected') ?? false;
    return result;
  }

  //************************
  static Future<bool> setBeeperVolume(BeeperVolume level) async {
    final result = await _methodchannel.invokeMethod<bool>('setBeeperVolume', {"level": level.index}) ?? false;
    return result;
  }

  static Future<BeeperVolume> getBeeperVolume() async {
    final result = await _methodchannel.invokeMethod<int>('getBeeperVolume') ?? 0;
    return BeeperVolume.values[result];
  }

  //************************
  static Future<void> getBatteryLevel() async {
    await _methodchannel.invokeMethod<void>('getBatteryLevel');
  }

  //************************
  static Future<bool> setDynamicPower(bool enabled) async {
    final result = await _methodchannel.invokeMethod<bool>('setDynamicPower', {"enabled": enabled}) ?? false;
    return result;
  }

  //************************
  static Future<bool> setPreFilter(String? epc) async {
    final result = await _methodchannel.invokeMethod<bool>('setPreFilter', {"epc": epc}) ?? false;
    return result;
  }

  //************************
  static Future<String?> readTag(String epc, Memory memory, {String? password, int offset = 0, int length = 0}) async {
    final result = await _methodchannel.invokeMethod<String?>('readTag', {"epc": epc, "memory": memory.index, "password": password, "offset": offset, "length": length});
    return result;
  }

  //************************
  static Future<bool> writeTag(String epc, {String? newEpc, String? password, String? newPassword, String? killPassword, String? userData}) async {
    final result = await _methodchannel.invokeMethod<bool>('writeTag', {"epc": epc, "newEpc": newEpc, "password": password, "newPassword": newPassword, "killPassword": killPassword, "data": userData}) ?? false;
    return result;
  }

  //************************
  static Future<bool> killTag(String epc, {String? killPassword}) async {
    final result = await _methodchannel.invokeMethod<bool>('killTag', {"epc": epc, "password": killPassword}) ?? false;
    return result;
  }

  //************************
  static Future<bool> setAntennaConfig(int power, {int rfMode = 0}) async {
    final result = await _methodchannel.invokeMethod<bool>('setAntennaConfig', {"power": power, "rfMode": rfMode}) ?? false;
    return result;
  }

  //************************
  static Future<bool> setSingulation(Session session, InvState state) async {
    final result = await _methodchannel.invokeMethod<bool>('setSingulation', {"session": session.index, "state": state.index}) ?? false;
    return result;
  }

  //************************
  static Future<List<RegulatoryData>> getAvailableRegions() async {
    final result = await _methodchannel.invokeMethod<List<dynamic>>('getAvailableRegions') ?? [];
    List<RegulatoryData> data = [];
    for (var i = 0; i < result.length; i++) {
      data.add(RegulatoryData.fromMap(Map<String, dynamic>.from(result[i])));
    }
    return data;
  }

  //************************
  static Future<RegulatoryData> getRegulatoryConfig() async {
    final result = await _methodchannel.invokeMethod<dynamic>('getRegulatoryConfig');
    final map = Map<String, dynamic>.from(result);
    return RegulatoryData.fromMap(map);
  }

  //************************
  static Future<bool> setRegulatoryConfig(RegulatoryData config) async {
    final result = await _methodchannel.invokeMethod<bool>('setRegulatoryConfig', config.toMap()) ?? false;
    return result;
  }

  //************************
  // readTag(epc, memory, offset, len)

  //***************************************************************************
  static addDeviceHandler(void Function(ReaderDevice) handler) {
    _deviceHandlers.add(handler);
    _startListening();
  }

  static removeDeviceHandler(void Function(ReaderDevice) handler) {
    _deviceHandlers.remove(handler);
    _stopListening();
  }

  static addTriggerHandler(void Function(bool) handler) {
    _triggerHandlers.add(handler);
    _startListening();
  }

  static removeTriggerHandler(void Function(bool) handler) {
    _triggerHandlers.remove(handler);
    _stopListening();
  }

  static addInventoryHandler(void Function(bool) handler) {
    _inventoryHandlers.add(handler);
    _startListening();
  }

  static removeInventoryHandler(void Function(bool) handler) {
    _inventoryHandlers.remove(handler);
    _stopListening();
  }

  static addTagHandler(void Function(List<TagData>) handler) {
    _tagHandlers.add(handler);
    _startListening();
  }

  static removeTagHandler(void Function(List<TagData>) handler) {
    _tagHandlers.remove(handler);
    _stopListening();
  }

  //***************************************************************************
  static void _startListening() {
    if (_subscription != null) return;
    _subscription = _eventchannel.receiveBroadcastStream().listen(_eventListener);
  }

  static void _stopListening() {
    if (_deviceHandlers.isEmpty && _triggerHandlers.isEmpty && _inventoryHandlers.isEmpty && _tagHandlers.isEmpty) {
      _subscription?.cancel();
      _subscription = null;
    }
  }

  //***************************************************************************
  static void _eventListener(dynamic payload) {
    final map = Map<String, dynamic>.from(payload);
    final String? type = map['type'];
    final data = Map<String, dynamic>.from(map['data']);

    switch (type) {
      // RFIDConnection Event
      case 'RFIDConnection':
        final readerDevice = ReaderDevice.fromMap(data);
        for (final h in _deviceHandlers) {
          h(readerDevice);
        }
        break;

      // Trigger Pressed Event
      case 'RFIDTrigger':
        final triggerPressed = data['pressed'] as bool;
        for (final h in _triggerHandlers) {
          h(triggerPressed);
        }
        break;

      // Inventory Started/Stoped Event
      case 'RFIDInventory':
        final running = data['running'] as bool;
        for (final h in _inventoryHandlers) {
          h(running);
        }
        break;

      // RFIDTagData Event
      case 'RFIDTagData':
        final tags = data['tags'] as List<dynamic>;
        final List<TagData> taglist = [];
        for (var i = 0; i < tags.length; i++) {
          var tag = Map<String, dynamic>.from(tags[i]);
          taglist.add(TagData.fromMap(tag));
        }
        for (final h in _tagHandlers) {
          h(taglist);
        }
        break;

      default:
        break;
    }
  }
}
