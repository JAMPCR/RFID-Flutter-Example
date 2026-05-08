import 'package:flutter/material.dart';
import 'dart:async';

import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';

//******************************************************************************
class RFIDSelectionScreen extends StatefulWidget {
  const RFIDSelectionScreen({super.key});

  @override
  State<RFIDSelectionScreen> createState() => _RFIDSelectionScreen();
}

//******************************************************************************
class _RFIDSelectionScreen extends State<RFIDSelectionScreen> {
  List<ReaderDevice> availableReaderList = [];
  ReaderDevice connectedReader = ReaderDevice.initial();

  //***************************
  @override
  void initState() {
    super.initState();
    getAvailableReaderList();
    ZebraRfidSdk.addDeviceHandler(connectionHandler);
  }

  @override
  void dispose() {
    ZebraRfidSdk.removeDeviceHandler(connectionHandler);
    super.dispose();
  }

  //***************************
  Future<void> getAvailableReaderList() async {
    await requestAccess();
    final result = await ZebraRfidSdk.getAvailableReaderList();
    connectedReader = await ZebraRfidSdk.getConnectedReader();
    setState(() {
      availableReaderList = result;
    });
  }

  //***************************
  Future<void> requestAccess() async {
    await Permission.bluetoothScan.request().isGranted;
    await Permission.bluetoothConnect.request().isGranted;
  }

  //***************************
  void connectionHandler(ReaderDevice device) {
    setState(() {
      connectedReader = device;
    });
  }

  //***************************
  void connectToZebra(String tagName) async {
    await requestAccess();
    ZebraRfidSdk.connect(tagName);
  }

  //***************************
  void disconnectToZebra() async {
    await requestAccess();
    ZebraRfidSdk.disconnect();
  }

  //***************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RFID Readers'), centerTitle: true, elevation: 2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('DEVICES'),
              Text("Available Readers (${availableReaderList.length})", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      selectedTileColor: Colors.orange[100],
                      tileColor: (connectedReader.name == availableReaderList[index].name && connectedReader.connectionStatus == ConnectionStatus.connected)
                          ? Colors.green.shade300
                          : (connectedReader.name == availableReaderList[index].name && connectedReader.connectionStatus == ConnectionStatus.failed)
                          ? Colors.red.shade300
                          : (connectedReader.name == availableReaderList[index].name && connectedReader.connectionStatus == ConnectionStatus.connecting)
                          ? Colors.blue.shade300
                          : Colors.black12,
                      onTap: () => connectedReader.connectionStatus == ConnectionStatus.connecting
                          ? null
                          : (connectedReader.name == availableReaderList[index].name && connectedReader.connectionStatus == ConnectionStatus.connected)
                          ? disconnectToZebra()
                          : connectToZebra(availableReaderList[index].name!),
                      contentPadding: const EdgeInsets.all(8),
                      selectedColor: Colors.amber,
                      title: Text(availableReaderList[index].name ?? "Unknown Device"),
                      subtitle: (connectedReader.name == availableReaderList.elementAt(index).name && connectedReader.connectionStatus == ConnectionStatus.connected)
                          ? Text('Battery ${connectedReader.batteryLevel}%')
                          : (connectedReader.name == availableReaderList.elementAt(index).name && connectedReader.connectionStatus == ConnectionStatus.failed)
                          ? Text(connectedReader.message ?? '')
                          : Text(''),
                      trailing: Text(connectedReader.name == availableReaderList.elementAt(index).name ? connectedReader.connectionStatus.name : 'Not Connected'),
                    ),
                  ),
                  itemCount: availableReaderList.length,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(currentScreen: Screen.selection),
    );
  }
}
