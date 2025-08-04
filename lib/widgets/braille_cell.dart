import 'package:flutter/material.dart';
import 'package:mini_music_app/widgets/braille_cell_pin.dart';

class BrailleCell extends StatelessWidget {
  final int value;

  const BrailleCell({super.key, required this.value});

  List<bool> patternToCircleStates(int value) {
    int currentValue = value;
    final actuatorValues = [128, 64, 32, 16, 8, 4, 2, 1];
    final circleStates = List.generate(8, (_) => false);

    for (int i = 0; i < actuatorValues.length; i++) {
      if (currentValue - actuatorValues[i] >= 0) {
        currentValue -= actuatorValues[i];
        circleStates[i] = true;
      }
    }

    return circleStates;
  }

  @override
  Widget build(BuildContext context) {
    final circleStates = patternToCircleStates(value);
    return Row(
      children: [
        Column(
          children: [
            BrailleCellPin(isActivated: circleStates[7]),
            BrailleCellPin(isActivated: circleStates[6]),
            BrailleCellPin(isActivated: circleStates[5]),
            BrailleCellPin(isActivated: circleStates[1]),
          ],
        ),
        Column(
          children: [
            BrailleCellPin(isActivated: circleStates[4]),
            BrailleCellPin(isActivated: circleStates[3]),
            BrailleCellPin(isActivated: circleStates[2]),
            BrailleCellPin(isActivated: circleStates[0]),
          ],
        ),
      ],
    );
  }
}
