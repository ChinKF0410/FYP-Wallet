/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:firstly/services/auth/MSSQLAuthProvider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'show_error_dialog.dart';

class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  List<dynamic> credentials = [];
  bool isLoading = false;
  String? noDataMessage;
  String? authToken; // Store authToken globally after fetching

//let sainoforce know the status
  Future<void> sendMessage(String message, credential) async {
    final url = Uri.parse('http://127.0.0.1:3010/api/UpdateStatus');
    devtools.log("Message Send");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Set the content type to JSON
        },
        body: json.encode({
          'message': message,
          'credential': credential // Pass the message as a JSON body
        }),
      );

      if (response.statusCode == 200) {
        // Request was successful
        final responseData = json.decode(response.body);
        devtools.log('Message sent successfully: $responseData');
      } else {
        // Handle the error
        devtools.log(
            'Failed to send message. Status code: ${response.statusCode} + ${response.body}');
      }
    } catch (error) {
      // Handle exceptions
      devtools.log('Error sending message: $error');
    }
  }

  Future<void> fetchCredentials() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      noDataMessage = null;
    });
    if (!mounted) return;

    final MSSQLAuthProvider authProvider = MSSQLAuthProvider();
    await authProvider.initialize();
    if (!mounted) return;

    final user = authProvider.currentUser;

    if (user != null) {
      try {
        devtools.log("Step1: Initiating getWalletData call...");

        // Step 1: Call getWalletData API
        final walletResponse = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/getWalletData'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({'email': user.email}),
        );
        if (!mounted) return;

        if (walletResponse.statusCode == 200) {
          devtools.log("Step1.1: getWalletData successful.");

          final walletData = json.decode(walletResponse.body);
          devtools.log("Step1.2: Wallet data decoded.");
          devtools.log('Wallet Data: ${walletData.toString()}');

          // Ensure 'wallet' exists and then extract 'wallet_id'
          if (walletData.containsKey('wallet') &&
              walletData['wallet'].containsKey('wallet_id')) {
            final String walletID =
                walletData['wallet']['wallet_id'].toString();
            devtools.log("Wallet ID: $walletID");

            // Step 2: Call getAuthToken API using the retrieved walletID
            devtools.log("Step2: Initiating getAuthToken call...");

            final tokenResponse = await http.post(
              Uri.parse('http://127.0.0.1:4000/api/getAuthToken'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: json.encode({'walletID': walletID}),
            );
            if (!mounted) return;

            if (tokenResponse.statusCode == 200) {
              final tokenData = json.decode(tokenResponse.body);
              authToken = tokenData['token']; // Store the token globally
              devtools.log("Step2: Auth token received successfully.");

              // Step 3: Call fetchCredentials API (if needed)
              devtools.log("Step3: Fetching credentials using authToken...");

              final credentialsResponse = await http.post(
                Uri.parse('http://127.0.0.1:4000/api/receiveOffer'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization':
                      'Bearer $authToken', // Pass the auth token here
                },
                body: json.encode({'holder': user.email}),
              );
              if (!mounted) return;

              if (credentialsResponse.statusCode == 200) {
                final data = json.decode(credentialsResponse.body);
                if (!mounted) return;

                setState(() {
                  credentials = data['credentials'] ?? [];
                  isLoading = false;
                });
                devtools.log("Step3: Credentials fetched successfully.");
              } else {
                if (!mounted) return;

                setState(() {
                  isLoading = false;
                  noDataMessage = "No Pending Certification.";
                });
                devtools.log(
                    'Error fetching credentials: ${credentialsResponse.body}');
              }
            } else {
              if (!mounted) return;

              setState(() {
                isLoading = false;
                noDataMessage = "Error retrieving auth token.";
              });
              devtools
                  .log('Error retrieving auth token: ${tokenResponse.body}');
            }
          } else {
            if (!mounted) return;

            setState(() {
              isLoading = false;
              noDataMessage = "Invalid wallet data structure.";
            });
            devtools
                .log('Invalid wallet data structure: ${walletData.toString()}');
          }
        } else {
          if (!mounted) return;

          setState(() {
            isLoading = false;
            noDataMessage = "Error fetching wallet data.";
          });
          devtools.log('Error fetching wallet data: ${walletResponse.body}');
        }
      } catch (error) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          noDataMessage = "Error fetching data.";
        });
        devtools.log('Error occurred: $error');
      }
    } else {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        noDataMessage = "User not found.";
      });
    }
  }

