import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final double batteryLevel; // from 0.0 to 1.0 (e.g., 0.76 for 76%)

  const BatteryIndicator({super.key, required this.batteryLevel});

  Color _getGradientColor(double level) {
    if (level < 0.2) return Colors.red.shade800;
    if (level < 0.7) return Colors.orange.shade700;
    if (level < 0.8) return Colors.green.shade300;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getGradientColor(batteryLevel);
    final fillFactor = batteryLevel.clamp(0.0, 1.0);

    return SizedBox(
      width: 10,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Battery Shell
          Column(
            children: [
              // Battery Head
              Container(
                width: 5,
                height: 2,
                decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
              ),
              // Battery Body
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade700, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          // Fill Level
          Positioned(
            bottom: 2,
            child: ClipRRect(
              child: Container(
                width: 6,
                height: 16 * fillFactor,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      color.withAlpha(150), // Transparent end
                      color,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Battery Text
        ],
      ),
    );
  }
}
