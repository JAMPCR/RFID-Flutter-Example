import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk_example/screens/rfid_selection_screen.dart';
import 'package:zebra_rfid_sdk_example/route_observer.dart';

void main() {
  runApp(const RouteObserverApp());
}

class RouteObserverApp extends StatelessWidget {
  const RouteObserverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: <NavigatorObserver>[routeObserver],
      title: 'Zebra RFID Demo',
      home: RFIDSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
