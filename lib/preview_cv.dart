/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:developer' as devtools show log;

class ViewCV extends StatefulWidget {
  const ViewCV({super.key});

  @override
  _ViewCVState createState() => _ViewCVState();
}

class _ViewCVState extends State<ViewCV> {
  Map<String, dynamic>? _cvData; // To hold the CV data
  bool _isLoading = true; // To show a loading spinner while fetching data
  String? _errorMessage; // To store any error messages

  @override
  void initState() {
    super.initState();
    _fetchCVData(); // Fetch data when the page is initialized
  }

  // Fetch CV data from the backend
  Future<void> _fetchCVData() async {
    final accountID = await _getAccountID();
    if (accountID == null) {
      setState(() {
        _errorMessage = "Failed to retrieve account ID.";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/showDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accountID': accountID}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _cvData = jsonDecode(response.body); // Parse the JSON response
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        _showNotFoundDialog(); // Show dialog if status code is 404
      } else {
        setState(() {
          _errorMessage = "Failed to fetch CV details.";
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error fetching data: $error";
        _isLoading = false;
      });
      devtools.log('Error fetching CV data: $error');
    }
  }

  // Show a dialog if the response is 404 (CV not found)
  Future<void> _showNotFoundDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('CV Not Found'),
          content: const Text('Please Create Your Profile Before View CV.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context)
                    .pop(); // Navigate back to the previous page
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Get accountID from SharedPreferences
  Future<int?> _getAccountID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountID = prefs.getInt('accountID');
      devtools.log('Retrieved accountID: $accountID');
      return accountID;
    } catch (e) {
      devtools.log('Error retrieving accountID: $e');
      return null;
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
        title: Text('View CV', style: AppWidget.headlineTextFieldStyle()),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading spinner
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(Icons.person, 'Profile Information'),
                      _buildProfileSection(_cvData!['profile']),
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.school, 'Education Information'),
                      _cvData!['education'] != null
                          ? _buildEducationSection(_cvData!['education'])
                          : const Text("No education information available."),
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.work, 'Work Experience'),
                      _cvData!['workExperience'] != null
                          ? _buildWorkSection(_cvData!['workExperience'])
                          : const Text("No work experience available."),
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.lightbulb, 'Skills'),
                      _cvData!['skills'] != null
                          ? _buildSoftSkillsSection(_cvData!['skills'])
                          : const Text("No skills information available."),
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.star, 'Certifications'),
                      _cvData!['certification'] != null
                          ? _buildCertificationSection(
                              _cvData!['certification'])
                          : const Text(
                              "No certification information available."),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  // Build section title widget
  Widget _buildSectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF171B63)),
          const SizedBox(width: 8.0),
          Text(
            title,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Display profile information
  Widget _buildProfileSection(Map<String, dynamic>? profile) {
    if (profile == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (profile['profile_image_path'] != null)
          Image.memory(
            base64Decode(profile[
                'profile_image_path']), // Decode the base64 photo if available
            width: 100,
            height: 100,
          ),
        _buildInfoBox([
          'Name: ${profile['name']}',
          'Age: ${profile['age']}',
          'Email: ${profile['email']}',
          'Phone: ${profile['phone']}',
          'Address: ${profile['address']}',
          'Description: ${profile['description']}',
        ]),
      ],
    );
  }

  // Display education information
  Widget _buildEducationSection(List<dynamic> education) {
    return Column(
      children: education.map((edu) {
        return Column(
          children: [
            _buildInfoBox([
              'Level: ${edu['level']}',
              'Field of Study: ${edu['field_of_study']}',
              'Institute Name: ${edu['institute_name']}',
              'Country: ${edu['institute_country']}',
              'City: ${edu['institute_city']}',
              'Start Date: ${edu['start_date']}',
              'End Date: ${edu['end_date']}',
            ]),
            const SizedBox(
                height: 5), // Less space between items in the same category
          ],
        );
      }).toList(),
    );
  }

  // Display work experience information
  Widget _buildWorkSection(List<dynamic> workExperience) {
    return Column(
      children: workExperience.map((work) {
        return Column(
          children: [
            _buildInfoBox([
              'Job Title: ${work['job_title']}',
              'Company: ${work['company_name']}',
              'Industry: ${work['industry']}',
              'Country: ${work['country']}',
              'State: ${work['state']}',
              'City: ${work['city']}',
              'Description: ${work['description']}',
              'Start Date: ${work['start_date']}',
              'End Date: ${work['end_date']}',
            ]),
            const SizedBox(
                height: 5), // Less space between items in the same category
          ],
        );
      }).toList(),
    );
  }

// Display skills information, including SoftLevel
  Widget _buildSoftSkillsSection(List<dynamic> softSkills) {
    return Column(
      children: softSkills.map((skill) {
        return Column(
          children: [
            _buildInfoBox([
              'Skill: ${skill['skill']}', // Skill name
              'Description: ${skill['description']}', // Skill description
              'Level: ${_mapSoftLevelToText(skill['level'])}', // Map the SoftLevel to human-readable text
            ]),
            const SizedBox(height: 5),
          ],
        );
      }).toList(),
    );
  }

// Helper function to map SoftLevel to text
  String _mapSoftLevelToText(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return 'Unknown'; // Fallback if SoftLevel is outside the expected range
    }
  }

  // Display certifications information
  Widget _buildCertificationSection(List<dynamic> certifications) {
    return Column(
      children: certifications.map((cert) {
        return Column(
          children: [
            _buildInfoBox([
              'Title: ${cert['name']}',
              'Email: ${cert['email']}',
              'Type: ${cert['type']}',
              'Issuer: ${cert['issuer']}',
              'Description: ${cert['description']}',
              'Acquired Date: ${cert['acquiredDate']}',
            ]),
            const SizedBox(
                height: 5), // Less space between items in the same category
          ],
        );
      }).toList(),
    );
  }

  // Helper function to create a box of information
  Widget _buildInfoBox(List<String> info) {
    return Container(
      margin: const EdgeInsets.symmetric(
          vertical: 5.0), // Less margin between items
      padding: const EdgeInsets.all(20.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: info.map((line) {
          return Text(
            line,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          );
        }).toList(),
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
