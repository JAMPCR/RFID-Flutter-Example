import 'package:flutter/material.dart';

import 'package:zebra_rfid_sdk_example/screens/RFIDProfileScreen.dart';
import 'package:zebra_rfid_sdk_example/screens/RFIDRegulatoryScreen.dart';
import 'package:zebra_rfid_sdk_example/screens/RFIDBeeperScreen.dart';
import 'package:zebra_rfid_sdk_example/widgets/menu_list.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';

//******************************************************************************
class RFIDSettingsScreen extends StatefulWidget {
  const RFIDSettingsScreen({super.key});

  @override
  State<RFIDSettingsScreen> createState() => _RFIDSettingsScreen();
}

//******************************************************************************
class _RFIDSettingsScreen extends State<RFIDSettingsScreen> {
  final List<MenuItem> menuItems = [];

  //***************************
  @override
  void initState() {
    super.initState();
    menuItems.add(
      MenuItem(
        title: "Profiles",
        icon: Icons.person,
        onTap: () {
          Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => RFIDProfileScreen(), transitionDuration: const Duration(seconds: 0), reverseTransitionDuration: const Duration(seconds: 0)));
        },
      ),
    );
    menuItems.add(
      MenuItem(
        title: "Regulatory",
        icon: Icons.public,
        onTap: () {
          Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => RFIDRegulatoryScreen(), transitionDuration: const Duration(seconds: 0), reverseTransitionDuration: const Duration(seconds: 0)));
        },
      ),
    );
    menuItems.add(
      MenuItem(
        title: "Beeper",
        icon: Icons.volume_up,
        onTap: () {
          Navigator.push(context, PageRouteBuilder(pageBuilder: (_, __, ___) => RFIDBeeperScreen(), transitionDuration: const Duration(seconds: 0), reverseTransitionDuration: const Duration(seconds: 0)));
        },
      ),
    );
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
