/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as devtools show log;

// After user login
Future<void> saveUserEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userEmail', email);
}

class ReceiveDialog extends StatefulWidget {
  @override
  _ReceiveDialogState createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends State<ReceiveDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(Duration(seconds: 60), (timer) async {
      await _checkForNewCredentials();
    });
  }

  Future<void> _checkForNewCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email =
        prefs.getString('userEmail'); // Get the email from shared preferences

    if (email == null) {
      devtools.log('User email not found. Please log in again.');
      return;
    }

    final response = await http
        .get(Uri.parse('http://127.0.0.1:4000/api/receiveCredentials/$email'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['credentialsAvailable'] == true) {
        _showCertificationDialog(
            context); // Show the dialog if new credentials are available
      }
    } else {
      // Handle error response if needed
      devtools
          .log('Error checking for new credentials: ${response.statusCode}');
    }
  }

  void _showCertificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Certification Received'),
          content: Text(
              'You have received a new certification. Do you want to accept it?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Handle "Decline" action here
              },
              child: Text('Decline'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Handle "Accept" action here
              },
              child: Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Certification Wallet')),
        body: Center(child: Text('Waiting for Certification...')),
      ),
    );
  }
}
