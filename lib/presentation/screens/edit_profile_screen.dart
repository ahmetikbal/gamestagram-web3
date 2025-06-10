import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../application/view_models/auth_view_model.dart';
import '../widgets/animated_game_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isCurrentPasswordObscured = true;
  bool _isNewPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final user = authViewModel.currentUser;
      if (user != null) {
        _usernameController.text = user.username;
        _emailController.text = user.email;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Update profile information
      bool success = await authViewModel.updateProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text.trim().isEmpty 
            ? null 
            : _newPasswordController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile updated successfully!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authViewModel.errorMessage ?? 'Failed to update profile',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Animated game icons background
          AnimatedGameBackground(
            gameIcons: const [],
            opacity: 0.08,
          ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  theme.colorScheme.secondary.withOpacity(0.3),
                  theme.colorScheme.primary.withOpacity(0.4),
                  theme.colorScheme.tertiary?.withOpacity(0.2) ?? Colors.purple.withOpacity(0.2),
                  theme.scaffoldBackgroundColor.withOpacity(0.9),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Edit form card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Profile avatar
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.secondary,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'U',
                                        style: GoogleFonts.poppins(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Username field
                                  _buildGlassTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    icon: Icons.person_outline_rounded,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter a username';
                                      }
                                      if (value.trim().length < 3) {
                                        return 'Username must be at least 3 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Email field
                                  _buildGlassTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter an email address';
                                      }
                                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                          .hasMatch(value.trim())) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Password section divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'Change Password (Optional)',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Current password field
                                  _buildGlassTextField(
                                    controller: _currentPasswordController,
                                    label: 'Current Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _isCurrentPasswordObscured,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isCurrentPasswordObscured 
                                            ? Icons.visibility_off_outlined 
                                            : Icons.visibility_outlined,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      onPressed: () => setState(() => 
                                          _isCurrentPasswordObscured = !_isCurrentPasswordObscured),
                                    ),
                                    validator: (value) {
                                      // Only validate if user is trying to change password
                                      if (_newPasswordController.text.isNotEmpty) {
                                        if (value == null || value.isEmpty) {
                                          return 'Current password required to change password';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // New password field
                                  _buildGlassTextField(
                                    controller: _newPasswordController,
                                    label: 'New Password (Leave empty to keep current)',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _isNewPasswordObscured,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isNewPasswordObscured 
                                            ? Icons.visibility_off_outlined 
                                            : Icons.visibility_outlined,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      onPressed: () => setState(() => 
                                          _isNewPasswordObscured = !_isNewPasswordObscured),
                                    ),
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (value.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Confirm new password field
                                  _buildGlassTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm New Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _isConfirmPasswordObscured,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordObscured 
                                            ? Icons.visibility_off_outlined 
                                            : Icons.visibility_outlined,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      onPressed: () => setState(() => 
                                          _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                                    ),
                                    validator: (value) {
                                      if (_newPasswordController.text.isNotEmpty) {
                                        if (value != _newPasswordController.text) {
                                          return 'Passwords do not match';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  // Save button
                                  _isLoading
                                      ? Container(
                                          width: double.infinity,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        )
                                      : _buildGlassmorphismButton(
                                          text: 'Save Changes',
                                          icon: Icons.save_rounded,
                                          onPressed: _saveProfile,
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                hintStyle: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    icon, 
                    color: Colors.white.withOpacity(0.8),
                    size: 24,
                  ),
                ),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                errorStyle: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphismButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
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