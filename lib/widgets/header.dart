import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final String imagePath;
  const HeaderWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: Column(
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(imagePath), fit: BoxFit.fill),
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20)),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            "S H O R T  V I D E O S  F O R  L I F E !",
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }
}
