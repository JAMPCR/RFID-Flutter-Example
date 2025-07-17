import 'package:flutter/material.dart';

class ChannelCheckBoxList extends StatefulWidget {
  final List<String>? items;
  final List<String>? enabledItems;
  final Function(List<String>)? onChanged;

  const ChannelCheckBoxList({super.key, this.items, this.enabledItems, this.onChanged});

  @override
  State<ChannelCheckBoxList> createState() => _ChannelCheckBoxList();
}

class _ChannelCheckBoxList extends State<ChannelCheckBoxList> {
  final Map<String, bool> checkedMap = {};
  final List<String> itemsList = [];

  @override
  void initState() {
    super.initState();
    initializeCheckedMap();
  }

  @override
  void didUpdateWidget(covariant ChannelCheckBoxList oldWidget) {
    super.didUpdateWidget(oldWidget);
    initializeCheckedMap();
  }

  void initializeCheckedMap() {
    final items = widget.items ?? [];
    final enabledItems = widget.enabledItems ?? [];
    checkedMap.clear();
    itemsList.clear();
    for (var item in items) {
      checkedMap[item] = enabledItems.contains(item);
      itemsList.add(item);
    }
    setState(() {});
  }

  List<String> getEnabledItems() {
    return checkedMap.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (checkedMap.isEmpty) {
      return Center(child: Text('No channels available'));
    }
    return SizedBox(
      child: ListView.builder(
        itemCount: itemsList.length,
        itemBuilder: (context, index) {
          return CheckboxListTile(
            title: Text(itemsList[index]),
            value: checkedMap[itemsList[index]],
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 0),
            visualDensity: VisualDensity.compact,
            dense: true,
            onChanged: (bool? value) {
              setState(() {
                checkedMap[itemsList[index]] = value ?? false;
              });
              if (widget.onChanged != null) widget.onChanged!(getEnabledItems());
            },
          );
        },
      ),
    );
  }
}
