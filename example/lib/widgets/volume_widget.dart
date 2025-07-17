import 'package:flutter/material.dart';
import 'package:zebra_rfid_sdk/zebra_rfid_sdk.dart';

class VolumeWidget extends StatefulWidget {
  final BeeperVolume initialSetting;
  const VolumeWidget({super.key, required this.initialSetting});

  @override
  State<VolumeWidget> createState() => _VolumeWidgetState();
}

class _VolumeWidgetState extends State<VolumeWidget> {
  late int _currentSetting;

  @override
  void initState() {
    super.initState();
    _currentSetting = widget.initialSetting.index;
  }

  @override
  void didUpdateWidget(covariant VolumeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _currentSetting = widget.initialSetting.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RotatedBox(
          quarterTurns: 3,
          child: Slider(
            min: 0,
            max: 3,
            onChanged: (v) => {
              setState(() {
                _currentSetting = v.toInt();
              }),
              ZebraRfidSdk.setBeeperVolume(BeeperVolume.values[_currentSetting]),
            },
            value: _currentSetting.toDouble(),
          ),
        ),
        Icon(
          _currentSetting == 0
              ? Icons.volume_off
              : _currentSetting == 1
              ? Icons.volume_mute
              : _currentSetting == 2
              ? Icons.volume_down
              : Icons.volume_up,
          size: 28,
        ),
      ],
    );
  }
}
