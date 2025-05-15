import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // For direct font use if needed

import '../../application/view_models/auth_view_model.dart';
import '../../presentation/screens/home_screen.dart'; // For navigation after login
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
          // Navigation to HomeScreen is handled by the Consumer in main.dart
          // based on authViewModel.currentUser
          print('[LoginScreen] Login reported success by ViewModel. Relying on main.dart Consumer for navigation.');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Login failed'),
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
        title: const Text('Login to Gamestagram'),
        automaticallyImplyLeading: !authViewModel.isLoading && authViewModel.currentUser == null,
      ),
      body: Container(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(Icons.videogame_asset_outlined, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailOrUsernameController,
                  decoration: InputDecoration(
                    labelText: 'Email or Username',
                    hintText: 'Enter your email or username',
                    prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.primary.withOpacity(0.7)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email or username';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary.withOpacity(0.7)),
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
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authViewModel.isLoading ? null : () {
                      print('Forgot Password Tapped');
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                authViewModel.isLoading
                    ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                    : ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Login'),
                      ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Don't have an account? ", style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: authViewModel.isLoading ? null : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                        );
                      },
                      child: const Text('Register Now'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}