/*
A Collaborative Creation:
CHIN KAH FUI
CHIN XUAN HONG
OLIVIA HUANG SI HAN
LIM CHU QING
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'auth_user.dart';
import 'auth_exception.dart';
import 'dart:developer' as devtools show log;
import 'package:shared_preferences/shared_preferences.dart';

class MSSQLAuthProvider implements AuthProvider {
  final String baseUrl = "http://127.0.0.1:4000/api";

  AuthUser? _currentUser;

  get toWalletDB => null;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw GenericAuthException();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      devtools
          .log('Login API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        _currentUser = AuthUser(
          accountID: responseData['id'],
          email: email,
        );

        await _saveUserToPreferences(_currentUser!);
        return _currentUser!;
      } else if (response.statusCode == 404) {
        throw UserNotFoundAuthException();
      } else if (response.statusCode == 401) {
        throw WrongPasswordAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log(email);
      devtools.log('Login Error: $e');
      throw GenericAuthException();
    }
  }

  Future<void> _saveUserToPreferences(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accountID', user.accountID);
    await prefs.setString('email', user.email);
// Assuming user.id is the accountID
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      devtools.log(
          'Register API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _currentUser = AuthUser(
          accountID: responseData['id'],
          email: email,
        );
        await _saveUserToPreferences(_currentUser!);
        return _currentUser!;
      } else if (response.statusCode == 400) {
        throw EmailAlreadyInUseAuthException();
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Register Error: $e');
      throw GenericAuthException();
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    await _clearUserFromPreferences();
  }

  Future<void> _clearUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<void> initialize() async {
    _currentUser = await _getUserFromPreferences();
  }

  Future<AuthUser?> _getUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final accountID = prefs.getInt('accountID');
    final email = prefs.getString('email');

    if (accountID != null && email != null) {
      return AuthUser(
        accountID: accountID,
        email: email,
      );
    }
    return null;
  }

  Future<Map<String, dynamic>?> generateQRCode({
    required String userID,
    required String perID,
    required String eduBacID,
    required String cerID,
    required String softID,
    required String workExpID,
    required String title,
  }) async {
    try {
      final qrData = {
        'userID': userID,
        'PerID': perID,
        'EduBacID': eduBacID,
        'CerID': cerID,
        'SoftID': softID,
        'WorkExpID': workExpID,
        'title': title,
      };
      devtools.log("\n\nPerID is : $softID\n\n\n");
      final response = await http.post(
        Uri.parse('$baseUrl/generateQRCode'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(qrData),
      );

      devtools.log(
          'Generate QRCode API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        devtools.log('QR Code Hash: ${responseData['qrHash']}');

        return responseData;
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Generate QRCode Error: $e');
      throw GenericAuthException();
    }
  }

  Future<List<Map<String, dynamic>>> fetchQRCodesByUserId(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fetchQRCodesByUserId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'userID': userId,
        }),
      );

      devtools.log(
          'Fetch QR Codes by UserID API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(responseData['qrCodes']);
      } else {
        return [];
      }
    } catch (e) {
      devtools.log('Fetch QR Codes Error: $e');
      return [];
    }
  }

  Future<void> deleteQRCode(int qrId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deleteQRCode'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int>{
          'qrID': qrId,
        }),
      );

      devtools.log(
          'Delete QR Code API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete QR Code');
      }
    } catch (e) {
      devtools.log('Delete QR Code Error: $e');
      throw Exception('Error deleting QR Code');
    }
  }

  // Function to fetch CV data by QR ID
  Future<Map<String, dynamic>> fetchCVDataByQRCode(int qrId) async {
    final url = Uri.parse(
        'http://127.0.0.1:4000/api/fetchCVByQRCode'); // Change to actual API URL
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'qrId': qrId}), // Send the QR ID to the backend
    );

    if (response.statusCode == 200) {
      // If the server returns a successful response, decode the JSON and return the data
      return jsonDecode(response.body);
    } else {
      // If the server returns an error, throw an exception
      throw Exception('Failed to fetch CV data.');
    }
  }

  Future<bool> verifyPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verifyPassword'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      devtools.log(
          'Verify Password API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        return false;
      } else {
        throw GenericAuthException();
      }
    } catch (e) {
      devtools.log('Verify Password Error: $e');
      throw GenericAuthException();
    }
  }

  Future<void> changePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      if (newPassword.isEmpty || oldPassword.isEmpty) {
        throw GenericAuthException();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/changePassword'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      devtools.log(
          'Change Password API Response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          throw WrongPasswordAuthException();
        } else if (response.statusCode == 404) {
          throw UserNotFoundAuthException();
        } else {
          throw GenericAuthException();
        }
      }
    } catch (e) {
      devtools.log('Change Password Error: $e');
      throw GenericAuthException();
    }
  }
}
