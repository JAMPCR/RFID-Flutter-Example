import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';
import 'package:zebra_rfid_sdk_example/widgets/volume_widget.dart';

//******************************************************************************
class RFIDBeeperScreen extends StatefulWidget {
  const RFIDBeeperScreen({super.key});

  @override
  State<RFIDBeeperScreen> createState() => _RFIDBeeperScreen();
}

//******************************************************************************
class _RFIDBeeperScreen extends State<RFIDBeeperScreen> {
  //***************************
  BeeperVolume _volume = BeeperVolume.quiet;

  @override
  void initState() {
    super.initState();
    getVolume();
  }

  void getVolume() async {
    _volume = await ZebraRfidSdk.getBeeperVolume();
    setState(() {});
  }

  //***************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beeper Volume'), centerTitle: true, elevation: 2),
      body: Padding(
        padding: EdgeInsetsGeometry.all(30),
        child: VolumeWidget(initialSetting: _volume),
      ),
      bottomNavigationBar: BottomBar(currentScreen: Screen.settings),
    );
  }
}
