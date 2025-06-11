import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../widgets/animated_game_background.dart';
import '../../application/view_models/auth_view_model.dart';
import '../../application/view_models/game_view_model.dart';
import 'home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailOrUsernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.login(
        emailOrUsername: _emailOrUsernameController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        if (success) {
          // Sync user game states after successful login
          final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
          final currentUser = authViewModel.currentUser;
          if (currentUser != null) {
            gameViewModel.syncUserGameStates(currentUser.id);
          }
          
          // Navigate to HomeScreen and clear the navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Login failed'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Animated game icons background
          AnimatedGameBackground(
            gameIcons: const [],
            opacity: 0.12,
          ),
          
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  theme.colorScheme.secondary.withOpacity(0.5),
                  theme.colorScheme.primary.withOpacity(0.4),
                  theme.colorScheme.tertiary?.withOpacity(0.3) ?? Colors.purple.withOpacity(0.3),
                  theme.scaffoldBackgroundColor.withOpacity(0.9),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isTablet = screenWidth > 600;
                
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 500 : double.infinity,
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? screenWidth * 0.2 : 24.0,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Login form container
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white.withOpacity(0.1),
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
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // App icon
                                      Container(
                                        width: 80,
                                        height: 80,
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
                                        child: const Icon(
                                          Icons.videogame_asset_rounded,
                                          size: 40,
                                          color: Colors.white,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Welcome Back title
                                      Text(
                                        'Welcome Back',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Email/Username field
                                      _buildGlassTextField(
                                        controller: _emailOrUsernameController,
                                        label: 'Email or Username',
                                        icon: Icons.person_outline_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email or username';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Password field
                                      _buildGlassTextField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscureText: _isPasswordObscured,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordObscured 
                                                ? Icons.visibility_off_outlined 
                                                : Icons.visibility_outlined,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                          onPressed: () => setState(() => 
                                              _isPasswordObscured = !_isPasswordObscured),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          return null;
                                        },
                                      ),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Forgot password
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: authViewModel.isLoading ? null : () {
                                            print('Forgot Password Tapped');
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Login button
                                      authViewModel.isLoading
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
                                              text: 'Sign In',
                                              icon: Icons.login_rounded,
                                              onPressed: _submitForm,
                                            ),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Sign up link
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: authViewModel.isLoading ? null : () {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                                              );
                                            },
                                            child: Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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