import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';
import 'package:zebra_rfid_sdk_example/widgets/data_view.dart';

//******************************************************************************
class RFIDMemeoryReaderScreen extends StatefulWidget {
  final String epc;
  const RFIDMemeoryReaderScreen({super.key, required this.epc});

  @override
  State<RFIDMemeoryReaderScreen> createState() => _RFIDMemeoryReaderScreen();
}

//******************************************************************************
class _RFIDMemeoryReaderScreen extends State<RFIDMemeoryReaderScreen> {
  //***************************
  String? epcMemory;
  String? userMemory;
  String? tidMemory;
  String? reservedMemory;

  @override
  void initState() {
    super.initState();
    readMemory();
  }

  void readMemory() async {
    epcMemory = await ZebraRfidSdk.readTag(widget.epc, Memory.EPC);
    setState(() {});
    tidMemory = await ZebraRfidSdk.readTag(widget.epc, Memory.TID);
    setState(() {});
    reservedMemory = await ZebraRfidSdk.readTag(widget.epc, Memory.RESERVED);
    setState(() {});
    userMemory = await ZebraRfidSdk.readTag(widget.epc, Memory.USER);
    setState(() {});
  }

  //***************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tag Memory'), centerTitle: true, elevation: 2),
      body: Padding(
        padding: EdgeInsetsGeometry.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DataView(title: "EPC Memory", data: epcMemory),
            DataView(title: "TID Memory", data: tidMemory),
            DataView(title: "Reserved Memory", data: reservedMemory),
            DataView(title: "User Memory", data: userMemory),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(currentScreen: Screen.settings),
    );
  }
}
