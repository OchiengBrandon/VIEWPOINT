import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String theText;
  final Color fillColor;
  final Color textColor;
  final Color borderColor;
  final Function() onTap;
  const CustomButton({
    super.key,
    required this.theText,
    required this.fillColor,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 41,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(19),
          ),
          border: Border.all(color: borderColor, width: 1.5),
          color: fillColor,
        ),
        child: Center(
          child: Text(
            theText,
            style: TextStyle(
                fontSize: 18, color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
