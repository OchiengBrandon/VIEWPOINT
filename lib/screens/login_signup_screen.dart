import 'package:flutter/material.dart';
import 'package:short_video_app/screens/login_screen.dart';
import 'package:short_video_app/screens/signup_screen.dart';
import 'package:short_video_app/utils/colors/colors.dart';
import 'package:short_video_app/widgets/custom_button.dart';
import 'package:short_video_app/widgets/footer_text.dart';
import 'package:short_video_app/widgets/header.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: HeaderWidget(
                    imagePath: "assets/images/Login Page.png",
                  ),
                ),
                const SizedBox(
                  height: 100,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CustomButton(
                    theText: "L O G I N",
                    fillColor: Colors.white,
                    textColor: autheColorFill,
                    borderColor: Theme.of(context).colorScheme.surface,
                    onTap: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()));
                    },
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                CustomButton(
                  theText: "S I G N U P",
                  fillColor: autheColorFill,
                  textColor: Colors.white,
                  borderColor: Theme.of(context).colorScheme.surface,
                  onTap: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpScreen()));
                  },
                ),
                const SizedBox(
                  height: 100,
                ),
                const FooterText()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
