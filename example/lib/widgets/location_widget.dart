import 'package:flutter/material.dart';

class LocationIndicator extends StatelessWidget {
  final int location;
  final String epc;

  const LocationIndicator({super.key, required this.epc, required this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Center(
          child: Text(epc, style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
        ),
        Divider(height: 1, thickness: 1, indent: 10, endIndent: 10, color: Colors.grey.shade700),
        Padding(
          padding: EdgeInsetsGeometry.only(top: 50),
          child: Column(
            children: [
              Stack(
                children: [
                  Positioned(
                    bottom: 2,
                    child: ClipRRect(
                      child: Container(
                        width: 100,
                        height: 400,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.red.shade700, Colors.orange.shade700, Colors.green.shade700]),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    child: Positioned(
                      top: 0,
                      left: 0,
                      width: 100,
                      height: 400 * (1 - (location / 100)),
                      child: Container(color: Colors.white),
                    ),
                  ),

                  Container(
                    width: 100,
                    height: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              Center(
                child: Text("$location%", style: TextStyle(color: Colors.grey.shade700, fontSize: 17)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
