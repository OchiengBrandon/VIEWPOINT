import 'package:flutter/material.dart';

class FooterText extends StatelessWidget {
  const FooterText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "M a d e w i t h  ",
            style: TextStyle(),
          ),
          Icon(
            Icons.favorite,
            color: Colors.red,
            size: 19,
          ),
          Text("  b y  b r a n d o n d e v e l o p e r")
        ],
      ),
    );
  }
}
