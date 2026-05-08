import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'package:zebra_rfid_sdk_example/screens/rfid_option_screen.dart';
import 'dart:async';
import 'package:zebra_rfid_sdk_example/widgets/battery_indicator.dart';
import 'package:zebra_rfid_sdk_example/widgets/totals_widget.dart';
import 'package:zebra_rfid_sdk_example/widgets/tag_list_widget.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';
import 'package:zebra_rfid_sdk_example/route_observer.dart';

//******************************************************************************
class RFIDReadingScreen extends StatefulWidget {
  const RFIDReadingScreen({super.key});

  @override
  State<RFIDReadingScreen> createState() => _RFIDReadingScreen();
}

//******************************************************************************
class _RFIDReadingScreen extends State<RFIDReadingScreen> with RouteAware {
  //***************************
  bool scanning = false;
  bool _totalsScreen = true;
  int _secondsElapsed = 0;
  int _totalReads = 0;
  int _readRate = 0;
  int _totalReadRate = 0;
  Timer? _timer;
  double _batteryLevel = 0;
  final List<TagData> _readTags = [];

  @override
  void initState() {
    super.initState();
    _startScreen();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _stopScreen();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    _stopScreen();
  }

  @override
  void didPopNext() {
    _startScreen();
  }

  void _startScreen() async {
    ZebraRfidSdk.addTriggerHandler(triggerHandler);
    ZebraRfidSdk.addInventoryHandler(inventoryHandler);
    ZebraRfidSdk.addTagHandler(tagHandler);
    ZebraRfidSdk.addDeviceHandler(connectionHandler);
    ZebraRfidSdk.getBatteryLevel();
  }

  void _stopScreen() {
    ZebraRfidSdk.stopInventory();
    ZebraRfidSdk.removeTriggerHandler(triggerHandler);
    ZebraRfidSdk.removeInventoryHandler(inventoryHandler);
    ZebraRfidSdk.removeTagHandler(tagHandler);
    ZebraRfidSdk.removeDeviceHandler(connectionHandler);
    _timer?.cancel();
  }

  // Update Event for connection
  void connectionHandler(ReaderDevice reader) {
    setState(() => _batteryLevel = reader.batteryLevel / 100);
  }

  // Trigger been pressed ?
  void triggerHandler(bool pressed) {
    if (pressed == true) {
      ZebraRfidSdk.startInventory();
    } else {
      ZebraRfidSdk.stopInventory();
    }
  }

  // State Event
  void inventoryHandler(bool running) {
    setState(() {
      scanning = running;
      if (running) {
        _secondsElapsed = 0;
        _totalReads = 0;
        _readTags.clear();
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  // Tags Event
  void tagHandler(List<TagData> tags) {
    _totalReadRate += tags.length;
    for (var tag in tags) {
      var data = _readTags.where((row) => row.epc == tag.epc);
      if (data.isNotEmpty) data.first.seenCount += tag.seenCount;
      if (!_readTags.contains(tag)) {
        _readTags.add(tag);
      }
    }
    setState(() => _totalReads += tags.length);
  }

  // Helper for format Time
  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _secondsElapsed++;
        _readRate = _totalReadRate;
        _totalReadRate = 0;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Toggle Displayed Screen
  void onToggleScreen() {
    setState(() => _totalsScreen = !_totalsScreen);
  }

  //***************************
  @override
  Widget build(BuildContext context) {
    final timerText = _formatTime(_secondsElapsed);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Tag Reader'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(_totalsScreen ? Icons.list : Icons.leaderboard),
            onPressed: onToggleScreen,
          ),
          Center(child: BatteryIndicator(batteryLevel: _batteryLevel)),
          PopupMenuButton(
            onSelected: (i) {
              ZebraRfidSdk.setPreFilter(null);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(value: 0, child: Text('Clear Filter')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(6),
        child: Center(
          child: _totalsScreen
              ? TotalsWidget(
                  totalReads: _totalReads.toString(),
                  timerText: timerText,
                  readRate: _readRate.toString(),
                  uniqueReads: _readTags.length.toString(),
                )
              : TagList(
                  tagList: _readTags,
                  onSelection: (epc) {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            RFIDOptionsScreen(epc: epc),
                        transitionDuration: const Duration(seconds: 0),
                        reverseTransitionDuration: const Duration(seconds: 0),
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => triggerHandler(!scanning),
        foregroundColor: Colors.white,
        backgroundColor: scanning ? Colors.red : Colors.green,
        child: Icon(scanning ? Icons.stop : Icons.play_arrow),
      ),
      bottomNavigationBar: BottomBar(currentScreen: Screen.reading),
    );
  }
}
