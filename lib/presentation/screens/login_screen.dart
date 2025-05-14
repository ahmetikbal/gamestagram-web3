import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            SnackBar(content: Text(authViewModel.errorMessage ?? 'Login failed')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        automaticallyImplyLeading: !authViewModel.isLoading && authViewModel.currentUser == null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.gamepad, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailOrUsernameController,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  hintText: 'Enter your email or username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.emailAddress,
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
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured)),
                ),
                obscureText: _isPasswordObscured,
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
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: _submitForm,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: authViewModel.isLoading ? null : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                        );
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}