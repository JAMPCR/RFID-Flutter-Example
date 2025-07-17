import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';

class TagList extends StatelessWidget {
  final List<TagData> tagList;
  final Function(String) onSelection;

  const TagList({super.key, required this.tagList, required this.onSelection});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Row
        Container(
          color: Colors.grey[300],
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 4, // EPC takes more space
                child: Text('EPC', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Count',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'RSSI',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),
        // Data List
        Expanded(
          child: ListView.builder(
            itemCount: tagList.length,
            itemBuilder: (context, index) {
              final item = tagList[index];
              return InkWell(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: Text(item.epc, style: TextStyle(fontSize: 12))),
                      Expanded(flex: 1, child: Text(item.seenCount.toString(), textAlign: TextAlign.center)),
                      Expanded(flex: 1, child: Text(item.rssi.toString(), textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                onTap: () => {onSelection(item.epc)},
              );
            },
          ),
        ),
      ],
    );
  }
}
