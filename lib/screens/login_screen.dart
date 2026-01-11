import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ai_calorie_tracker/providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<ShadFormState>();
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
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<UserProvider>(context, listen: false);

    try {
      if (_useMagicLink) {
        await provider.signInWithMagicLink(_emailController.text.trim());
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast(
              title: Text('Check your email!'),
              description: Text('Login link sent. Check Mailpit at http://127.0.0.1:54334'),
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
          ShadToaster.of(context).show(
            const ShadToast(
              title: Text('Account created!'),
              description: Text('You can now log in.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text(e.toString()),
          ),
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
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Google Sign In failed'),
            description: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return Scaffold(
      body: ShadToaster(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Header
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              Color.lerp(theme.colorScheme.primary, Colors.white, 0.3)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          LucideIcons.leaf,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',
                      style: theme.textTheme.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI Calorie Tracker',
                      style: theme.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Form
                    ShadForm(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShadInputFormField(
                            id: 'email',
                            controller: _emailController,
                            label: const Text('Email'),
                            placeholder: const Text('you@example.com'),
                            leading: const Icon(LucideIcons.mail, size: 16),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v.contains('@') ? null : 'Enter a valid email',
                          ),
                          if (!_useMagicLink) ...[
                            const SizedBox(height: 16),
                            ShadInputFormField(
                              id: 'password',
                              controller: _passwordController,
                              label: const Text('Password'),
                              placeholder: const Text('Enter your password'),
                              leading: const Icon(LucideIcons.lock, size: 16),
                              obscureText: true,
                              validator: (v) => v.length < 6 ? 'Min 6 characters' : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_isLoading)
                      Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ShadButton(
                            onPressed: _submit,
                            size: ShadButtonSize.lg,
                            child: Text(_useMagicLink 
                                ? 'Send Magic Link' 
                                : (_isLogin ? 'Login' : 'Sign Up')),
                          ),
                          const SizedBox(height: 12),
                          ShadButton.ghost(
                            onPressed: () => setState(() => _useMagicLink = !_useMagicLink),
                            child: Text(_useMagicLink 
                                ? 'Use password instead' 
                                : 'Use magic link (passwordless)'),
                          ),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: theme.textTheme.muted),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          if (_supportsSocialLogin) ...[
                            ShadButton.outline(
                              onPressed: _googleSignIn,
                              size: ShadButtonSize.lg,
                              leading: const Icon(LucideIcons.globe, size: 20),
                              child: const Text('Continue with Google'),
                            ),
                            const SizedBox(height: 12),
                            ShadButton.outline(
                              onPressed: () {
                                ShadToaster.of(context).show(
                                  const ShadToast(
                                    title: Text('Coming Soon'),
                                    description: Text('Apple Sign In needs OAuth configuration'),
                                  ),
                                );
                              },
                              size: ShadButtonSize.lg,
                              leading: const Icon(LucideIcons.apple, size: 20),
                              child: const Text('Continue with Apple'),
                            ),
                          ] else
                            Text(
                              'Social Login available on Mobile & Web',
                              style: theme.textTheme.muted,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    
                    if (!_useMagicLink)
                      ShadButton.link(
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
      ),
    );
  }
}
