import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'secrets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;

  static bool _isGoogleInitialized = false;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _showUpdatePasswordDialog();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() => setState(() => _isLogin = !_isLogin);

  void _showUpdatePasswordDialog() {
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Your Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your new password below.'),
            const SizedBox(height: 15),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'New Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text.trim().length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Password must be at least 6 characters')));
                return;
              }
              final dialogNavigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(ctx);
              try {
                await Supabase.instance.client.auth.updateUser(
                    UserAttributes(
                        password: newPasswordController.text.trim()));
                dialogNavigator.pop();
                scaffoldMessenger.showSnackBar(const SnackBar(
                    content: Text('Password updated successfully!')));
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Error updating password: $e')));
              }
            },
            child: const Text('Update Password'),
          )
        ],
      ),
    );
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter your email address first.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password reset link sent! Check your email.')));
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error occurred')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _nativeGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        await Supabase.instance.client.auth
            .signInWithOAuth(OAuthProvider.google);
      } else {
        final googleSignIn = GoogleSignIn.instance;
        if (!_isGoogleInitialized) {
          await googleSignIn.initialize(serverClientId: Secrets.webClientId);
          _isGoogleInitialized = true;
        }
        final googleUser = await googleSignIn.authenticate();
        if (googleUser == null) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        final idToken = googleUser.authentication.idToken;
        if (idToken == null) throw 'Missing Google ID Token.';
        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Google Sign-In Error: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAuth() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter an email and password.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Verify Your Email'),
              content: const Text(
                  'We have sent a confirmation link to your email. Please click it to activate your account, then return here to log in.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _isLogin = true;
                      _passwordController.clear();
                    });
                  },
                  child: const Text('Okay'),
                )
              ],
            ),
          );
        }
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error occurred')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;    // navy
    final saffron = Theme.of(context).colorScheme.secondary;     // saffron

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Namma-Appeal Login' : 'Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/page_icon_custom.png',
                    width: 100, height: 100, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                "Your AI-powered civic assistant to draft, analyze, and track Right to Information (RTI) applications.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[700], height: 1.4),
              ),
              const SizedBox(height: 24),

              // Saffron decorative divider
              Row(
                children: [
                  Expanded(child: Divider(color: saffron, thickness: 1.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.balance, color: saffron, size: 18),
                  ),
                  Expanded(child: Divider(color: saffron, thickness: 1.5)),
                ],
              ),
              const SizedBox(height: 24),

              // Email field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                obscureText: true,
              ),

              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: Text('Forgot Password?',
                        style: TextStyle(color: themeColor)),
                  ),
                )
              else
                const SizedBox(height: 22),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )
              else ...[
                ElevatedButton(
                  onPressed: _submitAuth,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  child: Text(_isLogin ? 'Login' : 'Sign Up',
                      style: const TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR")),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Colors.grey),
                  ),
                  onPressed: _isLoading ? null : _nativeGoogleSignIn,
                  icon: Image.network(
                      'https://img.icons8.com/color/48/000000/google-logo.png',
                      height: 24),
                  label: const Text('Continue with Google',
                      style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLogin
                        ? 'New user? Create Account'
                        : 'Already have an account? Login',
                    style: TextStyle(color: themeColor),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/privacy-policy'),
                      child: Text('Privacy Policy', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ),
                    Text('•', style: TextStyle(color: Colors.grey[400])),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/terms'),
                      child: Text('Terms of Service', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
