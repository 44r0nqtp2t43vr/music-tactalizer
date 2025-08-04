import 'package:flutter/material.dart';
import 'package:mini_music_app/widgets/braille_cell.dart';

class Station extends StatelessWidget {
  final String data;

  const Station({super.key, required this.data});

  List<int> processString(String input) {
    // 1. Remove the first and last character
    String trimmed = input.substring(1, input.length - 1);

    // 2. Split into groups of 3 characters
    List<String> groups = [];
    for (int i = 0; i < trimmed.length; i += 3) {
      groups.add(trimmed.substring(i, i + 3));
    }

    // 3. Convert each group into an integer
    List<int> parsedNumbers = groups.map(int.parse).toList();

    return parsedNumbers;
  }

  @override
  Widget build(BuildContext context) {
    final patternList = processString(data);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BrailleCell(value: patternList[0]),
        BrailleCell(value: patternList[1]),
        SizedBox(width: 12),
        BrailleCell(value: patternList[2]),
        BrailleCell(value: patternList[3]),
        SizedBox(width: 12),
        BrailleCell(value: patternList[4]),
        BrailleCell(value: patternList[5]),
        SizedBox(width: 12),
        BrailleCell(value: patternList[6]),
        BrailleCell(value: patternList[7]),
        SizedBox(width: 12),
        BrailleCell(value: patternList[8]),
        BrailleCell(value: patternList[9]),
      ],
    );
  }
}
