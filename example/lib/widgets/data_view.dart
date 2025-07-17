import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class DataView extends StatelessWidget {
  final String? data;
  final String title;

  const DataView({super.key, required this.title, required this.data});

  String formatHexDump(Uint8List bytes) {
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += 8) {
      int remaining = bytes.length - i;
      int lineLength = remaining >= 8 ? 8 : remaining;

      // Build hex part
      String hexPart = '';
      for (int j = 0; j < lineLength; j++) {
        hexPart += bytes[i + j].toRadixString(16).padLeft(2, '0').toUpperCase() + ' ';
      }
      buffer.writeln('$hexPart');
    }
    return buffer.toString();
  }

  String formatAsciiDump(Uint8List bytes) {
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += 8) {
      int remaining = bytes.length - i;
      int lineLength = remaining >= 8 ? 8 : remaining;

      String asciiPart = "";
      for (int j = 0; j < lineLength; j++) {
        int charCode = bytes[i + j];
        if (charCode >= 32 && charCode <= 126) {
          asciiPart += String.fromCharCode(charCode);
        } else {
          asciiPart += '.';
        }
      }
      buffer.writeln('$asciiPart');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List bytes;
    String hexDump = "";
    String asciiDump = "";

    if (data != null) {
      bytes = Uint8List.fromList(utf8.encode(data!));
      hexDump = formatHexDump(bytes);
      asciiDump = formatAsciiDump(bytes);
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 8),
          data == null
              ? Align(
                  alignment: Alignment.center,
                  child: Text(
                    "<no data>",
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hexDump,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      asciiDump,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
