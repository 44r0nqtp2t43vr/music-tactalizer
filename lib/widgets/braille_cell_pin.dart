import 'package:flutter/material.dart';

class BrailleCellPin extends StatelessWidget {
  final bool isActivated;

  const BrailleCellPin({super.key, required this.isActivated});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center, // Ensures circle stays centered
      child: Container(
        width: isActivated ? 14.0 : 10.0, // Size changes
        height: isActivated ? 14.0 : 10.0,
        decoration: BoxDecoration(
          color: isActivated ? Colors.white : Colors.black,
          shape: BoxShape.circle,
          border: isActivated ? Border.all(color: Colors.black, width: 1.0) : null,
        ),
      ),
    );
  }
}
