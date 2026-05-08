import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'package:zebra_rfid_sdk_example/widgets/battery_indicator.dart';
import 'package:zebra_rfid_sdk_example/widgets/location_widget.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';

//******************************************************************************
class RFIDLocateScreen extends StatefulWidget {
  final String epc;
  const RFIDLocateScreen({super.key, required this.epc});

  @override
  State<RFIDLocateScreen> createState() => _RFIDLocateScreen();
}

//******************************************************************************
class _RFIDLocateScreen extends State<RFIDLocateScreen> {
  double _batteryLevel = 0;
  bool scanning = false;
  int _locateDistance = 0;

  @override
  void initState() {
    super.initState();
    ZebraRfidSdk.stopInventory();
    ZebraRfidSdk.addTriggerHandler(triggerHandler);
    ZebraRfidSdk.addInventoryHandler(inventoryHandler);
    ZebraRfidSdk.addTagHandler(tagHandler);
    ZebraRfidSdk.addDeviceHandler(connectionHandler);
    ZebraRfidSdk.getBatteryLevel();
  }

  @override
  void dispose() {
    ZebraRfidSdk.stopLocationing();
    ZebraRfidSdk.removeTriggerHandler(triggerHandler);
    ZebraRfidSdk.removeInventoryHandler(inventoryHandler);
    ZebraRfidSdk.removeTagHandler(tagHandler);
    ZebraRfidSdk.removeDeviceHandler(connectionHandler);
    super.dispose();
  }

  // Update Event for connection
  void connectionHandler(ReaderDevice reader) {
    setState(() => _batteryLevel = reader.batteryLevel / 100);
  }

  // Tags Event
  void tagHandler(List<TagData> tags) {
    for (var tag in tags) {
      if (tag.epc == widget.epc) setState(() => _locateDistance = tag.distance);
    }
  }

  // Trigger been pressed ?
  void triggerHandler(bool pressed) {
    if (pressed == true) {
      ZebraRfidSdk.startLocationing(widget.epc);
    } else {
      ZebraRfidSdk.stopLocationing();
    }
  }

  // State Event
  void inventoryHandler(bool running) {
    setState(() {
      scanning = running;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Tag Locater'),
        centerTitle: true,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: BatteryIndicator(batteryLevel: _batteryLevel)),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(6),
        child: Center(
          child: LocationIndicator(location: _locateDistance, epc: widget.epc),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => triggerHandler(!scanning), foregroundColor: Colors.white, backgroundColor: scanning ? Colors.red : Colors.green, child: Icon(scanning ? Icons.stop : Icons.play_arrow)),
      bottomNavigationBar: BottomBar(currentScreen: Screen.reading),
    );
  }
}
