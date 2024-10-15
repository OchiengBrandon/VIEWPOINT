import 'package:flutter/material.dart';
import 'package:short_video_app/screens/home_screen.dart';
import 'package:short_video_app/services/auth_service.dart';
import 'package:short_video_app/utils/colors/colors.dart';
import 'package:short_video_app/widgets/custom_button.dart';
import 'package:short_video_app/widgets/footer_text.dart';
import 'package:short_video_app/widgets/header.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false; // Add this line
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 120),
                const HeaderWidget(
                  imagePath: "assets/images/Login Page.png",
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 289,
                        height: 53,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                              labelText: "Email",
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: autheColorFill,
                              ),
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 289,
                        height: 53,
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.w300, fontSize: 16),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: autheColorFill,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      _isLoading // Check loading state
                          ? const CircularProgressIndicator() // Show loading indicator
                          : CustomButton(
                              theText: "L O G I N",
                              fillColor: Theme.of(context).colorScheme.surface,
                              textColor:
                                  Theme.of(context).colorScheme.secondary,
                              borderColor: Colors.white,
                              onTap: _login,
                            ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpScreen()),
                          );
                        },
                        child: const Text(
                          "or create account",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 100),
                      const FooterText()
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true; // Set loading to true
      });

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      String? result = await _authService.login(email, password);
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading to false
        });
        if (result == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
