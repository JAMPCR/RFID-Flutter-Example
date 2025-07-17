import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final IconData? icon;
  final void Function()? onTap;
  const MenuItem({required this.title, this.icon, this.onTap});
}

class MenuList extends StatelessWidget {
  final List<MenuItem> items; // from 0.0 to 1.0 (e.g., 0.76 for 76%)

  const MenuList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: InkWell(
            child: Padding(
              padding: EdgeInsetsGeometry.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.only(right: 15),
                    child: items[index].icon != null ? Icon(items[index].icon, color: Colors.blue.shade400) : null,
                  ),
                  Text(items[index].title, style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
            onTap: () => items[index].onTap != null ? items[index].onTap!() : null,
          ),
        );
      },
    );
  }
}
