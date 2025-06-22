import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/view_models/web3_auth_view_model.dart';
import '../../core/theme/app_theme.dart';

class Web3RegistrationScreen extends StatefulWidget {
  const Web3RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<Web3RegistrationScreen> createState() => _Web3RegistrationScreenState();
}

class _Web3RegistrationScreenState extends State<Web3RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _showMnemonic = false;
  String? _mnemonic;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
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
              Expanded(
                child:
                    _showMnemonic
                        ? _buildMnemonicView()
                        : _buildRegistrationForm(),
              ),
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
            'Create Web3 Account',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join the blockchain gaming revolution',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          // Web3 Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureIcon(Icons.fingerprint, 'Passkey'),
              const SizedBox(width: 16),
              _buildFeatureIcon(Icons.account_balance_wallet, 'Wallet'),
              const SizedBox(width: 16),
              _buildFeatureIcon(Icons.token, 'Tokens'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
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
            // Username Field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a unique username',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a username';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Web3 Features Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'What you\'ll get:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem('🔐 Secure Passkey authentication'),
                  _buildFeatureItem('💰 Stellar wallet with test XLM'),
                  _buildFeatureItem('🎮 Play-to-earn gaming tokens'),
                  _buildFeatureItem('🌐 Decentralized identity'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Create Account Button
            Consumer<Web3AuthViewModel>(
              builder: (context, authViewModel, child) {
                return ElevatedButton(
                  onPressed:
                      authViewModel.isLoading ? null : _handleRegistration,
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
                              const Icon(Icons.add_circle, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Create Web3 Account',
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
                  'Already have an account? ',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to login screen
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'Login',
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

  Widget _buildMnemonicView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade100,
            ),
            child: Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Account Created Successfully!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Your Stellar wallet has been created. Please save your recovery phrase:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Mnemonic Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recovery Phrase',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _mnemonic ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange.shade800,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Write this down and keep it safe. You\'ll need it to recover your wallet.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Continue Button
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.rocket_launch, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Start Gaming',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.green.shade600),
      ),
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    final authViewModel = Provider.of<Web3AuthViewModel>(
      context,
      listen: false,
    );

    final success = await authViewModel.register(
      username: username,
      email: email,
    );

    if (success && mounted) {
      // Get the mnemonic from the registration result
      // In a real implementation, this would come from the service
      _mnemonic =
          'sample recovery phrase twelve words long for demonstration purposes';

      setState(() {
        _showMnemonic = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Welcome to Gamestagram Web3, $username!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
