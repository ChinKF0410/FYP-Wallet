/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as devtools show log;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

import 'package:firstly/show_error_dialog.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  _ProfileInfoPageState createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  XFile? _imageFile;
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  int PerID = 0;
  bool _isEditing = false; // Track whether the user is editing
  bool _isSaving = false; // Track whether the profile is being saved
  Map<String, String?> _errorMessages = {}; // Store error messages
  bool _isLoading = true; // Track whether data is being fetched
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchProfileData(); // Fetch profile data when the page is initialized
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
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
    setState(() {
      _isLoading = true; // Start loading
    });

    final accountID = await _getAccountID();
    if (accountID == null) {
      devtools.log('No accountID found');
      setState(() {
        _isLoading = false; // Stop loading if there's no account ID
      });
      return;
    }

    devtools.log('Fetching profile for accountID: $accountID');

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/api/getCVProfile?accountID=$accountID'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _nameController.text = data['name'] ?? '';
            _ageController.text = data['age']?.toString() ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _addressController.text = data['address'] ?? '';
            _descriptionController.text = data['description'] ?? '';
            PerID = data['PerID'] ?? '';
          });
          // Load profile image if available
          if (data['Photo'] != null && data['Photo'].isNotEmpty) {
            try {
              final bytes = base64Decode(data['Photo']);
              final tempFile =
                  File('${(await getTemporaryDirectory()).path}/Photo.png');
              await tempFile.writeAsBytes(bytes);
              setState(() {
                _imageFile = XFile(tempFile.path);
              });
            } catch (e) {
              devtools.log('Error decoding image: $e');
            }
          }
        } else {
          await _fetchPersonDetails(accountID);
        }
      } else {
        devtools.log('Failed to load profile data: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching profile data: $e');
    } finally {
      if (mounted) {
        // Check if the widget is still mounted
        setState(() {
          _isLoading = false; // Stop loading when data is fetched
        });
      }
    }
  }

  Future<void> _fetchPersonDetails(int accountID) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/api/getPersonDetails?accountID=$accountID'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          setState(() {
            _nameController.text = data['FullName'] ?? '';
            _emailController.text = data['Email'] ?? '';
            _phoneController.text = data['Mobile_Number'] ?? '';
            // You may want to leave age, address, and description empty or set defaults
          });
        } else {
          devtools.log('Person details not found');
        }
      } else {
        devtools.log('Failed to load person details: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching person details: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_isEditing) {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () async {
                    final picker = ImagePicker();
                    Navigator.of(context).pop();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    setState(() {
                      if (pickedFile != null) {
                        _imageFile = pickedFile;
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () async {
                    final picker = ImagePicker();
                    Navigator.of(context).pop();
                    final pickedFile = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );

                    setState(() {
                      if (pickedFile != null) {
                        _imageFile = pickedFile;
                      }
                    });
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _saveCVProfile() async {
    final accountID = await _getAccountID() ?? 0;
    bool hasError = false;
    Uint8List? imageBytes;
    if (_imageFile != null) {
      // Read the image file
      final File imageFile = File(_imageFile!.path);

      // Load the image into memory using the image package
      final img.Image? originalImage =
          img.decodeImage(imageFile.readAsBytesSync());

      if (originalImage != null) {
        // Get the size of the original image in bytes
        int originalSizeBytes = imageFile.lengthSync();

        // If the image is already under 2MB, skip compression
        if (originalSizeBytes <= 2 * 1024 * 1024) {
          devtools
              .log('Image size is already under 2MB: $originalSizeBytes bytes');
          imageBytes = await imageFile.readAsBytes(); // No need to compress
        } else {
          // Compress the image to approximately 2MB by reducing quality and dimensions
          const int targetSizeMB = 2; // Target size in MB
          const int targetSizeBytes =
              targetSizeMB * 1024 * 1024; // Convert MB to bytes

          // Estimate resize factor based on the original size
          double resizeFactor = sqrt(targetSizeBytes / originalSizeBytes);

          // Resize the image based on the estimated factor
          img.Image resizedImage = img.copyResize(
            originalImage,
            width: (originalImage.width * resizeFactor).toInt(),
          );

          // Start with a slightly reduced quality (80%)
          int quality = 80;
          List<int>? compressedImageBytes;

          // Compress the resized image
          compressedImageBytes = img.encodeJpg(resizedImage, quality: quality);
          devtools.log(
              'Initial compressed image size: ${compressedImageBytes.length} bytes');

          // If the initial compression is still larger than 2MB, reduce quality
          if (compressedImageBytes.length > targetSizeBytes) {
            // Reduce quality in larger steps initially, then smaller steps near the target size
            for (int step = 20; step >= 5; step = step ~/ 2) {
              while (compressedImageBytes != null &&
                  compressedImageBytes.length > targetSizeBytes &&
                  quality > 0) {
                quality -= step;
                compressedImageBytes =
                    img.encodeJpg(resizedImage, quality: quality);
                devtools.log(
                    'Compressed image size with quality $quality: ${compressedImageBytes.length} bytes');
              }
            }
          }
          // Convert the compressed image to Uint8List
          if (compressedImageBytes != null) {
            devtools.log(compressedImageBytes.length.toString());
            imageBytes = Uint8List.fromList(compressedImageBytes);
          }
        }
      }
    }

    final profileData = {
      'accountID': accountID,
      'Photo': imageBytes != null ? base64Encode(imageBytes) : null,
      'name': _nameController.text.trim().toUpperCase(),
      'age': _ageController.text.trim().toUpperCase(),
      'email_address': _emailController.text.trim(),
      'mobile_number': _phoneController.text.trim().toUpperCase(),
      'address': _addressController.text.trim().toUpperCase(),
      'description': _descriptionController.text.trim().toUpperCase(),
      'PerID': PerID,
    };

    devtools.log('Saving profile data for accountID: $accountID');

    setState(() {
      _isSaving = true;
    });

    try {
      // final response = await http.post(
      //   Uri.parse('http://127.0.0.1:4000/api/saveCVProfile'),
      //   headers: <String, String>{
      //     'Content-Type': 'application/json; charset=UTF-8',
      //   },
      //   body: jsonEncode(profileData),
      // );
      // final response2 = await http.post(
      //   Uri.parse('http://127.0.0.1:6011/api/saveCVProfile'),
      //   headers: <String, String>{
      //     'Content-Type': 'application/json; charset=UTF-8',
      //   },
      //   body: jsonEncode(profileData),
      // );

      // devtools.log('Response 1 status: ${response.statusCode}');
      // devtools.log('Response 1 body: ${response.body}');
      // devtools.log('Response 2 status: ${response2.statusCode}');
      // devtools.log('Response 2 body: ${response2.body}');
      // if (response.statusCode == 200 || response2.statusCode == 200) {
      //   devtools.log('Profile saved successfully');
      //   _showSuccessDialog();
      // } else {
      //   devtools.log('Failed to save profile: ${response.statusCode}');
      //   _showErrorDialog('Failed to save profile.');
      // }

      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/saveCVProfile'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(profileData),
      );

      devtools.log('Response 1 status: ${response.statusCode}');
      devtools.log('Response 1 body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        devtools.log('Profile saved successfully');
        showErrorDialog(context, 'Profile saved successfully');
      } else if (response.statusCode == 501) {
        devtools.log('Profile saved successfully');
        showErrorDialog(context, response.body);
      } else if (response.statusCode == 502) {
        devtools.log('Profile saved successfully');
        showErrorDialog(context, response.body);
      } else {
        devtools.log('Failed to save profile: ${response.statusCode}');
        showErrorDialog(context, response.body);
      }
    } catch (e) {
      if (!mounted) return;

      devtools.log('Error saving profile data: $e');
      showErrorDialog(context, 'An error occurred while saving the profile.');
      hasError = true;
    } finally {
      if (mounted && !hasError) {
        // Check if the widget is still mounted
        setState(() {
          _isSaving = false; // Stop saving when done
        });
      }
    }
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

  String? _validateAge(String age) {
    if (age.isEmpty) {
      return 'Age cannot be empty.';
    } else if (!RegExp(r'^\d+$').hasMatch(age)) {
      return 'Invalid Age';
    }
    return null;
  }

  void _validateFields() {
    setState(() {
      _errorMessages['name'] =
          _nameController.text.isEmpty ? 'Name cannot be empty.' : null;
      _errorMessages['age'] = _validateAge(_ageController.text); //this line
      _errorMessages['email'] = _validateEmail(_emailController.text);
      _errorMessages['phone'] = _validatePhoneNumber(_phoneController.text);
      _errorMessages['address'] =
          _addressController.text.isEmpty ? 'Address cannot be empty.' : null;
      _errorMessages['description'] = _descriptionController.text.isEmpty
          ? 'Description cannot be empty.'
          : null;
    });
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        _validateFields();
        if (_errorMessages.values.every((error) => error == null)) {
          _saveCVProfile(); // Save data when toggling off edit mode
        } else {
          return; // Do not toggle edit mode if there are validation errors
        }
      }
      _isEditing = !_isEditing; // Toggle editing state
    });
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
        title: Text('Profile Information',
            style: AppWidget.headlineTextFieldStyle()),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading spinner
          : Stack(
              children: [
                _buildProfileForm(), // Show the form after data is fetched
                if (_isSaving)
                  const Center(
                      child:
                          CircularProgressIndicator()), // Loading during save
              ],
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: (_isLoading || _isSaving) ? null : _toggleEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF171B63),
                padding: const EdgeInsets.symmetric(
                    horizontal: 60.0, vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                _isEditing ? 'Save' : 'Edit',
                style: const TextStyle(color: Colors.white, fontSize: 15.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20.0),
          InkWell(
            onTap: _isEditing ? _pickImage : null,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt_outlined, color: Colors.black)
                    : CircleAvatar(
                        radius: 80.0,
                        backgroundImage: FileImage(File(_imageFile!.path)),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 15.0),
          _buildInputField("Name", _nameController, _errorMessages['name']),
          const SizedBox(height: 15.0),
          _buildInputField("Age", _ageController, _errorMessages['age']),
          const SizedBox(height: 15.0),
          _buildInputField("Email", _emailController, _errorMessages['email']),
          const SizedBox(height: 15.0),
          _buildInputField("Phone", _phoneController, _errorMessages['phone']),
          const SizedBox(height: 15.0),
          _buildInputField(
              "Address", _addressController, _errorMessages['address']),
          const SizedBox(height: 15.0),
          _buildInputField("Description", _descriptionController,
              _errorMessages['description']),
          const SizedBox(height: 15.0),
        ],
      ),
    );
  }

  Widget _buildInputField(
      String label, TextEditingController controller, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        TextField(
          controller: controller,
          enabled: _isEditing,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          decoration: InputDecoration(
            hintText: label == "Phone"
                ? 'Mobile Phone (Eg: 01xxxxxxxx)'
                : null, // Hint text for phone
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12.0)),
          ),
      ],
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
