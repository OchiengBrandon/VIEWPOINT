import 'package:flutter/material.dart';
import 'package:short_video_app/screens/home_screen.dart';
import 'package:short_video_app/widgets/custom_button.dart';
import 'package:short_video_app/widgets/footer_text.dart';
import 'package:short_video_app/widgets/header.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();

  void _signUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; // Reset error message
      });

      String? result = await _authService.signUp(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
        _phoneController.text,
      );

      setState(() {
        _isLoading = false;
        _errorMessage = result; // Set error message if exists
      });

      if (result == null) {
        // Navigate to the home screen or show a success message
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) {
            return const HomeScreen();
          }),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HeaderWidget(
                  imagePath: "assets/images/Login Page.png",
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 289,
                        height: 53,
                        child: TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                              labelText: "Username",
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder()),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your username';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 289,
                        height: 53,
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                              labelText: "Email",
                              prefixIcon: Icon(Icons.email),
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
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 289,
                        height: 53,
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder()),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 289,
                        height: 53,
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                              labelText: "Phone Number",
                              prefixIcon: Icon(Icons.phone),
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              theText: "S I G N U P",
                              fillColor: Theme.of(context).colorScheme.surface,
                              textColor:
                                  Theme.of(context).colorScheme.secondary,
                              borderColor: Colors.white,
                              onTap: _signUp,
                            ),
                      const SizedBox(height: 5),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to the login screen
                        },
                        child: const Text(
                          "or login",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                              fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
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
}
