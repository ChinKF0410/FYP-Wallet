/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:firstly/education_info.dart';
import 'package:firstly/profile_info.dart';
import 'package:firstly/softskill_info.dart';
import 'package:firstly/work_info.dart';
import 'credential2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as devtools show log;
import 'package:http/http.dart' as http;

class SelfCredentialPage1 extends StatefulWidget {
  const SelfCredentialPage1({super.key});

  @override
  _SelfCredentialPage1State createState() => _SelfCredentialPage1State();
}

class _SelfCredentialPage1State extends State<SelfCredentialPage1>
    with WidgetsBindingObserver {
  bool isProfileAvailable = false; // Initially set to false
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (!mounted) return;
    WidgetsBinding.instance.addObserver(this);
    if (!mounted) return;
    // Add this line to listen for lifecycle changes
    _fetchUserProfile();
    if (!mounted) return;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove the observer
    super.dispose();
  }

  // Lifecycle method
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check the user profile when the app is resumed
      _fetchUserProfile();
      if (!mounted) return;
    }
  }

  // Fetch accountID from SharedPreferences
  Future<int?> _getAccountID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('accountID');
    } catch (e) {
      devtools.log('Error retrieving accountID: $e');
      return null;
    }
  }

  // Fetch user profile from the server
  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    if (!mounted) return;

    final accountID = await _getAccountID();
    if (!mounted) return;

    if (accountID == null) {
      devtools.log('No accountID found');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/api/getCVProfile?accountID=$accountID'),
      );
      if (!mounted) return;

      // Handle the response based on status code
      if (response.statusCode == 404) {
        devtools.log('Profile not found');
        setState(() {
          isProfileAvailable = false; // Disable buttons
        });
      } else if (response.statusCode == 200) {
        devtools.log('Profile found');
        setState(() {
          isProfileAvailable = true; // Enable buttons
        });
      } else {
        devtools.log('Unexpected status code: ${response.statusCode}');
        setState(() {
          isProfileAvailable = false;
        });
      }
    } catch (e) {
      devtools.log('Error fetching profile: $e');
      setState(() {
        isProfileAvailable = false; // Disable buttons if profile not found
      });
    } finally {
      setState(() {
        _isLoading = false; // Stop loading after the fetch
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: const Color(0xFF171B63),
        title: const Padding(
          padding: EdgeInsets.only(bottom: 10.0),
          child: Text(
            'Wallet',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildInfoBox(
                      context,
                      icon: const Icon(Icons.person,
                          size: 50.0, color: Color(0xFF171B63)),
                      label: 'Profile',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return const ProfileInfoPage(); // Navigate to ProfileInfoPage
                            },
                          ),
                        );
                        // Refresh the state after returning from ProfileInfoPage
                        setState(() {
                          _fetchUserProfile();
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    _buildInfoBox(
                      context,
                      icon: const Icon(Icons.school,
                          size: 50.0, color: Color(0xFF171B63)),
                      label: 'Education',
                      onTap: isProfileAvailable
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return const EducationInfoPage(); // Navigate to EducationPage
                                  },
                                ),
                              )
                          : null, // Disabled if profile is unavailable
                    ),
                    const SizedBox(height: 20.0),
                    _buildInfoBox(
                      context,
                      icon: const Icon(Icons.star,
                          size: 50.0, color: Color(0xFF171B63)),
                      label: 'Certification',
                      onTap: isProfileAvailable
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return const Credential2(); // Navigate to CertificationPage
                                  },
                                ),
                              )
                          : null,
                    ),
                    const SizedBox(height: 20.0),
                    _buildInfoBox(
                      context,
                      icon: const Icon(Icons.work,
                          size: 50.0, color: Color(0xFF171B63)),
                      label: 'Work Experience',
                      onTap: isProfileAvailable
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return const WorkInfoPage(); // Navigate to WorkExperiencePage
                                  },
                                ),
                              )
                          : null,
                    ),
                    const SizedBox(height: 20.0),
                    _buildInfoBox(
                      context,
                      icon: const Icon(Icons.lightbulb,
                          size: 50.0, color: Color(0xFF171B63)),
                      label: 'Soft Skill',
                      onTap: isProfileAvailable
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return const SoftSkillInfoPage(); // Navigate to SoftSkillPage
                                  },
                                ),
                              )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoBox(
    BuildContext context, {
    Icon? icon,
    String? imagePath,
    required String label,
    required VoidCallback? onTap, // Set this as nullable
  }) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Opacity(
      opacity:
          onTap != null ? 1.0 : 0.5, // Reduce opacity if button is disabled
      child: Container(
        width: screenWidth * 0.9,
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
          onTap: onTap, // Only assign if not null
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: icon != null
                    ? icon
                    : Image.asset(
                        imagePath!,
                        width: 45.0,
                        height: 45.0,
                      ),
              ),
              const SizedBox(width: 20.0),
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
