/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as devtools show log;

import 'package:firstly/show_error_dialog.dart';

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

class WorkInfoPage extends StatefulWidget {
  const WorkInfoPage({super.key});

  @override
  _WorkInfoPageState createState() => _WorkInfoPageState();
}

class _WorkInfoPageState extends State<WorkInfoPage> {
  bool _isEditing = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _workExperienceEntries = [];
  List<String?> _selectedIndustries = [];
  List<TextEditingController> _jobTitleControllers = [];
  List<TextEditingController> _companyNameControllers = [];
  List<TextEditingController> _countryControllers = [];
  List<TextEditingController> _stateControllers = [];
  List<TextEditingController> _cityControllers = [];
  List<TextEditingController> _descriptionControllers = [];
  List<TextEditingController> _startDateControllers = [];
  List<TextEditingController> _endDateControllers = [];
  List<TextEditingController> _otherIndustryControllers = [];
  List<bool> _isPublicControllers = [];

  final List<String?> _jobTitleErrors = [];
  final List<String?> _companyNameErrors = [];
  final List<String?> _countryErrors = [];
  final List<String?> _stateErrors = [];
  final List<String?> _cityErrors = [];
  final List<String?> _descriptionErrors = [];
  final List<String?> _startDateErrors = [];
  final List<String?> _endDateErrors = [];
  final List<String?> _industryErrors = [];
  final List<String?> _dateValidationErrors = [];

  final List<String> _industries = [
    'Accounting',
    'Finance',
    'Business',
    'Information Technology',
    'Data Science',
    'Marketing',
    'Others',
  ];

  @override
  void initState() {
    if (!mounted) return;
    super.initState();
    if (!mounted) return;
    _initializeWorkEntries();
    if (!mounted) return;
    _fetchWorkEntries();
  }

