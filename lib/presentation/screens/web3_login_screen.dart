import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/view_models/web3_auth_view_model.dart';
import '../../core/theme/app_theme.dart';

class Web3LoginScreen extends StatefulWidget {
  const Web3LoginScreen({Key? key}) : super(key: key);

  @override
  State<Web3LoginScreen> createState() => _Web3LoginScreenState();
}

class _Web3LoginScreenState extends State<Web3LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkTheme.primaryColor.withOpacity(0.8),
              AppTheme.darkTheme.primaryColor.withOpacity(0.4),
              AppTheme.darkTheme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              Expanded(child: _buildLoginForm()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Back Button
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            'Welcome Back',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Login with your Web3 account',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          // Passkey Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.fingerprint, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username/Email Field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username or Email',
                hintText: 'Enter your username or email',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your username or email';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Passkey Authentication Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will be prompted to authenticate using your biometric credentials (fingerprint, face ID, or PIN)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Login Button
            Consumer<Web3AuthViewModel>(
              builder: (context, authViewModel, child) {
                return ElevatedButton(
                  onPressed: authViewModel.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppTheme.darkTheme.primaryColor.withOpacity(
                      0.3,
                    ),
                  ),
                  child:
                      authViewModel.isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fingerprint, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Login with Passkey',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Error Message
            Consumer<Web3AuthViewModel>(
              builder: (context, authViewModel, child) {
                if (authViewModel.errorMessage != null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authViewModel.errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: authViewModel.clearError,
                          icon: Icon(
                            Icons.close,
                            color: Colors.red.shade600,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const Spacer(),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to registration screen
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final usernameOrEmail = _usernameController.text.trim();

    final authViewModel = Provider.of<Web3AuthViewModel>(
      context,
      listen: false,
    );

    // For now, use a mock wallet address - in real app, this would come from Passkey
    final mockWalletAddress = 'G' + 'A' * 55; // Mock Stellar address
    final success = await authViewModel.login(walletAddress: mockWalletAddress);

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Welcome back!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}
