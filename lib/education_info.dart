/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:firstly/show_error_dialog.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
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
}

class EducationInfoPage extends StatefulWidget {
  const EducationInfoPage({super.key});

  @override
  _EducationInfoPageState createState() => _EducationInfoPageState();
}

class _EducationInfoPageState extends State<EducationInfoPage> {
  final List<String> _educationLevels = [
    'HIGH SCHOOL',
    'FOUNDATION',
    'COLLEGE',
    'DIPLOMA',
    'BACHELOR’S DEGREE',
    'MASTER’S DEGREE',
    'PH.D.',
    'OTHER',
  ];

  final List<Map<String, dynamic>> _educationEntries = [];
  final List<String?> _selectedLevels = [];
  final List<TextEditingController> _fieldOfStudyControllers = [];
  final List<TextEditingController> _instituteNameControllers = [];
  final List<TextEditingController> _instituteCountryControllers = [];
  final List<TextEditingController> _instituteStateControllers = [];
  final List<TextEditingController> _instituteCityControllers = [];
  final List<String> _startDateList = [];
  final List<String> _endDateList = [];
  final List<bool> _isPublicList = [];
  bool _isEditing = false;
  bool _isLoading = false;
  bool hasError = false;

  final List<String?> _levelOfEducationErrors = [];
  final List<String?> _fieldOfStudyErrors = [];
  final List<String?> _instituteNameErrors = [];
  final List<String?> _instituteCountryErrors = [];
  final List<String?> _instituteStateErrors = [];
  final List<String?> _instituteCityErrors = [];
  final List<String?> _startDateErrors = [];
  final List<String?> _endDateErrors = [];
  final List<String?> _dateValidationErrors = [];

  @override
  void initState() {
    super.initState();
    if (!mounted) return;
    _initializeEducationEntries();
    if (!mounted) return;
    _fetchEducationData();
    if (!mounted) return;
  }

