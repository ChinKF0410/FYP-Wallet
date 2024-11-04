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

class SoftSkillInfoPage extends StatefulWidget {
  const SoftSkillInfoPage({super.key});

  @override
  _SoftSkillInfoPageState createState() => _SoftSkillInfoPageState();
}

class _SoftSkillInfoPageState extends State<SoftSkillInfoPage> {
  List<Map<String, dynamic>> _skillEntries = [];
  List<TextEditingController> _softSkillControllers = [];
  List<TextEditingController> _descriptionControllers = [];
  List<bool> _isPublicList = [];
  List<int?> _softLevelList = []; // New list to track skill level
  List<String?> _skillNameErrors = [];
  List<String?> _descriptionErrors = [];
  List<int> newEntryIndexes = [];

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    if (!mounted) return;
    super.initState();
    if (!mounted) return;
    _initializeSkillEntries();
    if (!mounted) return;
    _fetchSkillData();
  }

  void _initializeSkillEntries() {
    setState(() {
      _skillEntries.clear();
      _softSkillControllers.clear();
      _descriptionControllers.clear();
      _isPublicList.clear();
      _softLevelList.clear(); // Initialize softLevel list
      _skillNameErrors.clear();
      _descriptionErrors.clear();
      _addSkillEntry(); // Add one set of input fields initially
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

  Future<void> _fetchSkillData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final accountID = await _getAccountID();
    if (accountID == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:4000/api/getCVSkill?accountID=$accountID'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _skillEntries.clear();
            _softSkillControllers.clear();
            _descriptionControllers.clear();
            _isPublicList.clear();
            _softLevelList.clear();
            _skillNameErrors.clear();
            _descriptionErrors.clear();

            if (data.isNotEmpty) {
              for (var entry in data) {
                _skillEntries.add(entry);
                _isPublicList.add(entry['isPublic'] ?? true);
                _softSkillControllers
                    .add(TextEditingController(text: entry['SoftHighlight']));
                _descriptionControllers.add(TextEditingController(
                    text: entry['SoftDescription'] ?? ''));
                _softLevelList.add(entry['SoftLevel'] ?? 1); // Add skill level
                _skillNameErrors.add(null);
                _descriptionErrors.add(null);
              }
            }
          });
        }
      } else {
        devtools.log(
            'Failed to fetch skill data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      devtools.log('Error fetching skill data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addSkillEntry() {
    setState(() {
      _skillEntries.add({
        'SoftID': null,
        'SoftHighlight': '',
        'SoftDescription': '',
        'isPublic': true,
      });
      _softSkillControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _isPublicList.add(true);
      _softLevelList.add(1); // Add default level as "Beginner"
      _skillNameErrors.add(null);
      _descriptionErrors.add(null);
    });
  }

  Future<void> _saveSkills() async {
    final accountID = await _getAccountID();
    if (accountID == null) return;
    if (!mounted) return;

    List<Map<String, dynamic>> newSkillEntries = [];
    List<Map<String, dynamic>> existingSkillEntries = [];
    newEntryIndexes.clear();

    Set<String> skillNamesSet = {};
    bool hasError = false;

    setState(() {
      _skillNameErrors =
          List.generate(_softSkillControllers.length, (index) => null);
      _descriptionErrors =
          List.generate(_descriptionControllers.length, (index) => null);
    });

    for (int i = 0; i < _skillEntries.length; i++) {
      String currentSkillName =
          _softSkillControllers[i].text.trim().toUpperCase();
      String currentDescription =
          _descriptionControllers[i].text.trim().toUpperCase();

      if (skillNamesSet.contains(currentSkillName)) {
        setState(() {
          _skillNameErrors[i] = 'Duplicate skill name found.';
        });
        hasError = true;
        break;
      }

      skillNamesSet.add(currentSkillName);

      if (currentSkillName.isEmpty) {
        setState(() {
          _skillNameErrors[i] = 'Skill name cannot be empty.';
        });
        hasError = true;
        //break;
      }
      if (currentDescription.isEmpty) {
        setState(() {
          _descriptionErrors[i] = 'Description cannot be empty.';
        });
        hasError = true;
        //break;
      }

      final entry = {
        'SoftID': _skillEntries[i]['SoftID'],
        'SoftHighlight': currentSkillName,
        'SoftDescription': currentDescription,
        'isPublic': _isPublicList[i],
        'SoftLevel': _softLevelList[i], // Add the selected skill level
      };

      if (_skillEntries[i]['SoftID'] == null) {
        newSkillEntries.add(entry);
        newEntryIndexes.add(i);
      } else {
        existingSkillEntries.add(entry);
      }
    }

    if (hasError) {
      setState(() {
        _isEditing = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final body = jsonEncode({
      'accountID': accountID,
      'newSkillEntries': newSkillEntries,
      'existingSkillEntries': existingSkillEntries,
    });
    devtools.log("call softskill api");

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:4000/api/saveCVSkill'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      devtools.log(response.statusCode.toString());
      if (!mounted) return;
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List updatedSkills = responseData['newSkillsWithID'];

        if (updatedSkills.length == newSkillEntries.length) {
          for (int i = 0; i < newSkillEntries.length; i++) {
            _skillEntries[newEntryIndexes[i]]['SoftID'] =
                updatedSkills[i]['SoftID'];
            devtools.log(
                "Added SoftID to new entry at index: ${newEntryIndexes[i]}");
          }
        } else {
          devtools.log('Error: Mismatch between new skills and updated IDs.');
        }

        devtools.log('Skill entries saved successfully.');
        setState(() {
          _isEditing = false;
        });
      } else {
        devtools.log(
            'Failed to save skill entries. Status code: ${response.statusCode}');
        showErrorDialog(context, 'Failed to save skill entries');
      }
    } catch (error) {
      devtools.log('Error saving skill entries: $error');
      showErrorDialog(context, 'Error saving skill entries');
    } finally {
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    }
  }

  void _deleteSkillEntry(int index) async {
    final softID = _skillEntries[index]['SoftID'];
    if (softID != null) {
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:4000/api/deleteCVSkill'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'SoftID': softID}),
        );

        if (response.statusCode == 200) {
          setState(() {
            _skillEntries.removeAt(index);
            _softSkillControllers.removeAt(index);
            _descriptionControllers.removeAt(index);
            _isPublicList.removeAt(index);
            //here
            _skillNameErrors.removeAt(index);
            _descriptionErrors.removeAt(index);

            if (_skillEntries.isEmpty) {
              _addSkillEntry(); // Ensure at least one entry remains
            }
          });
        } else {
          showErrorDialog(context, 'Failed to delete skill entry');
        }
      } catch (e) {
        showErrorDialog(context, 'Error deleting skill entry: $e');
      }
    } else {
      //here
      setState(() {
        _skillEntries.removeAt(index);
        _softSkillControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
        _isPublicList.removeAt(index);
        _skillNameErrors.removeAt(index);
        _descriptionErrors.removeAt(index);

        if (_skillEntries.isEmpty) {
          _addSkillEntry(); // Ensure at least one entry remains
        }
      });
    }
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _saveSkills();
        if (!mounted) return;
      } catch (error) {
        devtools.log('Error saving data: $error');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isEditing = true;
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
                  "Skill Information ${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF171B63),
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSkillEntry(index),
                  ),
              ],
            ),
          ),
          _buildInputField(context, 'Skill Name', _softSkillControllers[index],
              _isEditing, _skillNameErrors[index]),
          const SizedBox(height: 15.0),
          _buildInputField(
              context,
              'Description',
              _descriptionControllers[index],
              _isEditing,
              _descriptionErrors[index]),
          const SizedBox(height: 15.0),
          _buildDropdownField(
            context,
            'Skill Level', // Label for dropdown
            index,
          ),
          const SizedBox(height: 15.0),
          if (_isEditing)
            Row(
              children: [
                Checkbox(
                  value: _isPublicList[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _isPublicList[index] = value ?? true;
                    });
                  },
                ),
                const Text('Public'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context, String label, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppWidget.semiBoldTextFieldStyle()),
        const SizedBox(height: 10.0),
        DropdownButtonFormField<int>(
          value: _softLevelList[index],
          onChanged: _isEditing
              ? (int? newValue) {
                  setState(() {
                    _softLevelList[index] = newValue!;
                  });
                }
              : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          ),
          items: const [
            DropdownMenuItem(
              value: 1,
              child: Text('Beginner'),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text('Intermediate'),
            ),
            DropdownMenuItem(
              value: 3,
              child: Text('Advanced'),
            ),
            DropdownMenuItem(
              value: 4,
              child: Text('Expert'),
            ),
            DropdownMenuItem(
              value: 5,
              child: Text('Master'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(
      BuildContext context, String labelText, TextEditingController controller,
      [bool isEditable = true, String? errorMessage]) {
    return TextField(
      controller: controller,
      enabled: isEditable,
      style: AppWidget.semiBoldTextFieldStyle(),
      decoration: InputDecoration(
        labelText: labelText,
        errorText: errorMessage,
        labelStyle: const TextStyle(color: Colors.black),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSkillEntry(BuildContext context, int index) {
    return Column(
      children: [
        _buildInputField(context, 'Skill Name', _softSkillControllers[index],
            _isEditing, _skillNameErrors[index]),
        const SizedBox(height: 10),
        _buildInputField(context, 'Description', _descriptionControllers[index],
            _isEditing, _descriptionErrors[index]),
        const SizedBox(height: 10),
        if (_isEditing)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _deleteSkillEntry(index);
                },
              ),
            ],
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
        title: Text('Skill Information',
            style: AppWidget.headlineTextFieldStyle()),
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
                    itemCount: _skillEntries.length,
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
                                  _addSkillEntry();
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
                        child: const Text('Add More Skills',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16.0)),
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
}
