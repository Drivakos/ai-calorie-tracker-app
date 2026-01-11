import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _useMagicLink = false;

  // Check if platform supports social login (Mobile or Web)
  bool get _supportsSocialLogin {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<UserProvider>(context, listen: false);

    try {
      if (_useMagicLink) {
        await provider.signInWithMagicLink(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email for the login link! (Check Mailpit at http://127.0.0.1:54334)'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else if (_isLogin) {
        await provider.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await provider.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! You can now log in.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<UserProvider>(context, listen: false).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign In failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Icon(Icons.eco, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'AI Calorie Tracker',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.contains('@') ? null : 'Invalid email',
                  ),
                  if (!_useMagicLink) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_useMagicLink 
                              ? 'Send Magic Link' 
                              : (_isLogin ? 'Login' : 'Sign Up')),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => _useMagicLink = !_useMagicLink),
                          child: Text(_useMagicLink 
                              ? 'Use password instead' 
                              : 'Use magic link (passwordless)'),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_supportsSocialLogin) ...[
                          OutlinedButton.icon(
                            onPressed: _googleSignIn,
                            icon: const Icon(Icons.g_mobiledata, size: 28), 
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Apple Sign In needs OAuth configuration')),
                              );
                            },
                            icon: const Icon(Icons.apple, size: 28),
                            label: const Text('Continue with Apple'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                          ),
                        ] else
                          const Center(
                            child: Text(
                              'Social Login available on Mobile & Web',
                              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (!_useMagicLink)
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin
                          ? 'Don\'t have an account? Sign Up'
                          : 'Already have an account? Login'),
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
