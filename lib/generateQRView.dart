/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as devtools show log;
import 'package:http/http.dart' as http;
import 'package:firstly/services/auth/MSSQLAuthProvider.dart';
import 'package:firstly/show_error_dialog.dart';

class GenerateQRView extends StatefulWidget {
  const GenerateQRView({super.key});

  @override
  _GenerateQRViewState createState() => _GenerateQRViewState();
}

class _GenerateQRViewState extends State<GenerateQRView> {
  final _formKey = GlobalKey<FormState>();
  final MSSQLAuthProvider _authProvider = MSSQLAuthProvider();
  final TextEditingController _titleController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  // Data from backend
  Map<String, dynamic> userProfile = {};
  List<dynamic> userEducation = [];
  List<dynamic> userWorkExperience = [];
  List<dynamic> userCertifications = [];
  List<dynamic> userSkills = [];

  // Selected IDs
  List<int> selectedEduBacIDs = [];
  List<int> selectedCerIDs = [];
  List<int> selectedSkillIDs = [];
  List<int> selectedWorkExpIDs = []; // Separate list for Work Experience

  @override
  void initState() {
    super.initState();
    _fetchUserDetails(); // Fetch user details on page load
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authProvider.initialize();
      final user = _authProvider.currentUser;

      if (user != null) {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/showDetailsQR'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'accountID': user.accountID}),
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          final details = jsonDecode(response.body);
          setState(() {
            userProfile = details['profile'];
            userEducation = details['education'];
            userWorkExperience = details['workExperience'];
            userCertifications = details['certification'];
            userSkills = details['skills']; // Assign skills data
          });
        } else if (response.statusCode == 404) {
          errorMessage =
              'Please Create Your Profile Before Generating CV QR Code';
        } else {
          setState(() {
            errorMessage = 'Failed to fetch user details';
          });
          if (!mounted) return;
        }
      } else {
        setState(() {
          errorMessage = 'User not logged in.';
        });
        if (!mounted) return;
      }
    } catch (e) {
      devtools.log('Error fetching user details: $e');
      setState(() {
        errorMessage = 'Please Create Your Profile Before View CV.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateQRCode() async {
    // Validate title and selections
    final title = _titleController.text.trim();

    // Check if the title is empty
    if (title.isEmpty) {
      await showErrorDialog(
        context,
        'Title cannot be empty.',
      );
      return; // Stop execution if title is empty
    }

    // Check if at least one section is selected
    if (selectedEduBacIDs.isEmpty &&
        selectedWorkExpIDs.isEmpty &&
        selectedSkillIDs.isEmpty &&
        selectedCerIDs.isEmpty) {
      await showErrorDialog(
        context,
        'Please choose at least one from Education, Work Experience, Skills, or Certifications.',
      );
      return; // Stop execution if no sections are selected
    }

    if (!mounted) return; // Check if the widget is still mounted
    setState(() {
      isLoading = true;
    });

    final user = _authProvider.currentUser;
    if (user != null) {
      // Prepare IDs as strings with semicolons
      final EduBacID = '${selectedEduBacIDs.map((e) => '$e').join(';')};';
      final CerID = '${selectedCerIDs.map((e) => '$e').join(';')};';
      final SoftID = '${selectedSkillIDs.map((e) => '$e').join(';')};';
      final WorkExpID = '${selectedWorkExpIDs.map((e) => '$e').join(';')};';
      final PerID =
          userProfile['perID'] != null ? '${userProfile['perID']};' : '';

      // Log values for debugging
      devtools.log("EduBacID: $EduBacID");
      devtools.log("CerID: $CerID");
      devtools.log("SoftID: $SoftID");
      devtools.log("Title: $title");

      // Pass the title along with other parameters
      final response = await _authProvider.generateQRCode(
        userID: user.accountID.toString(),
        perID: PerID,
        eduBacID: EduBacID,
        cerID: CerID,
        softID: SoftID,
        workExpID: WorkExpID,
        title: title, // Pass the title here
      );

      if (response != null && mounted) {
        devtools.log('QR Code Generated Successfully');

        // Show the generated QR code
        _showGeneratedQRCode(response['qrCodeImage']);
      } else if (mounted) {
        setState(() {
          errorMessage = 'Failed to generate QR code. Please try again later.';
        });
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

// Function to display the generated QR code image
  void _showGeneratedQRCode(String qrCodeImage) {
    final qrCodeImageBytes = base64Decode(qrCodeImage);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generated QR Code'),
          content: Image.memory(qrCodeImageBytes),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'qr_generated');
                Navigator.pop(
                    context, 'qr_generated'); // Pop back to the QR list page
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await showErrorDialog(
            context,
            errorMessage!,
          );
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text('Generate QR', style: AppWidget.headlineTextFieldStyle()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title input field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile Section
                      const Text('Profile:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ListTile(
                        title: Text(userProfile['name'] ?? 'No Name'),
                        subtitle: Text(userProfile['email'] ?? 'No Email'),
                      ),
                      const SizedBox(height: 16),

                      // Education Section
                      const Text('Education:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ExpansionTile(
                        title: const Text('Select Education'),
                        children: userEducation.map((edu) {
                          return CheckboxListTile(
                            value: selectedEduBacIDs.contains(edu['eduBacID']),
                            title: Text(edu['institute_name'] ?? ''),
                            subtitle: Text(edu['level'] ?? ''),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedEduBacIDs.add(edu['eduBacID']);
                                } else {
                                  selectedEduBacIDs.remove(edu['eduBacID']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Work Experience Section
                      const Text('Work Experience:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ExpansionTile(
                        title: const Text('Select Work Experience'),
                        children: userWorkExperience.map((work) {
                          return CheckboxListTile(
                            value:
                                selectedWorkExpIDs.contains(work['workExpID']),
                            title: Text(work['job_title'] ?? ''),
                            subtitle: Text(work['company_name'] ?? ''),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedWorkExpIDs.add(work['workExpID']);
                                } else {
                                  selectedWorkExpIDs.remove(work['workExpID']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Skills Section
                      const Text('Skills:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ExpansionTile(
                        title: const Text('Select Skills'),
                        children: userSkills.map((skill) {
                          return CheckboxListTile(
                            value: selectedSkillIDs.contains(skill['SoftID']),
                            title: Text(skill['skill'] ?? ''),
                            subtitle: Text(skill['description'] ?? ''),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedSkillIDs.add(skill['SoftID']);
                                } else {
                                  selectedSkillIDs.remove(skill['SoftID']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Certification Section
                      const Text('Certifications:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ExpansionTile(
                        title: const Text('Select Certifications'),
                        children: userCertifications.map((cert) {
                          return CheckboxListTile(
                            value: selectedCerIDs.contains(cert['cerID']),
                            title: Text(cert['name'] ?? ''),
                            subtitle: Text(cert['issuer'] ?? ''),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedCerIDs.add(cert['cerID']);
                                } else {
                                  selectedCerIDs.remove(cert['cerID']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Generate QR Code Button
                      Center(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _generateQRCode,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Generate QR Code'),
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
