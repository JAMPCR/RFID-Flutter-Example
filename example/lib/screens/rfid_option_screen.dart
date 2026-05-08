import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';
import 'package:zebra_rfid_sdk_example/screens/rfid_locate_screen.dart';
import 'package:zebra_rfid_sdk_example/screens/rfid_memory_reader_screen.dart';
import 'package:zebra_rfid_sdk_example/widgets/menu_list.dart';
import 'package:zebra_rfid_sdk_example/widgets/bottom_bar.dart';

//******************************************************************************
class RFIDOptionsScreen extends StatefulWidget {
  final String epc;
  const RFIDOptionsScreen({super.key, required this.epc});

  @override
  State<RFIDOptionsScreen> createState() => _RFIDOptionsScreen();
}

//******************************************************************************
class _RFIDOptionsScreen extends State<RFIDOptionsScreen> {
  final List<MenuItem> menuItems = [];

  void setFilter(String epc) async {
    var result = await ZebraRfidSdk.setPreFilter(epc);
    if (!mounted) return;
    var snackBar = SnackBar(
      content: Text(result ? 'Pre-filter Set' : 'Failed to set pre-filter'),
      backgroundColor: result ? Colors.blue[800] : Colors.red[800],
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void killTag(String epc, String password) async {
    //Attempt to write kill password
    var killResult = await ZebraRfidSdk.writeTag(epc, killPassword: password);
    var result = killResult;
    if (killResult == true) {
      result = await ZebraRfidSdk.killTag(epc, killPassword: password);
    }
    if (!mounted) return;
    var snackBar = SnackBar(
      content: Text(result ? 'Tag killed!' : 'Failed to kill tag'),
      backgroundColor: result ? Colors.blue[800] : Colors.red[800],
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  //***************************
  @override
  void initState() {
    super.initState();
    menuItems.add(
      MenuItem(
        title: "Locate",
        icon: Icons.location_searching,
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => RFIDLocateScreen(epc: widget.epc),
              transitionDuration: const Duration(seconds: 0),
              reverseTransitionDuration: const Duration(seconds: 0),
            ),
          );
        },
      ),
    );
    menuItems.add(
      MenuItem(
        title: "Read Tag",
        icon: Icons.memory,
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  RFIDMemeoryReaderScreen(epc: widget.epc),
              transitionDuration: const Duration(seconds: 0),
              reverseTransitionDuration: const Duration(seconds: 0),
            ),
          );
        },
      ),
    );
    menuItems.add(
      MenuItem(
        title: "Set as Filter",
        icon: Icons.filter_alt,
        onTap: () {
          setFilter(widget.epc);
        },
      ),
    );
    menuItems.add(
      MenuItem(
        title: "Kill Tag",
        icon: Icons.cancel_sharp,
        onTap: () {
          showPasswordDialog(context, (password) {
            killTag(widget.epc, password);
          });
        },
      ),
    );
  }

  //***************************
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Settings'),
        centerTitle: true,
        elevation: 2,
      ),
      body: MenuList(items: menuItems),
      bottomNavigationBar: BottomBar(currentScreen: Screen.settings),
    );
  }
  //***************************

  void showPasswordDialog(BuildContext context, void Function(String)? onOk) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextFormField(
            controller: controller,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
              LengthLimitingTextInputFormatter(8), // Optional limit
            ],
            validator: (value) {
              if (value == null || value.length != 8) {
                return 'Must be exactly 8 hex digits';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'Enter 8 hex digit kill password',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (onOk != null) {
                  onOk(controller.text);
                }
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
