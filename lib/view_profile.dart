/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

class ViewProfile extends StatefulWidget {
  const ViewProfile({super.key});

  @override
  _ViewProfileState createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  bool _isEditing = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobilePhoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _icNumberController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _phoneNumberError;
  String? _emailError;
  String? _icNumberError;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<int?> _getAccountID() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('accountID');
    } catch (e) {
      devtools.log('Error retrieving accountID: $e');
      return null;
    }
  }

  Future<void> _fetchProfileData() async {
    final accountID = await _getAccountID();
    if (accountID == null) {
      devtools.log('No accountID found');
      return;
    }

    devtools.log('Fetching profile data for accountID: $accountID');

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/api/getProfile?accountID=$accountID'),
      );

      devtools.log('Response status: ${response.statusCode}');
      devtools.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _firstNameController.text = data['First_Name'] ?? '';
          _lastNameController.text = data['Last_Name'] ?? '';
          _mobilePhoneController.text = data['Mobile_Number'] ?? '';
          _emailController.text = data['Email_Address'] ?? '';
          _icNumberController.text = data['Identity_Code'] ?? '';
        });
      } else if (response.statusCode == 404) {
        devtools.log('Profile not found, fetching login email');
        _getAccountID().then((accountID) {
          if (accountID != null) {
            _fetchEmailFromAccount(accountID); // Fetch email for a new user
          }
        });
      } else {
        devtools.log('Failed to load profile data: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching profile data: $e');
    }
  }

  Future<void> _fetchEmailFromAccount(int accountID) async {
    devtools.log('Fetching email for accountID: $accountID');
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/api/getAccountEmail?accountID=$accountID'),
      );

      devtools.log('Response status for email: ${response.statusCode}');
      devtools.log('Response body for email: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null && data['Email'] != null) {
          devtools.log('Email fetched successfully: ${data['Email']}');
          setState(() {
            _emailController.text = data['Email'] ?? '';
          });
        } else {
          devtools.log('Email not found in the response');
        }
      } else {
        devtools.log('Failed to load email data: ${response.statusCode}');
        devtools.log('Response body: ${response.body}');
      }
    } catch (e) {
      devtools.log('Error fetching email data: $e');
    }
  }

  Future<void> _saveProfileData() async {
    final accountID = await _getAccountID() ?? 0;

    final profileData = {
      'accountID': accountID,
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'mobilePhone': _mobilePhoneController.text.trim(),
      'email': _emailController.text.trim(),
      'icNumber': _icNumberController.text.trim(),
    };

    devtools.log('Saving profile data for accountID: $accountID');
    devtools.log('Profile data: $profileData');

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/saveProfile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(profileData),
      );

      devtools.log('Response status: ${response.statusCode}');
      devtools.log('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        devtools.log('Profile saved successfully');
      } else {
        devtools.log('Failed to save profile: ${response.statusCode}');
        devtools.log('Response body: ${response.body}');
      }
    } catch (e) {
      devtools.log('Error saving profile data: $e');
    }
  }

  void _validateFields() {
    setState(() {
      _firstNameError = _firstNameController.text.isEmpty
          ? 'First Name cannot be empty'
          : _validateName(_firstNameController.text, "First Name");

      _lastNameError = _lastNameController.text.isEmpty
          ? 'Last Name cannot be empty'
          : _validateName(_lastNameController.text, "Last Name");

      _icNumberError = _icNumberController.text.isEmpty
          ? 'IC Number cannot be empty'
          : _validateICNumber(_icNumberController.text);

      _phoneNumberError = _mobilePhoneController.text.isEmpty
          ? 'Mobile Phone cannot be empty'
          : _validatePhoneNumber(_mobilePhoneController.text);

      _emailError = _emailController.text.isEmpty
          ? 'Email cannot be empty'
          : _validateEmail(_emailController.text);
    });
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
            'Account Profile',
            style: AppWidget.headlineTextFieldStyle(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30.0),
              _buildInputField(
                  context, "First Name", _firstNameController, _isEditing,
                  errorText: _firstNameError, isNameField: true),
              const SizedBox(height: 20.0),
              _buildInputField(
                  context, "Last Name", _lastNameController, _isEditing,
                  errorText: _lastNameError, isNameField: true),
              const SizedBox(height: 20.0),
              _buildICNumberField(context, _icNumberController, _isEditing,
                  errorText: _icNumberError),
              const SizedBox(height: 20.0),
              _buildPhoneNumberField(
                  context, _mobilePhoneController, _isEditing,
                  errorText: _phoneNumberError),
              const SizedBox(height: 20.0),
              _buildInputField(context, "Email", _emailController, _isEditing,
                  errorText: _emailError),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    if (_isEditing) {
                      _validateFields();
                      if (_firstNameError == null &&
                          _lastNameError == null &&
                          _phoneNumberError == null &&
                          _emailError == null &&
                          _icNumberError == null) {
                        _saveProfileData(); // Save profile data
                        _isEditing = false;
                      }
                    } else {
                      _isEditing = true;
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF171B63),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 60.0,
                    vertical: 15.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  _isEditing ? 'Save' : 'Edit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(BuildContext context, String label,
      TextEditingController controller, bool isEnabled,
      {String? errorText, bool isNameField = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            style: isEnabled
                ? AppWidget.semiBoldTextFieldStyle()
                : AppWidget.savedTextFieldStyle(),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              border: InputBorder.none,
              hintText: label,
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            keyboardType: TextInputType.text,
            inputFormatters: isNameField
                ? [
                    FilteringTextInputFormatter.allow(RegExp('[a-zA-Z ]')),
                    LengthLimitingTextInputFormatter(30),
                  ]
                : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5.0),
          Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 12.0),
          ),
        ],
      ],
    );
  }

  Widget _buildICNumberField(
      BuildContext context, TextEditingController controller, bool isEnabled,
      {String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            style: isEnabled
                ? AppWidget.semiBoldTextFieldStyle()
                : AppWidget.savedTextFieldStyle(),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              border: InputBorder.none,
              hintText: 'IC Number',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5.0),
          Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 12.0),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneNumberField(
      BuildContext context, TextEditingController controller, bool isEnabled,
      {String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            style: isEnabled
                ? AppWidget.semiBoldTextFieldStyle()
                : AppWidget.savedTextFieldStyle(),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              border: InputBorder.none,
              hintText: 'Mobile Phone (Eg: 01xxxxxxxx)',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5.0),
          Text(
            errorText,
            style: const TextStyle(color: Colors.red, fontSize: 12.0),
          ),
        ],
      ],
    );
  }

  String? _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return 'Mobile Phone cannot be empty';
    } else if (!RegExp(r'^01\d{8,9}$').hasMatch(phoneNumber)) {
      return 'Invalid Phone Number.';
    }
    return null;
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email cannot be empty';
    } else if (!email.contains('@')) {
      return 'Invalid Email';
    }
    return null;
  }

  String? _validateICNumber(String icNumber) {
    if (icNumber.isEmpty) {
      return 'IC Number cannot be empty';
    } else if (icNumber.length != 12) {
      return 'Invalid IC Number';
    }
    return null;
  }

  String? _validateName(String name, String fieldName) {
    if (name.isEmpty) {
      return '$fieldName cannot be empty';
    } else if (RegExp(r'\d').hasMatch(name)) {
      return '$fieldName cannot contain digits';
    }
    return null;
  }
}