  void _initializeEducationEntries() {
    setState(() {
      _educationEntries.clear();
      _selectedLevels.clear();
      _fieldOfStudyControllers.clear();
      _instituteNameControllers.clear();
      _instituteCountryControllers.clear();
      _instituteStateControllers.clear();
      _instituteCityControllers.clear();
      _startDateList.clear();
      _endDateList.clear();
      _isPublicList.clear();

      _levelOfEducationErrors.clear();
      _fieldOfStudyErrors.clear();
      _instituteNameErrors.clear();
      _instituteCountryErrors.clear();
      _instituteStateErrors.clear();
      _instituteCityErrors.clear();
      _startDateErrors.clear();
      _endDateErrors.clear();
      _dateValidationErrors.clear();

      _addEducationEntry(); // Initialize with one education entry
    });
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

  Future<void> _fetchEducationData() async {
    setState(() {
      _isLoading = true;
    });

    final accountID = await _getAccountID();
    if (accountID == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:4000/api/getCVEducation?accountID=$accountID'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            // Clear all lists before populating them with new data
            _educationEntries.clear();
            _selectedLevels.clear();
            _fieldOfStudyControllers.clear();
            _instituteNameControllers.clear();
            _instituteCountryControllers.clear();
            _instituteStateControllers.clear();
            _instituteCityControllers.clear();
            _startDateList.clear();
            _endDateList.clear();
            _isPublicList.clear();

            // Clear error lists
            _levelOfEducationErrors.clear();
            _fieldOfStudyErrors.clear();
            _instituteNameErrors.clear();
            _instituteCountryErrors.clear();
            _instituteStateErrors.clear();
            _instituteCityErrors.clear();
            _startDateErrors.clear();
            _endDateErrors.clear();
            _dateValidationErrors.clear();

            // Populate lists for each entry in the response data
            for (var entry in data) {
              _educationEntries.add(entry);
              _selectedLevels.add(entry['level']);
              _fieldOfStudyControllers
                  .add(TextEditingController(text: entry['field_of_study']));
              _instituteNameControllers
                  .add(TextEditingController(text: entry['institute_name']));
              _instituteCountryControllers
                  .add(TextEditingController(text: entry['institute_country']));
              _instituteStateControllers
                  .add(TextEditingController(text: entry['institute_state']));
              _instituteCityControllers
                  .add(TextEditingController(text: entry['institute_city']));
              _startDateList.add(entry['start_date'] ?? '');
              _endDateList.add(entry['end_date'] ?? '');
              _isPublicList.add(entry['isPublic'] ?? true);

              // Initialize the error lists for each entry
              _levelOfEducationErrors.add(null);
              _fieldOfStudyErrors.add(null);
              _instituteNameErrors.add(null);
              _instituteCountryErrors.add(null);
              _instituteStateErrors.add(null);
              _instituteCityErrors.add(null);
              _startDateErrors.add(null);
              _endDateErrors.add(null);
              _dateValidationErrors.add(null);
            }
          });
        }
      } else {
        devtools.log(
            'Failed to fetch education data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching education data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addEducationEntry() {
    setState(() {
      _educationEntries.add({
        'eduBacID': null,
        'level': null,
        'field_of_study': '',
        'institute_name': '',
        'institute_country': '',
        'institute_state': '',
        'institute_city': '',
        'start_date': '',
        'end_date': '',
        'isPublic': true,
      });
      _selectedLevels.add(null);
      _fieldOfStudyControllers.add(TextEditingController());
      _instituteNameControllers.add(TextEditingController());
      _instituteCountryControllers.add(TextEditingController());
      _instituteStateControllers.add(TextEditingController());
      _instituteCityControllers.add(TextEditingController());
      _startDateList.add('');
      _endDateList.add('');
      _isPublicList.add(true);

      _levelOfEducationErrors.add(null);
      _fieldOfStudyErrors.add(null);
      _instituteNameErrors.add(null);
      _instituteCountryErrors.add(null);
      _instituteStateErrors.add(null);
      _instituteCityErrors.add(null);
      _startDateErrors.add(null);
      _endDateErrors.add(null);
      _dateValidationErrors.add(null); // Add this line
    });
  }

  Future<void> _saveEducationEntries() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;
    if (!mounted) return;

    hasError = false;

    // Validate input fields for each education entry
    for (int i = 0; i < _educationEntries.length; i++) {
      _levelOfEducationErrors[i] = _selectedLevels[i] == null
          ? 'Level of Education cannot be empty'
          : null;
      _fieldOfStudyErrors[i] = _fieldOfStudyControllers[i].text.isEmpty
          ? 'Field of Study cannot be empty'
          : null;
      _instituteNameErrors[i] = _instituteNameControllers[i].text.isEmpty
          ? 'Institute Name cannot be empty'
          : null;
      _instituteCountryErrors[i] = _instituteCountryControllers[i].text.isEmpty
          ? 'Country cannot be empty'
          : null;
      _instituteStateErrors[i] = _instituteStateControllers[i].text.isEmpty
          ? 'State cannot be empty'
          : null;
      _instituteCityErrors[i] = _instituteCityControllers[i].text.isEmpty
          ? 'City cannot be empty'
          : null;
      _startDateErrors[i] =
          _startDateList[i].isEmpty ? 'Start Date cannot be empty' : null;
      _endDateErrors[i] =
          _endDateList[i].isEmpty ? 'End Date cannot be empty' : null;

      // Validate date format
      if (_startDateList[i].isNotEmpty && _endDateList[i].isNotEmpty) {
        if (_startDateList[i].compareTo(_endDateList[i]) > 0) {
          _dateValidationErrors[i] = 'Invalid Date';
          hasError = true;
        } else {
          _dateValidationErrors[i] = null; // Clear previous error if valid
        }
      }

      // Check if there are any errors
      if (_levelOfEducationErrors[i] != null ||
          _fieldOfStudyErrors[i] != null ||
          _instituteNameErrors[i] != null ||
          _instituteCountryErrors[i] != null ||
          _instituteStateErrors[i] != null ||
          _instituteCityErrors[i] != null ||
          _startDateErrors[i] != null ||
          _endDateErrors[i] != null ||
          _dateValidationErrors[i] != null) {
        hasError = true;
      }
    }

    // Stop the save process if there are validation errors
    if (hasError) {
      _isEditing = true; // End edit mode after saving if no errors

      return;
    }

    // Proceed with saving the entries if no errors
    List<Map<String, dynamic>> newEducationEntries = [];
    List<Map<String, dynamic>> existingEducationEntries = [];
    List<int> newEntryIndexes = [];
    Set<String> entrySet = {};

    for (int i = 0; i < _educationEntries.length; i++) {
      String level = _selectedLevels[i]?.toUpperCase() ?? '';
      String fieldOfStudy = _fieldOfStudyControllers[i].text.toUpperCase();
      String instituteName = _instituteNameControllers[i].text.toUpperCase();

      String uniqueKey = '$level-$fieldOfStudy-$instituteName';

      final entry = {
        'EduBacID': _educationEntries[i]['eduBacID'],
        'level': level,
        'field_of_study': fieldOfStudy,
        'institute_name': instituteName,
        'institute_country': _instituteCountryControllers[i].text.toUpperCase(),
        'institute_state': _instituteStateControllers[i].text.toUpperCase(),
        'institute_city': _instituteCityControllers[i].text.toUpperCase(),
        'start_date': _startDateList[i],
        'end_date': _endDateList[i],
        'isPublic': _isPublicList[i],
      };

      // Ensure there are no duplicate entries
      if (entrySet.contains(uniqueKey)) {
        showErrorDialog(
          context,
          'Duplicate entry for education entry ${i + 1}.',
        );
        hasError = true;
        _isEditing = true; // End edit mode after saving if no errors

        return;
      }

      entrySet.add(uniqueKey);

      // Separate new entries from existing ones for processing
      if (_educationEntries[i]['eduBacID'] == null) {
        newEducationEntries.add(entry);
        newEntryIndexes.add(i);
      } else {
        existingEducationEntries.add(entry);
      }
    }

    if (hasError) return;

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Prepare request body
    final body = jsonEncode({
      'accountID': accountID,
      'newEducationEntries': newEducationEntries,
      'existingEducationEntries': existingEducationEntries,
    });

    try {
      // Make the request to save education entries
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/saveCVEducation'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      devtools.log(response.statusCode.toString());

      // Handle success response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List updatedEducations = responseData['newEducationsWithID'];

        // Update EduBacID for new entries
        for (int i = 0; i < newEntryIndexes.length; i++) {
          int index = newEntryIndexes[i];
          _educationEntries[index]['eduBacID'] =
              updatedEducations[i]['EduBacID'];
          devtools.log("Added EduBacID to new entry at index: $index");
        }

        devtools.log('Education entries saved successfully.');
        setState(() {
          _isEditing = false; // Exit edit mode after saving
        });
      } else {
        // Handle failure response
        devtools.log(
            'Failed to save education entries. Status code: ${response.statusCode}');
        showErrorDialog(context, 'Failed to save education entries');
      }
    } catch (error) {
      // Handle any errors that occurred during the save process
      devtools.log('Error saving education entries: $error');
      showErrorDialog(context, 'Error saving education entries');
    } finally {
      // Stop the loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteEducationEntry(int index) async {
    final eduBacID = _educationEntries[index]['eduBacID'];

    if (eduBacID != null) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/deleteCVEducation'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'EduBacID': eduBacID}),
        );
        final response2 = await http.post(
          Uri.parse('http://127.0.0.1:6011/api/deleteCVEducation'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'EduBacID': eduBacID}),
        );

        if (response.statusCode == 200 && response2.statusCode == 200 ||
            response2.statusCode == 201) {
          setState(() {
            _educationEntries.removeAt(index);
            _selectedLevels.removeAt(index);
            _fieldOfStudyControllers.removeAt(index);
            _instituteNameControllers.removeAt(index);
            _instituteCountryControllers.removeAt(index);
            _instituteStateControllers.removeAt(index);
            _instituteCityControllers.removeAt(index);
            _startDateList.removeAt(index);
            _endDateList.removeAt(index);
            _isPublicList.removeAt(index);

            if (_educationEntries.isEmpty) {
              _addEducationEntry();
            }
          });
          devtools.log("Education entry deleted successfully");
        } else {
          showErrorDialog(context, 'Failed to delete education entry');
        }
      } catch (e) {
        devtools.log("Error deleting education entry: $e");
        showErrorDialog(context, 'Error deleting education entry');
      }
    } else {
      setState(() {
        _educationEntries.removeAt(index);
        _selectedLevels.removeAt(index);
        _fieldOfStudyControllers.removeAt(index);
        _instituteNameControllers.removeAt(index);
        _instituteCountryControllers.removeAt(index);
        _instituteStateControllers.removeAt(index);
        _instituteCityControllers.removeAt(index);
        _startDateList.removeAt(index);
        _endDateList.removeAt(index);
        _isPublicList.removeAt(index);

        if (_educationEntries.isEmpty) {
          _addEducationEntry();
        }
      });
    }
  }

  void _toggleEditMode() async {
    if (_isEditing && mounted) {
      setState(() {
        _isLoading = true; // Start loading indicator when saving
      });

      try {
        // Perform save operation here
        await _saveEducationEntries();
        if (!mounted) return;
      } catch (error) {
        // Handle any errors during save
        devtools.log('Error saving data: $error');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Stop loading indicator after save completes
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isEditing = true; // Start edit mode
        });
      }
    }
  }

  Future<void> _selectMonthYear(
      BuildContext context, int index, bool isStart) async {
    DateTime? selectedDate = DateTime.now();
    if (isStart) {
      selectedDate = DateTime.tryParse(_startDateList[index]) ?? DateTime.now();
    } else {
      selectedDate = DateTime.tryParse(_endDateList[index]) ?? DateTime.now();
    }

    final DateTime? picked = await showMonthYearPicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && mounted) {
      setState(() {
        String formattedDate =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
        if (isStart) {
          _startDateList[index] = formattedDate;
        } else {
          _endDateList[index] = formattedDate;
        }
      });
    }
  }

  Widget _buildInputSection(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Education Information ${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF171B63),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEducationEntry(index),
                  ),
              ],
            ),
          ),
          _buildDropdownField(
            context,
            'Level of Education',
            _educationLevels,
            index,
            _isEditing,
            _levelOfEducationErrors[index], // Pass error for level of education
          ),
          const SizedBox(height: 15.0),
          _buildInputField(
            context,
            'Field of Study',
            _fieldOfStudyControllers[index],
            _isEditing,
            _fieldOfStudyErrors[index],
          ),
          const SizedBox(height: 15.0),
          _buildInputField(
            context,
            'Institute Name',
            _instituteNameControllers[index],
            _isEditing,
            _instituteNameErrors[index],
          ),
          const SizedBox(height: 15.0),
          _buildInputField(
            context,
            'Institute Country',
            _instituteCountryControllers[index],
            _isEditing,
            _instituteCountryErrors[index],
          ),
          const SizedBox(height: 15.0),
          _buildInputField(
            context,
            'Institute State',
            _instituteStateControllers[index],
            _isEditing,
            _instituteStateErrors[index],
          ),
          const SizedBox(height: 15.0),
          _buildInputField(
            context,
            'Institute City',
            _instituteCityControllers[index],
            _isEditing,
            _instituteCityErrors[index],
          ),
          const SizedBox(height: 15.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Date Section
              const Text(
                'Start Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Color(0xFF171B63),
                ),
              ),
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: () =>
                    _isEditing ? _selectMonthYear(context, index, true) : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 15.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    _startDateList[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF171B63),
                    ),
                  ),
                ),
              ),
              if (_startDateErrors[index] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    _startDateErrors[index]!,
                    style: const TextStyle(color: Colors.red, fontSize: 12.0),
                  ),
                ),
              if (_dateValidationErrors[index] !=
                  null) // Display date validation error
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    _dateValidationErrors[index]!,
                    style: const TextStyle(color: Colors.red, fontSize: 12.0),
                  ),
                ),
              const SizedBox(height: 15.0), // Space below start date

              // End Date Section
              const Text(
                'End Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Color(0xFF171B63),
                ),
              ),
              const SizedBox(height: 8.0),
              GestureDetector(
                onTap: () =>
                    _isEditing ? _selectMonthYear(context, index, false) : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 15.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    _endDateList[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF171B63),
                    ),
                  ),
                ),
              ),
              if (_endDateErrors[index] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    _endDateErrors[index]!,
                    style: const TextStyle(color: Colors.red, fontSize: 12.0),
                  ),
                ),

              if (_dateValidationErrors[index] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    _dateValidationErrors[index]!,
                    style: const TextStyle(color: Colors.red, fontSize: 12.0),
                  ),
                ),
              const SizedBox(height: 15.0), // Space below end date
            ],
          ),
          if (_isEditing)
            Row(
              children: [
                Checkbox(
                  value: _isPublicList[index],
                  onChanged: (bool? value) {
                    if (mounted) {
                      setState(() {
                        _isPublicList[index] = value ?? true;
                      });
                    }
                  },
                ),
                const Text('Public'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, String labelText,
      List<String> items, int index, bool isEditable, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          value: _selectedLevels[index],
          onChanged: isEditable
              ? (String? newValue) {
                  setState(() {
                    _selectedLevels[index] = newValue;
                  });
                }
              : null, // Disable if not editable
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
            enabledBorder: OutlineInputBorder(
              borderSide:
                  BorderSide(color: isEditable ? Colors.grey : Colors.black12),
              borderRadius: BorderRadius.circular(10.0),
            ),
            errorText: errorMessage, // Display the error message if any
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context, String labelText,
      TextEditingController controller, bool isEditing, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        TextField(
          controller: controller,
          enabled: isEditing,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF171B63),
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: errorMessage != null ? Colors.red : Colors.grey,
                width: 2.0,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12.0),
            ),
          ),
      ],
    );
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
        title: Text(
          'Education Information',
          style: AppWidget.headlineTextFieldStyle(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _educationEntries.length,
                    itemBuilder: (context, index) {
                      return _buildInputSection(context, index);
                    },
                  ),
                  const SizedBox(height: 10.0),
                  if (_isEditing)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null // Disable button when loading
                            : () {
                                setState(() {
                                  _addEducationEntry();
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF171B63),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        child: const Text(
                          'Add More Education',
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: _isLoading
                  ? null // Disable button when loading
                  : _toggleEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading
                    ? Colors.grey
                    : const Color(0xFF171B63), // Change button color if loading
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
}

// Month-Year Picker Function
Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      DateTime selectedDate = initialDate;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Month and Year'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Month'),
                  trailing: DropdownButton<int>(
                    value: selectedDate.month,
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedDate = DateTime(selectedDate.year, value);
                        });
                      }
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Year'),
                  trailing: DropdownButton<int>(
                    value: selectedDate.year,
                    items: List.generate(lastDate.year - firstDate.year + 1,
                        (index) {
                      return DropdownMenuItem(
                        value: firstDate.year + index,
                        child: Text(
                          "${firstDate.year + index}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedDate = DateTime(value, selectedDate.month);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(selectedDate);
                },
              ),
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}
