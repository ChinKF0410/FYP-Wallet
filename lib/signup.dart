/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart'; // Import the LoginPage or correct path
import 'dart:developer' as devtools show log;

class AppWidget {
  static TextStyle headlineTextFieldStyle() {
    return const TextStyle(
      color: Color(0xFF171B63),
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle semiBoldTextFieldStyle() {
    return const TextStyle(
      color: Color(0xFF171B63),
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle savedTextFieldStyle() {
    return const TextStyle(
      color: Colors.black,
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  // Add this line
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  Future<void> _register(String email, String password) async {
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }

    if (password != _confirmPasswordController.text) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    final passwordRegExp =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@_$!%*?&#]).{8,}$');

    if (!passwordRegExp.hasMatch(password)) {
      _showErrorDialog(
          '''Password must be at least 8 characters long and contain at least: 
      -1 uppercase letter
      -1 lowercase letter
      -1 digit
      -1 symbol''');
      return;
    }

    // Add this block
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (!mounted) return;
      devtools.log(response.statusCode.toString());

      if (response.statusCode == 201) {
        _showSuccessDialog(); // Show success dialog when registration is successful
      } else if (response.statusCode == 400) {
        // Handle specific case where email is already in use
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Unknown error';
        _showErrorDialog('Registration failed: $errorMessage');
      } else if (response.statusCode == 500) {
        // Handle server errors
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Server error occurred';
        _showErrorDialog('Registration failed: $errorMessage');
      } else {
        // Generic error handling for other status codes
        _showErrorDialog('Registration failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again later.');
      devtools.log('Registration error: $e');
    } finally {
      // Add this block
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Registration successful!'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the success dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginView()),
                ); // Navigate to the login page
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notice'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Sign Up',
            style: AppWidget.headlineTextFieldStyle(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: 'Email:',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: AppWidget.savedTextFieldStyle(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: 'Password:',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _togglePasswordVisibility,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: AppWidget.savedTextFieldStyle(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: 'Confirm Password:',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: _toggleConfirmPasswordVisibility,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: AppWidget.savedTextFieldStyle(),
              ),
              const SizedBox(height: 50),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          final email = _emailController.text;
                          final password = _passwordController.text;
                          _register(email, password);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF171B63),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50.0,
                      vertical: 15.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Register',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
