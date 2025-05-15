import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:google_fonts/google_fonts.dart'; // For direct font use if needed
import '../../application/view_models/auth_view_model.dart'; // Import AuthViewModel
import 'login_screen.dart'; 

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final success = await authViewModel.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) { 
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Registration successful! Please login.'),
              backgroundColor: Theme.of(context).colorScheme.primary, // Use a success color or primary
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Registration failed'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context); // Access theme data

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Gamestagram Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(Icons.app_registration_rounded, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Join Gamestagram',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username (4-20 characters)',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary.withOpacity(0.7)),
                ),
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.trim().length < 4 || value.trim().length > 20) {
                    return 'Username must be between 4 and 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary.withOpacity(0.7)),
                ),
                keyboardType: TextInputType.emailAddress,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email address';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Min. 8 characters, 1 digit',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.colorScheme.primary.withOpacity(0.7)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                    onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured)
                  ),
                ),
                obscureText: _isPasswordObscured,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (value.length < 8) return 'Password must be at least 8 characters long';
                  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain at least one digit';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.colorScheme.primary.withOpacity(0.7)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: theme.colorScheme.primary.withOpacity(0.7),
                    ),
                    onPressed: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured)
                  ),
                ),
                obscureText: _isConfirmPasswordObscured,
                style: theme.textTheme.bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              authViewModel.isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                  : ElevatedButton(
                      // Style inherited from theme
                      onPressed: _submitForm,
                      child: const Text('Create Account'),
                    ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Already have an account? ', style: theme.textTheme.bodyMedium),
                  TextButton(
                    // Style inherited from theme
                    onPressed: authViewModel.isLoading ? null : () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                    },
                    child: const Text('Login Now'),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Extra space at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
 