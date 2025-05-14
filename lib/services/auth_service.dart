import '../data/models/user_model.dart'; // Adjust path as necessary

class AuthService {
  // Mocked data store for users
  final Map<String, String> _mockUserPasswords = {}; // email: password
  final Map<String, UserModel> _mockUserDetails = {}; // email: UserModel
  int _userIdCounter = 1;

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (_mockUserDetails.containsKey(email)) {
      return {'success': false, 'message': 'Email already in use'};
    }
    // Simple username check (in a real app, this would be a DB query)
    if (_mockUserDetails.values.any((user) => user.username == username)) {
      return {'success': false, 'message': 'Username already taken'};
    }

    _userIdCounter++; // Increment first
    String userId = _userIdCounter.toString(); // Then convert to string
    UserModel newUser = UserModel(id: userId, username: username, email: email);
    _mockUserPasswords[email] = password; // In a real app, hash the password!
    _mockUserDetails[email] = newUser;

    return {'success': true, 'message': 'Registration successful', 'user': newUser};
  }

  Future<Map<String, dynamic>> login({
    required String emailOrUsername,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Find user by email or username
    UserModel? foundUser;
    String? userEmailKey;

    if (_mockUserDetails.containsKey(emailOrUsername)) { // Check if it's an email
      foundUser = _mockUserDetails[emailOrUsername];
      userEmailKey = emailOrUsername;
    } else { // Check if it's a username
      for (var entry in _mockUserDetails.entries) {
        if (entry.value.username == emailOrUsername) {
          foundUser = entry.value;
          userEmailKey = entry.key;
          break;
        }
      }
    }

    if (foundUser != null && userEmailKey != null && _mockUserPasswords[userEmailKey] == password) {
      return {'success': true, 'message': 'Login successful', 'user': foundUser};
    }

    return {'success': false, 'message': 'Invalid email/username or password'};
  }

  // Placeholder for logout if needed later
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Clear session, etc.
    print('User logged out');
  }
} 