import 'package:flutter/material.dart';

class TotalsWidget extends StatelessWidget {
  final String totalReads;
  final String timerText;
  final String readRate;
  final String uniqueReads;

  const TotalsWidget({super.key, required this.totalReads, required this.timerText, required this.readRate, required this.uniqueReads});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('TOTAL READS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(
              totalReads,
              style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('UNIQUE READS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(
              uniqueReads,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const Text("READ RATE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(
                  readRate,
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.red),
                ),
                const Text(
                  "tags/second",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Colors.red),
                ),
              ],
            ),
            Column(
              children: [
                const Text("READ TIME", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(
                  timerText,
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}
