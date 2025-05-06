import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import 'register_screen.dart';
import 'dart:io';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response =
            Uri.parse('http://172.16.5.8/ASMSLive/users/login.php');
        final request = await HttpClient().postUrl(response);
        request.headers.contentType = ContentType(
            'application', 'x-www-form-urlencoded',
            charset: 'utf-8');
        request.write(Uri(queryParameters: {
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
          'login': '1',
        }).query);

        final httpResponse = await request.close();
        final responseBody =
            await httpResponse.transform(const Utf8Decoder()).join();

        if (responseBody.contains('document.location =\'dashboard.php\'')) {
          // Login successful - now fetch user data
          await _fetchUserData(_usernameController.text.trim());
        } else {
          setState(() {
            _isLoading = false;
          });

          if (responseBody.contains('Invalid Details')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Invalid username or password'),
                  backgroundColor: Colors.red),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Login failed. Please try again.'),
                  backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchUserData(String username) async {
    try {
      // Fetch user data from backend
      final userDataUrl =
          Uri.parse('http://172.16.5.8/ASMSLive/users/get_user_data.php');
      final request = await HttpClient().postUrl(userDataUrl);
      request.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.write(Uri(queryParameters: {
        'username': username,
      }).query);

      final userDataResponse = await request.close();
      final userDataBody =
          await userDataResponse.transform(const Utf8Decoder()).join();

      setState(() {
        _isLoading = false;
      });

      // Attempt to parse user data
      try {
        final userData = jsonDecode(userDataBody);
        if (userData != null && userData['success'] == true) {
          // Create user model
          final user = User(
            id: userData['id'],
            fullName: userData['fullName'],
            email: userData['email'],
            mobileNumber: userData['mobileNumber'],
          );

          // Store user in provider
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          authProvider.setUser(user);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Login successful!'),
                backgroundColor: Colors.green),
          );

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // User data fetch failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to fetch user data. Please try again.'),
                backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        // JSON parse error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error processing user data: $e'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error fetching user data: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  const Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                  const SizedBox(height: 24),

                  // App Title
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Manage your scholarships easily',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0))
                        : const Text('LOGIN'),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