// Function to call storeCredential and saveCVCertification APIs
  Future<void> storeCredential(Map<String, dynamic> credential) async {
    // Check if authToken is missing
    if (authToken == null) {
      if (mounted) {
        setState(() {
          noDataMessage = "Auth token not found.";
        });
      }
      return;
    }

    // Set loading state only if the widget is still mounted
    if (mounted) {
      setState(() {
        isLoading = true; // Set loading to true
      });
    }

    final MSSQLAuthProvider authProvider = MSSQLAuthProvider();
    await authProvider.initialize();
    final user = authProvider.currentUser;

    // Extract necessary fields for saveCVCertification API
    Map<String, dynamic> credentialData = {
      'accountID': user?.accountID.toString() ?? '0', // The user's account ID
      'CerName': credential['name'] ??
          'N/A', // The name from the credential //modify did
      'CerEmail': credential['email'] ?? 'N/A', // The email from the credential
      'CerType': credential['credentialType'] ?? 'N/A', // The credential type
      'CerIssuer': credential['issuerName'] ?? 'N/A', // The issuer name
      'CerDescription': credential['description'] ?? 'N/A', // The description
      'CerAcquiredDate': credential['issueDate'] ?? 'N/A', // The issue date
      'credExId': credential['cred_ex_id'], // Send the credential exchange ID
      'jwtToken': authToken, // The JWT token
    };
    devtools.log(credential['name']);
    devtools.log(credential['credentialType']);

    try {
      // First API call: storeCredential
      devtools.log("Calling storeCredential API...");
      final storeResponse = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/storeCredential'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'credExId': credentialData['credExId'], // The credential exchange ID
          'jwtToken': authToken,
        }),
      );

      if (storeResponse.statusCode == 200) {
        devtools.log('Credential stored successfully.');
        final storeData = json.decode(storeResponse.body);

        // If the first API call succeeds, move on to the second
        devtools.log('Proceeding to saveCVCertification API...');

        // Second API call: saveCVCertification
        final saveResponse = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/saveCVCertification'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(credentialData),
        );

        if (saveResponse.statusCode == 200) {
          devtools.log('Certification saved successfully.');
          final saveData = json.decode(saveResponse.body);

          if (mounted) {
            // Only update UI if the widget is still mounted
            setState(() {
              noDataMessage =
                  'Credential stored and certification saved successfully.';
            });

            // Optionally show a success dialog if still mounted
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Success'),
                  content: Text.rich(
                    TextSpan(
                      text: 'Credential ',
                      style:
                          const TextStyle(color: Colors.black), // Normal text
                      children: [
                        TextSpan(
                          text: credential['did'] ?? 'N/A', // 'did' in bold
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: ' stored successfully.', // Normal text
                        ),
                      ],
                    ),
                  ),
                  actions: [
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

          // Fetch credentials even if unmounted to ensure data is up-to-date
          await fetchCredentials();
        } else {
          devtools.log('Save Certification Error: ${saveResponse.body}');
          if (mounted) {
            setState(() {
              noDataMessage = "Failed to save certification.";
            });
          }
        }
      } else {
        devtools.log('Store Credential Error: ${storeResponse.body}');
        if (mounted) {
          setState(() {
            noDataMessage = "Failed to store credential.";
          });
        }
      }
    } catch (error) {
      devtools.log('Error storing credential: $error');
      if (mounted) {
        setState(() {
          noDataMessage = "Error occurred during storing credential.";
        });
      }
    } finally {
      // Set loading to false only if the widget is still mounted
      if (mounted) {
        setState(() {
          isLoading = false; // Set loading to false once done
        });
      }
    }
  }

  // Function to call deleteCredential API using POST method
  Future<void> deleteCredential(String credExId) async {
    if (authToken == null) {
      setState(() {
        noDataMessage = "Auth token not found.";
      });
      return;
    }

    try {
      devtools.log("Calling deleteCredential API using POST... \n$authToken");

      // Call the delete API with POST method
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/deleteCredential'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'credExId': credExId, 'jwtToken': authToken}),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        devtools.log('Credential deleted successfully.');
        final data = json.decode(response.body);
        devtools.log('Delete Response: $data');

        //heree
        showErrorDialog(context, "Deleted Successfully");

        setState(() {
          noDataMessage = 'Credential deleted successfully.';
        });

        // Refresh the page by fetching updated credentials
        await fetchCredentials();
        if (!mounted) return;
      } else {
        setState(() {
          noDataMessage = "Failed to delete credential.";
        });
        devtools.log('Error deleting credential: ${response.body}');
      }
    } catch (error) {
      setState(() {
        noDataMessage = "Error occurred during deleting credential.";
      });
      devtools.log('Error deleting credential: $error');
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
        title: Text('Pending Certification',
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
                    'Your Certification Information',
                    style: TextStyle(fontSize: 18, color: Colors.black),
                  ),
                  const SizedBox(height: 20),
                  noDataMessage != null
                      ? Text(
                          noDataMessage!,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                        )
                      : credentials.isEmpty
                          ? ElevatedButton(
                              onPressed: fetchCredentials,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF171B63),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60.0, vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              child: const Text(
                                'Fetch Certification',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15.0),
                              ),
                            )
                          : Expanded(
                              child: ListView.builder(
                                itemCount: credentials.length,
                                itemBuilder: (context, index) {
                                  final credential = credentials[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 16.0),
                                    child: ListTile(
                                      title: Text(
                                        '${credential['did'] ?? 'N/A'}', // Using the 'did' key from the credential directly
                                      ),
                                      subtitle: Text(
                                        '${credential['description'] ?? 'N/A'}', // Using the 'description' key from the credential directly
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              devtools.log(
                                                  'Received Certificatiom: ${credential['cred_ex_id']}');
                                              storeCredential(
                                                  credential); // Pass the entire credential object
                                              sendMessage("Credential Accepted",
                                                  credential);
                                            },
                                            child: const Text('Receive'),
                                          ),
                                          const SizedBox(width: 8.0),
                                          ElevatedButton(
                                            onPressed: () {
                                              devtools.log(
                                                  'Denied credential: ${credential['cred_ex_id']}');
                                              deleteCredential(credential[
                                                  'cred_ex_id']); // Call deleteCredential function
                                              sendMessage("Credential Rejected",
                                                  credential);
                                            },
                                            child: const Text('Deny'),
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
