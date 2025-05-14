import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Added
import '../data/models/user_model.dart'; // Adjust path as necessary

class AuthService {
  static const String _usersKey = 'registered_users';
  static const String _passwordsKey = 'user_passwords'; // Stores email:password
  static const String _userIdCounterKey = 'user_id_counter';

  Map<String, UserModel> _mockUserDetails = {}; // email: UserModel
  Map<String, String> _mockUserPasswords = {}; // email: password
  int _userIdCounter = 0;

  // Flag to ensure prefs are loaded only once
  bool _prefsLoaded = false;

  AuthService() {
    _loadDataFromPrefs(); // Load data when service is instantiated
  }

  Future<void> _loadDataFromPrefs() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersJsonString = prefs.getString(_usersKey);
      if (usersJsonString != null) {
        final List<dynamic> userList = jsonDecode(usersJsonString);
        _mockUserDetails = {
          for (var userData in userList) 
            (userData['email'] as String): UserModel.fromJson(userData as Map<String, dynamic>)
        };
      }

      final String? passwordsJsonString = prefs.getString(_passwordsKey);
      if (passwordsJsonString != null) {
        _mockUserPasswords = Map<String, String>.from(jsonDecode(passwordsJsonString));
      }
      _userIdCounter = prefs.getInt(_userIdCounterKey) ?? 0;
      _prefsLoaded = true;
      print('[AuthService] Loaded data from SharedPreferences. Users: ${_mockUserDetails.length}, Counter: $_userIdCounter');
    } catch (e) {
      print('[AuthService] Error loading data from SharedPreferences: $e');
      // Initialize with empty if error, or handle more gracefully
      _mockUserDetails = {};
      _mockUserPasswords = {};
      _userIdCounter = 0;
    }
  }

  Future<void> _saveDataToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> userList = _mockUserDetails.values.map((user) => user.toJson()).toList();
      await prefs.setString(_usersKey, jsonEncode(userList));
      await prefs.setString(_passwordsKey, jsonEncode(_mockUserPasswords));
      await prefs.setInt(_userIdCounterKey, _userIdCounter);
      print('[AuthService] Saved data to SharedPreferences. Users: ${_mockUserDetails.length}, Counter: $_userIdCounter');
    } catch (e) {
      print('[AuthService] Error saving data to SharedPreferences: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await _ensurePrefsLoaded(); // Ensure data is loaded before proceeding
    print('[AuthService] Attempting to register: $email, Username: $username');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (_mockUserDetails.containsKey(email)) {
      print('[AuthService] Registration failed: Email $email already in use');
      return {'success': false, 'message': 'Email already in use'};
    }
    // Simple username check (in a real app, this would be a DB query)
    if (_mockUserDetails.values.any((user) => user.username == username)) {
      print('[AuthService] Registration failed: Username $username already taken');
      return {'success': false, 'message': 'Username already taken'};
    }

    _userIdCounter++; // Increment first
    String userId = _userIdCounter.toString(); // Then convert to string
    UserModel newUser = UserModel(id: userId, username: username, email: email);
    _mockUserPasswords[email] = password; // In a real app, hash the password!
    _mockUserDetails[email] = newUser;
    
    await _saveDataToPrefs(); // Save after successful registration

    print('[AuthService] Registration successful for $email. Stored user: ${newUser.username}, Stored pass: $password');
    print('[AuthService] Current _mockUserDetails: $_mockUserDetails');
    print('[AuthService] Current _mockUserPasswords: $_mockUserPasswords');
    return {'success': true, 'message': 'Registration successful', 'user': newUser};
  }

  Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    await _ensurePrefsLoaded();
    print('[AuthService] Attempting login for: $emailOrUsername with password: $password');
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Find user by email or username
    UserModel? foundUser;
    String? userEmailKey;

    if (_mockUserDetails.containsKey(emailOrUsername)) { // Check if it's an email
      foundUser = _mockUserDetails[emailOrUsername];
      userEmailKey = emailOrUsername;
      print('[AuthService] User lookup by email ($emailOrUsername): ${foundUser?.username}');
    } else { // Check if it's a username
      for (var entry in _mockUserDetails.entries) {
        if (entry.value.username == emailOrUsername) {
          foundUser = entry.value;
          userEmailKey = entry.key;
          print('[AuthService] User lookup by username ($emailOrUsername): ${foundUser?.username}, Email key: $userEmailKey');
          break;
        }
      }
    }

    if (foundUser != null && userEmailKey != null && _mockUserPasswords[userEmailKey] == password) {
      print('[AuthService] Login successful for ${foundUser.username}. Password match.');
      return {'success': true, 'message': 'Login successful', 'user': foundUser};
    } else {
      print('[AuthService] Login failed for $emailOrUsername.');
      print('[AuthService] foundUser: ${foundUser?.id}, userEmailKey: $userEmailKey, storedPassword: ${_mockUserPasswords[userEmailKey]}');
      print('[AuthService] Current _mockUserDetails: $_mockUserDetails');
      print('[AuthService] Current _mockUserPasswords: $_mockUserPasswords');
      return {'success': false, 'message': 'Invalid email/username or password'};
    }
  }

  // Helper to ensure prefs are loaded, especially if service is used immediately
  Future<void> _ensurePrefsLoaded() async {
    if (!_prefsLoaded) {
      await _loadDataFromPrefs();
    }
  }

  // Placeholder for logout if needed later
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Clear session, etc.
    print('[AuthService] User logged out');
  }
} 