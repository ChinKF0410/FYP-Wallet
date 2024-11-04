/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'confirmation_cred.dart';
import 'viewStoredCredential.dart';

class ReceiveCre extends StatelessWidget {
  const ReceiveCre({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable the back navigation icon
        centerTitle: true,
        backgroundColor: const Color(0xFF171B63),
        title: const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Certifications',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Received Credential with Icon
              _buildCredentialField(
                context,
                const Icon(Icons.verified,
                    size: 50.0, color: Color(0xFF171B63)),
                'Received Certifications',
                true, // Pass true for received credentials
              ),
              const SizedBox(height: 20.0), // Space between the two containers
              // Pending Credential with Icon
              _buildCredentialField(
                context,
                const Icon(Icons.pending, size: 50.0, color: Color(0xFF171B63)),
                'Pending Certifications',
                false, // Pass false for pending credentials
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialField(
      BuildContext context, Widget iconOrImage, String label, bool isReceived) {
    // Get the screen width using MediaQuery
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.9, // Set width to 90% of the screen width
      height: 90.0,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.transparent,
      ),
      child: InkWell(
        onTap: () {
          // Navigate to the appropriate detail page based on isReceived
          if (isReceived) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ViewStoredCredentialScreen(), // Link to the ViewStoredCredentialScreen
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ConfirmationScreen(), // Link to the ConfirmationScreen
              ),
            );
          }
        },
        child: SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: iconOrImage, // This can now be an Icon or Image
              ),
              const SizedBox(
                width: 20.0,
              ), // Space between icon/image and text
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20.0,
                  color: Color(0xFF171B63),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
