import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'dart:async';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';
import 'package:zebra_rfid_sdk_example/widgets/channel_check_box_list.dart';

//******************************************************************************
class RFIDRegulatoryScreen extends StatefulWidget {
  const RFIDRegulatoryScreen({super.key});

  @override
  State<RFIDRegulatoryScreen> createState() => _RFIDRegulatoryScreen();
}

//******************************************************************************
class _RFIDRegulatoryScreen extends State<RFIDRegulatoryScreen> {
  List<RegulatoryData> _availableRegions = [];
  RegulatoryData? _currentSelectedRegion = RegulatoryData.initial();
  RegulatoryData _currentRegion = RegulatoryData.initial();
  bool _loading = true;

  //***************************
  @override
  void initState() {
    super.initState();
    getDeviceData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getDeviceData() async {
    final availableRegions = await ZebraRfidSdk.getAvailableRegions();
    _currentRegion = await ZebraRfidSdk.getRegulatoryConfig();
    if (!mounted) return;
    setState(() {
      _availableRegions = availableRegions;
      for (var x in _availableRegions) {
        if (x == _currentRegion) {
          _currentSelectedRegion = x;
        }
      }
      _loading = false;
    });
  }

  void _saveSettings() async {
    if (_currentSelectedRegion != null) {
      final result = await ZebraRfidSdk.setRegulatoryConfig(_currentRegion);
      if (!mounted) return;
      var snackBar = SnackBar(
        content: Text(
          result
              ? 'Regulatory settings stored'
              : "Failed to set regulatory settings",
        ),
        backgroundColor: result ? Colors.blue[800] : Colors.red[800],
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Regulatory Settings'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            DropdownMenu<RegulatoryData>(
              initialSelection: _currentSelectedRegion,
              label: const Text("Select Region"),
              width: screenWidth - 40,
              onSelected: (RegulatoryData? newValue) {
                _currentRegion.name = newValue != null ? newValue.name : "";
                _currentRegion.regionCode = newValue != null
                    ? newValue.regionCode
                    : "";
                _currentRegion.channels = List<String>.empty();
                _currentRegion.hopping = false;
                setState(() {
                  _currentSelectedRegion = newValue;
                });
              },
              dropdownMenuEntries: _availableRegions.map((region) {
                return DropdownMenuEntry<RegulatoryData>(
                  value: region,
                  label: "${region.name} (${region.regionCode})",
                );
              }).toList(),
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(top: 20, bottom: 20),
              child: Text("Selected Channels"),
            ),
            Flexible(
              flex: 10,
              child: _loading
                  ? Center(child: Text("Loading"))
                  : ChannelCheckBoxList(
                      items: _currentSelectedRegion?.channels,
                      enabledItems: _currentRegion.channels,
                      onChanged: (list) => {
                        setState(() {
                          _currentRegion.channels = list;
                          if (list.length <= 1) _currentRegion.hopping = false;
                        }),
                      },
                    ),
            ),
            Spacer(flex: 1),
            CheckboxListTile(
              title: Text("Channel Hopping"),
              value: _currentRegion.hopping,
              enabled:
                  _currentRegion.channels.length > 1 &&
                  (_currentSelectedRegion != null
                      ? _currentSelectedRegion!.hopping
                      : false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.symmetric(horizontal: 0),
              visualDensity: VisualDensity.compact,
              dense: true,
              onChanged: (bool? value) {
                setState(() {
                  _currentRegion.hopping = value ?? false;
                });
              },
            ),
            Spacer(),
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black87,
                backgroundColor: Colors.grey[300],
                minimumSize: Size(88, 36),
                padding: EdgeInsets.symmetric(horizontal: 16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
              onPressed: () => _saveSettings(),
              child: Text("Save Settings"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(currentScreen: Screen.settings),
    );
  }
}
