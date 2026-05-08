import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'package:zebra_rfid_sdk_example/widgets/menu_list.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';

//******************************************************************************
class RFIDProfileScreen extends StatefulWidget {
  const RFIDProfileScreen({super.key});

  @override
  State<RFIDProfileScreen> createState() => _RFIDProfileScreen();
}

//******************************************************************************
class _RFIDProfileScreen extends State<RFIDProfileScreen> {
  final List<MenuItem> menuItems = [];

  //***************************
  @override
  void initState() {
    super.initState();
    menuItems.add(MenuItem(title: "Fastest Read", onTap: () => setFastestRead()));
    menuItems.add(MenuItem(title: "Cycle Count", onTap: () => setCycleCount()));
    menuItems.add(MenuItem(title: "Dense Readers", onTap: () => setDenseReaders()));
    menuItems.add(MenuItem(title: "Optimal Battery", onTap: () => setOptimalBattery()));
    menuItems.add(MenuItem(title: "Balanced Performance", onTap: () => setBalancedPerformance()));
  }

  void setFastestRead() async {
    ZebraRfidSdk.setDynamicPower(false);
    var antenna = await ZebraRfidSdk.setAntennaConfig(300, rfMode: 7);
    if (antenna == false) antenna = await ZebraRfidSdk.setAntennaConfig(300, rfMode: 2);
    var singulation = await ZebraRfidSdk.setSingulation(Session.S0, InvState.State_AB);
    var result = antenna && singulation;
    if (!mounted) return;
    var snackBar = SnackBar(content: Text(result ? 'Profile Set' : 'Failed to set profile'), backgroundColor: result ? Colors.blue[800] : Colors.red[800]);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void setCycleCount() async {
    ZebraRfidSdk.setDynamicPower(false);
    var antenna = await ZebraRfidSdk.setAntennaConfig(300);
    var singulation = await ZebraRfidSdk.setSingulation(Session.S2, InvState.State_A);
    var result = antenna && singulation;
    if (!mounted) return;
    var snackBar = SnackBar(content: Text(result ? 'Profile Set' : 'Failed to set profile'), backgroundColor: result ? Colors.blue[800] : Colors.red[800]);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void setDenseReaders() async {
    ZebraRfidSdk.setDynamicPower(false);
    var antenna = await ZebraRfidSdk.setAntennaConfig(300, rfMode: 17);
    if (antenna == false) antenna = await ZebraRfidSdk.setAntennaConfig(300, rfMode: 1);
    var singulation = await ZebraRfidSdk.setSingulation(Session.S1, InvState.State_A);
    var result = antenna && singulation;
    if (!mounted) return;
    var snackBar = SnackBar(content: Text(result ? 'Profile Set' : 'Failed to set profile'), backgroundColor: result ? Colors.blue[800] : Colors.red[800]);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void setOptimalBattery() async {
    ZebraRfidSdk.setDynamicPower(true);
    var antenna = await ZebraRfidSdk.setAntennaConfig(240);
    var singulation = await ZebraRfidSdk.setSingulation(Session.S1, InvState.State_A);
    var result = antenna && singulation;
    if (!mounted) return;
    var snackBar = SnackBar(content: Text(result ? 'Profile Set' : 'Failed to set profile'), backgroundColor: result ? Colors.blue[800] : Colors.red[800]);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void setBalancedPerformance() async {
    ZebraRfidSdk.setDynamicPower(true);
    var antenna = await ZebraRfidSdk.setAntennaConfig(270);
    var singulation = await ZebraRfidSdk.setSingulation(Session.S1, InvState.State_A);
    var result = antenna && singulation;
    if (!mounted) return;
    var snackBar = SnackBar(content: Text(result ? 'Profile Set' : 'Failed to set profile'), backgroundColor: result ? Colors.blue[800] : Colors.red[800]);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  //***************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RFID Settings'), centerTitle: true, elevation: 2),
      body: MenuList(items: menuItems),
      bottomNavigationBar: BottomBar(currentScreen: Screen.settings),
    );
  }
}
