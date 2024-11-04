/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:firstly/services/auth/MSSQLAuthProvider.dart';

class ViewStoredCredentialScreen extends StatefulWidget {
  const ViewStoredCredentialScreen({super.key});

  @override
  _ViewStoredCredentialScreenState createState() =>
      _ViewStoredCredentialScreenState();
}

class _ViewStoredCredentialScreenState
    extends State<ViewStoredCredentialScreen> {
  List<dynamic> storedCredentials = [];
  bool isLoading = false;
  String? noDataMessage;

  Future<void> fetchStoredCredentials() async {
    setState(() {
      isLoading = true;
      noDataMessage = null;
    });

    final MSSQLAuthProvider authProvider = MSSQLAuthProvider();
    await authProvider.initialize();
    final user = authProvider.currentUser;

    if (user != null) {
      try {
        devtools.log("Fetching stored credentials... ${user.email}");
        final response = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/receiveExistedCredential'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({'holder': user.email}),
        );
        devtools.log(response.body);
        if (response.statusCode == 200) {
          devtools.log("Successfully fetched stored credentials.");
          final data = json.decode(response.body);
          setState(() {
            storedCredentials = data['credentials'] ?? [];
            isLoading = false;
          });
        } else if (response.statusCode == 404) {
          setState(() {
            isLoading = false;
            noDataMessage = "No stored credentials found.";
          });
        } else {
          setState(() {
            isLoading = false;
            noDataMessage = "Error fetching credentials.";
          });
          devtools.log('Error fetching credentials: ${response.body}');
        }
      } catch (error) {
        setState(() {
          isLoading = false;
          noDataMessage = "Error fetching data.";
        });
        devtools.log('Error occurred: $error');
      }
    } else {
      setState(() {
        isLoading = false;
        noDataMessage = "User not found.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        elevation: 0,
        title: Text('View Stored Certifications',
            style: AppWidget.headlineTextFieldStyle()),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Your Stored Certifications Information',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  noDataMessage != null
                      ? Text(
                          noDataMessage!,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                        )
                      : storedCredentials.isEmpty
                          ? ElevatedButton(
                              onPressed: fetchStoredCredentials,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF171B63),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60.0, vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              child: const Text(
                                'Fetch Stored Certifications',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15.0),
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: storedCredentials.length,
                                itemBuilder: (context, index) {
                                  final credential = storedCredentials[index];
                                  final String status = credential['status'];
                                  final Color statusColor = status == 'Accepted'
                                      ? Colors.green
                                      : Colors.red;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: ListTile(
                                      title:
                                          Text('Name: ${credential['name']}'),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Email: ${credential['email']}'),
                                          Text('Type: ${credential['type']}'),
                                          Text(
                                              'Issuer: ${credential['issuer']}'),
                                          Text(
                                              'Description: ${credential['description']}'),
                                          Text(
                                              'Acquired Date: ${credential['acquiredDate']}'),
                                          Text(
                                            'Status: $status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ],
              ),
      ),
    );
  }
}

class AppWidget {
  static TextStyle headlineTextFieldStyle() {
    return const TextStyle(
        color: Color(0xFF171B63), fontSize: 20.0, fontWeight: FontWeight.bold);
  }

  static TextStyle semiBoldTextFieldStyle() {
    return const TextStyle(
        color: Color(0xFF171B63), fontSize: 16.0, fontWeight: FontWeight.w600);
  }
}