  void _initializeWorkEntries() {
    setState(() {
      _workExperienceEntries.clear();
      _selectedIndustries.clear();
      _jobTitleControllers.clear();
      _companyNameControllers.clear();
      _countryControllers.clear();
      _stateControllers.clear();
      _cityControllers.clear();
      _descriptionControllers.clear();
      _startDateControllers.clear();
      _endDateControllers.clear();
      _otherIndustryControllers.clear();
      _isPublicControllers.clear();

      // Initialize error lists
      _jobTitleErrors.clear();
      _companyNameErrors.clear();
      _countryErrors.clear();
      _stateErrors.clear();
      _cityErrors.clear();
      _descriptionErrors.clear();
      _startDateErrors.clear();
      _endDateErrors.clear();
      _industryErrors.clear();
      _dateValidationErrors.clear();
      _jobTitleErrors.add(null);
      _companyNameErrors.add(null);
      _countryErrors.add(null);
      _stateErrors.add(null);
      _cityErrors.add(null);
      _descriptionErrors.add(null);
      _startDateErrors.add(null);
      _endDateErrors.add(null);
      _industryErrors.add(null);
      _dateValidationErrors.add(null);
      _addWorkExperienceEntry();
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

  Future<void> _fetchWorkEntries() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });
    if (!mounted) return;

    final accountID = await _getAccountID();
    if (accountID == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/api/getCVWork?accountID=$accountID'),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _workExperienceEntries =
                List<Map<String, dynamic>>.from(data.map((entry) {
              return {
                'WorkExpID': entry['WorkExpID'],
                'job_title': entry['job_title'],
                'company_name': entry['company_name'],
                'industry': entry['industry'],
                'country': entry['country'],
                'state': entry['state'],
                'city': entry['city'],
                'description': entry['description'],
                'start_date': entry['start_date'],
                'end_date': entry['end_date'],
                'isPublic': entry['isPublic'],
              };
            }));
            _initializeControllers();
          });
        }
      } else {
        if (!mounted) return;
        showErrorDialog(context, 'Failed to load work entries');
      }
    } catch (error) {
      if (!mounted) return;

      devtools.log('No work entries: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeControllers() {
    _jobTitleControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['job_title']),
    );
    _companyNameControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['company_name']),
    );

    // Initialize the selected industries and other industry controllers
    devtools.log('Initializing controllers...');
    devtools.log('Work Experience Entries: $_workExperienceEntries');

    _selectedIndustries = [];
    _otherIndustryControllers = [];

    for (int index = 0; index < _workExperienceEntries.length; index++) {
      String industry =
          _workExperienceEntries[index]['industry']?.toUpperCase() ?? 'OTHERS';

      devtools.log('Processing industry for entry $index: $industry');

      if (_industries.map((i) => i.toUpperCase()).contains(industry)) {
        devtools.log(
            'Industry "$industry" found in the list, setting dropdown to it.');
        _selectedIndustries
            .add(industry); // Set the dropdown to the found industry
        _otherIndustryControllers
            .add(TextEditingController()); // No need for custom industry input
      } else {
        devtools.log(
            'Industry "$industry" not found, setting dropdown to "Others" and custom industry value.');
        _selectedIndustries.add('OTHERS'); // Set dropdown to 'Others'
        _otherIndustryControllers.add(TextEditingController(
            text: _workExperienceEntries[index]
                ['industry'])); // Set the custom industry value
      }
    }

    devtools.log('Selected Industries: $_selectedIndustries');
    devtools.log(
        'Custom Industry Controllers: ${_otherIndustryControllers.map((c) => c.text).toList()}');

    _countryControllers = List.generate(
      _workExperienceEntries.length,
      (index) =>
          TextEditingController(text: _workExperienceEntries[index]['country']),
    );
    _stateControllers = List.generate(
      _workExperienceEntries.length,
      (index) =>
          TextEditingController(text: _workExperienceEntries[index]['state']),
    );
    _cityControllers = List.generate(
      _workExperienceEntries.length,
      (index) =>
          TextEditingController(text: _workExperienceEntries[index]['city']),
    );
    _descriptionControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['description']),
    );
    _startDateControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['start_date']),
    );
    _endDateControllers = List.generate(
      _workExperienceEntries.length,
      (index) => TextEditingController(
          text: _workExperienceEntries[index]['end_date']),
    );
    _isPublicControllers = List.generate(
      _workExperienceEntries.length,
      (index) => _workExperienceEntries[index]['isPublic'] ?? true,
    );
  }

  // Function to validate date format
  bool _isDateFormatValid(String date) {
    final RegExp regex = RegExp(r'^\d{4}-\d{2}$'); // Format: YYYY-MM
    return regex.hasMatch(date);
  }

  Future<void> _saveWorkEntries() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;
    if (!mounted) return;

    bool hasError = false;

    setState(() {
      for (int i = 0; i < _workExperienceEntries.length; i++) {
        // Validate empty fields
        _jobTitleErrors[i] = _jobTitleControllers[i].text.isEmpty
            ? 'Job title cannot be empty'
            : null;
        _companyNameErrors[i] = _companyNameControllers[i].text.isEmpty
            ? 'Company name cannot be empty'
            : null;
        _countryErrors[i] = _countryControllers[i].text.isEmpty
            ? 'Country cannot be empty'
            : null;
        _stateErrors[i] =
            _stateControllers[i].text.isEmpty ? 'State cannot be empty' : null;
        _cityErrors[i] =
            _cityControllers[i].text.isEmpty ? 'City cannot be empty' : null;
        _descriptionErrors[i] = _descriptionControllers[i].text.isEmpty
            ? 'Description cannot be empty'
            : null;

        // Validate start and end date fields
        _startDateErrors[i] = _startDateControllers[i].text.isEmpty
            ? 'Start date cannot be empty'
            : null;
        _endDateErrors[i] = _endDateControllers[i].text.isEmpty
            ? 'End date cannot be empty'
            : null;

        // Validate date format
        String startDateText = _startDateControllers[i].text.trim();
        String endDateText = _endDateControllers[i].text.trim();

        if (!_isDateFormatValid(startDateText)) {
          _startDateErrors[i];
          hasError = true;
        } else {
          _startDateErrors[i] = null; // Clear previous error if valid
        }

        if (!_isDateFormatValid(endDateText)) {
          _endDateErrors[i];
          hasError = true;
        } else {
          _endDateErrors[i] = null; // Clear previous error if valid
        }

        // Check if both start and end dates are not empty before validating
        if (startDateText.isNotEmpty && endDateText.isNotEmpty) {
          // Validate that the start date is not later than the end date
          if (startDateText.compareTo(endDateText) > 0) {
            _dateValidationErrors[i] = 'Invalid Date';
            hasError = true;
          } else {
            _dateValidationErrors[i] = null; // Clear previous error if valid
          }
        }

        // Validate industry
        _industryErrors[i] = (_selectedIndustries[i] == 'OTHERS' &&
                _otherIndustryControllers[i].text.isEmpty)
            ? 'Industry cannot be empty'
            : null;

        // If any error exists, mark hasError as true
        if (_jobTitleErrors[i] != null ||
            _companyNameErrors[i] != null ||
            _countryErrors[i] != null ||
            _stateErrors[i] != null ||
            _cityErrors[i] != null ||
            _descriptionErrors[i] != null ||
            _startDateErrors[i] != null ||
            _endDateErrors[i] != null ||
            _industryErrors[i] != null ||
            _dateValidationErrors[i] != null) {
          hasError = true;
        }
      }

      // If there are any errors, return and stop the save process
      if (hasError) {
        _isEditing = true;
        return;
      }
    });

    // If no errors, proceed with saving the work entries
    List<Map<String, dynamic>> newWorkEntries = [];
    List<Map<String, dynamic>> existingWorkEntries = [];
    List<int> newEntryIndexes = [];
    Set<String> entrySet = {};

    for (int i = 0; i < _workExperienceEntries.length; i++) {
      String jobTitle = _jobTitleControllers[i].text.trim().toUpperCase();
      String companyName = _companyNameControllers[i].text.trim().toUpperCase();

      if (jobTitle.isEmpty || companyName.isEmpty) continue;

      String industry = _selectedIndustries[i] == 'OTHERS'
          ? _otherIndustryControllers[i].text.trim().toUpperCase()
          : _selectedIndustries[i]?.toUpperCase() ?? '';

      // Create a unique key for duplicate checking based on job title and company name
      String uniqueKey = '$jobTitle-$companyName';

      // Prepare the work entry for saving
      final entry = {
        'WorkExpID': _workExperienceEntries[i]['WorkExpID'],
        'job_title': jobTitle,
        'company_name': companyName,
        'industry': industry,
        'country': _countryControllers[i].text.trim().toUpperCase(),
        'state': _stateControllers[i].text.trim().toUpperCase(),
        'city': _cityControllers[i].text.trim().toUpperCase(),
        'description': _descriptionControllers[i].text.trim().toUpperCase(),
        'start_date': _startDateControllers[i].text.trim().toUpperCase(),
        'end_date': _endDateControllers[i].text.trim().toUpperCase(),
        'isPublic': _isPublicControllers[i],
      };

      // Check for duplicate job title and company name
      if (entrySet.contains(uniqueKey)) {
        hasError = true;
        showErrorDialog(context, 'Duplicate entry for work entry ${i + 1}.');
        _isEditing = true;
        return;
      }

      entrySet.add(uniqueKey);

      if (_workExperienceEntries[i]['WorkExpID'] == null) {
        newWorkEntries.add(entry);
        newEntryIndexes.add(i); // Track the index of the new entry
      } else {
        existingWorkEntries.add(entry);
      }
    }

    if (hasError) {
      _isEditing = true;
      return;
    }
    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Prepare request body
    final body = jsonEncode({
      'accountID': accountID,
      'newWorkEntries': newWorkEntries,
      'existingWorkEntries': existingWorkEntries,
    });

    try {
      // Make the request to save work entries
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/saveCVWork'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List updatedWorkEntries = responseData['newWorkWithID'];

        // Correctly update new entries with their generated WorkExpID
        for (int i = 0; i < newEntryIndexes.length; i++) {
          int index = newEntryIndexes[i];
          _workExperienceEntries[index]['WorkExpID'] =
              updatedWorkEntries[i]['WorkExpID'];
        }

        devtools.log('Work entries saved successfully.');
        setState(() {
          _isEditing = false; // Only turn off editing mode if successful
        });
      } else {
        devtools.log(
            'Failed to save work entries. Status code: ${response.statusCode}');
        showErrorDialog(context, 'Failed to save work entries');
      }
    } catch (error) {
      devtools.log('Error saving work entries: $error');
      showErrorDialog(context, 'Error saving work entries');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      setState(() {
        _isLoading = true; // Start loading indicator when saving
      });

      try {
        // Perform save operation here
        await _saveWorkEntries();
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
      setState(() {
        _isEditing = true; // Start edit mode
      });
    }
  }

  void _addWorkExperienceEntry() {
    setState(() {
      _workExperienceEntries.add({
        'WorkExpID': null,
        'job_title': '',
        'company_name': '',
        'industry': 'ACCOUNTING', // Set to default industry
        'country': '',
        'state': '',
        'city': '',
        'description': '',
        'start_date': '',
        'end_date': '',
        'isPublic': true,
      });
      _jobTitleControllers.add(TextEditingController());
      _companyNameControllers.add(TextEditingController());
      _selectedIndustries.add('ACCOUNTING'); // Set default industry
      _countryControllers.add(TextEditingController());
      _stateControllers.add(TextEditingController());
      _cityControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _startDateControllers.add(TextEditingController());
      _endDateControllers.add(TextEditingController());
      _otherIndustryControllers.add(TextEditingController());
      _isPublicControllers.add(true);

      // Add null entries to the error lists to maintain synchronization
      _jobTitleErrors.add(null);
      _companyNameErrors.add(null);
      _countryErrors.add(null);
      _stateErrors.add(null);
      _cityErrors.add(null);
      _descriptionErrors.add(null);
      _startDateErrors.add(null);
      _endDateErrors.add(null);
      _industryErrors.add(null);
      _dateValidationErrors.add(null);
    });
  }

  Future<void> _deleteWorkExperienceEntry(int index) async {
    final WorkExpID = _workExperienceEntries[index]['WorkExpID'];

    if (WorkExpID != null) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/deleteCVWork'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'WorkExpID': WorkExpID}),
        );

        final response2 = await http.post(
          Uri.parse('http://127.0.0.1:6011/api/deleteCVWork'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'WorkExpID': WorkExpID}),
        );
        if (!mounted) return;

        if (response.statusCode == 200 &&
            (response2.statusCode == 200 || response2.statusCode == 201)) {
          setState(() {
            _workExperienceEntries.removeAt(index);
            _jobTitleControllers.removeAt(index);
            _companyNameControllers.removeAt(index);
            _selectedIndustries.removeAt(index);
            _countryControllers.removeAt(index);
            _stateControllers.removeAt(index);
            _cityControllers.removeAt(index);
            _descriptionControllers.removeAt(index);
            _startDateControllers.removeAt(index);
            _endDateControllers.removeAt(index);
            _isPublicControllers.removeAt(index);

            if (_workExperienceEntries.isEmpty) {
              _addWorkExperienceEntry();
            }
          });
        } else {
          showErrorDialog(context, 'Failed to delete work entry');
        }
      } catch (e) {
        showErrorDialog(context, 'Error deleting work entry: $e');
      }
    } else {
      setState(() {
        _workExperienceEntries.removeAt(index);
        _jobTitleControllers.removeAt(index);
        _companyNameControllers.removeAt(index);
        _selectedIndustries.removeAt(index);
        _countryControllers.removeAt(index);
        _stateControllers.removeAt(index);
        _cityControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
        _startDateControllers.removeAt(index);
        _endDateControllers.removeAt(index);
        _isPublicControllers.removeAt(index);

        if (_workExperienceEntries.isEmpty) {
          _addWorkExperienceEntry();
        }
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
        title:
            Text('Work Experience', style: AppWidget.headlineTextFieldStyle()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _workExperienceEntries.length,
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
                            ? null
                            : () {
                                setState(() {
                                  _addWorkExperienceEntry();
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
                          'Add More Work Experience',
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
              onPressed: _isLoading ? null : _toggleEditMode,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isLoading ? Colors.grey : const Color(0xFF171B63),
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

  Widget _buildInputSection(BuildContext context, int index) {
    bool isExistingEntry = _workExperienceEntries[index]['WorkExpID'] != null;

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
                  "Work Experience ${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF171B63),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteWorkExperienceEntry(index),
                  ),
              ],
            ),
          ),
          _buildInputField(context, 'Job Title', _jobTitleControllers[index],
              _isEditing, _jobTitleErrors[index]),
          const SizedBox(height: 15.0),
          _buildInputField(
              context,
              'Company Name',
              _companyNameControllers[index],
              _isEditing,
              _companyNameErrors[index]),
          const SizedBox(height: 15.0),
          _buildDropdownField(context, 'Industry', _industries, index,
              editable: _isEditing),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'Country', _countryControllers[index],
              _isEditing, _countryErrors[index]),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'State', _stateControllers[index],
              _isEditing, _stateErrors[index]),
          const SizedBox(height: 15.0),
          _buildInputField(context, 'City', _cityControllers[index], _isEditing,
              _cityErrors[index]),
          const SizedBox(height: 15.0),
          _buildInputField(
              context,
              'Description',
              _descriptionControllers[index],
              _isEditing,
              _descriptionErrors[index]),
          const SizedBox(height: 15.0),
          // Start Date and End Date pickers
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Date
              GestureDetector(
                onTap: () =>
                    _isEditing ? _selectMonthYear(context, index, true) : null,
                child: AbsorbPointer(
                  absorbing: !_isEditing,
                  child: _buildInputField(
                    context,
                    'Start Date',
                    _startDateControllers[index],
                    false,
                    _startDateErrors[index],
                  ),
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
              const SizedBox(height: 15.0),
              // End Date
              GestureDetector(
                onTap: () =>
                    _isEditing ? _selectMonthYear(context, index, false) : null,
                child: AbsorbPointer(
                  absorbing: !_isEditing,
                  child: _buildInputField(
                    context,
                    'End Date',
                    _endDateControllers[index],
                    false,
                    _endDateErrors[index],
                  ),
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
              const SizedBox(height: 15.0),

              if (_isEditing)
                Row(
                  children: [
                    Checkbox(
                      value: _isPublicControllers[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _isPublicControllers[index] = value ?? true;
                        });
                      },
                    ),
                    const Text('Public'),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonthYear(
      BuildContext context, int index, bool isStart) async {
    DateTime selectedDate = DateTime.now();
    if (isStart) {
      selectedDate = DateTime.tryParse(_startDateControllers[index].text) ??
          DateTime.now();
    } else {
      selectedDate =
          DateTime.tryParse(_endDateControllers[index].text) ?? DateTime.now();
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
          _startDateControllers[index].text = formattedDate;
        } else {
          _endDateControllers[index].text = formattedDate;
        }
      });
    }
  }

  Widget _buildDropdownField(
      BuildContext context, String labelText, List<String> items, int index,
      {required bool editable}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<String>(
          value: _selectedIndustries[index], // Set initial value as 'OTHERS'
          onChanged: editable
              ? (String? newValue) {
                  setState(() {
                    _selectedIndustries[index] = newValue;
                    // Clear the text when anything other than 'Others' is selected
                    if (newValue != 'OTHERS') {
                      _otherIndustryControllers[index].clear();
                    }
                  });
                }
              : null,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value.toUpperCase(),
              child: Text(value.toUpperCase()),
            );
          }).toList(),
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          ),
        ),
        const SizedBox(height: 10.0),
        // Only show the text field if "Others" is selected
        if (_selectedIndustries[index] == 'OTHERS')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please specify the industry',
                  style: AppWidget.semiBoldTextFieldStyle()),
              const SizedBox(height: 10.0),
              TextField(
                controller: _otherIndustryControllers[index],
                enabled: editable,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 15.0),
                  hintText: 'Enter Industry',
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInputField(BuildContext context, String labelText,
      TextEditingController controller, bool isEditable, String? errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        TextField(
          controller: controller,
          enabled: isEditable,
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
}
