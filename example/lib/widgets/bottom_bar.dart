import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk_example/screens/rfid_selection_screen.dart';
import 'package:zebra_rfid_sdk_example/screens/rfid_reading_screen.dart';
import 'package:zebra_rfid_sdk_example/screens/rfid_settings_sreen.dart';

enum Screen { selection, reading, settings }

class BottomBar extends StatelessWidget {
  final Screen currentScreen;

  const BottomBar({super.key, required this.currentScreen});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RFIDSelectionScreen(),
            transitionDuration: const Duration(seconds: 0),
            reverseTransitionDuration: const Duration(seconds: 0),
          ),
          (Route<dynamic> route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RFIDReadingScreen(),
            transitionDuration: const Duration(seconds: 0),
            reverseTransitionDuration: const Duration(seconds: 0),
          ),
          (Route<dynamic> route) => false,
        );
        break;
      case 2:
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => RFIDSettingsScreen(),
            transitionDuration: const Duration(seconds: 0),
            reverseTransitionDuration: const Duration(seconds: 0),
          ),
          (Route<dynamic> route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Readers'),
        BottomNavigationBarItem(icon: Icon(Icons.business), label: 'RFID'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      currentIndex: currentScreen.index,
      selectedItemColor: Colors.blueAccent,
      onTap: (i) => _onItemTapped(context, i),
    );
  }
}
