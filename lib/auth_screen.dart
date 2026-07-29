import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'secrets.dart';

const kRoyalBlue = Color(0xFF2563EB);
const kBackgroundOffWhite = Color(0xFFF8FAFC);
const kTextSlate = Color(0xFF1E293B);
const kTextSecondary = Color(0xFF64748B);
const kRejectedRed = Color(0xFFEF4444);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUp = false;
  static bool _isGoogleInitialized = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
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

  void _showUpdatePasswordDialog() {
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Your Password', style: TextStyle(color: kTextSlate)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please enter your new password below.', style: TextStyle(color: kTextSecondary)),
            const SizedBox(height: 15),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kRoyalBlue, foregroundColor: Colors.white),
            onPressed: () async {
              if (newPasswordController.text.trim().length < 6) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                return;
              }
              final dialogNavigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(ctx);
              try {
                await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPasswordController.text.trim()));
                dialogNavigator.pop();
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
              } catch (e) {
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error updating password: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your email address first.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset link sent! Check your email.')));
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error occurred')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _nativeGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
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
        await Supabase.instance.client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an email and password.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (!_isSignUp) {
        await Supabase.instance.client.auth.signInWithPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      } else {
        await Supabase.instance.client.auth.signUp(email: _emailController.text.trim(), password: _passwordController.text.trim());
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text('Verify Your Email', style: TextStyle(color: kTextSlate)),
              content: const Text('We have sent a confirmation link to your email. Please click it to activate your account, then return here to log in.', style: TextStyle(color: kTextSecondary)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    setState(() { _isSignUp = false; _passwordController.clear(); });
                  },
                  child: const Text('Okay', style: TextStyle(color: kRoyalBlue)),
                )
              ],
            ),
          );
        }
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error occurred')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundOffWhite,
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(
            top: -100, left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(width: 400, height: 400, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x262563EB))),
            ),
          ),
          Positioned(
            bottom: -150, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(width: 500, height: 500, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1A10B981))),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, 15))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.05), blurRadius: 15)],
                            ),
                            child: Image.asset('assets/page_icon_custom.png', width: 60, height: 60),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isSignUp ? "Create an Account" : "Welcome Back",
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kTextSlate, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Sign in to your enterprise dashboard",
                            style: TextStyle(fontSize: 14, color: kTextSecondary.withOpacity(0.8), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 32),

                          _buildTextField(controller: _emailController, hint: 'Email Address', icon: Icons.email_outlined),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock_outline, isPassword: true),
                          
                          if (!_isSignUp)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resetPassword,
                                child: const Text('Forgot Password?', style: TextStyle(color: kRoyalBlue, fontWeight: FontWeight.w600)),
                              ),
                            )
                          else
                            const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: kRoyalBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kRoyalBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(_isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () => setState(() => _isSignUp = !_isSignUp),
                            child: Text(
                              _isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up",
                              style: const TextStyle(color: kRoyalBlue, fontWeight: FontWeight.w600),
                            ),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Expanded(child: Divider(color: Colors.black12)),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w600, fontSize: 12))),
                                Expanded(child: Divider(color: Colors.black12)),
                              ],
                            ),
                          ),

                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _nativeGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 54),
                              backgroundColor: Colors.white,
                              foregroundColor: kTextSlate,
                              side: const BorderSide(color: Colors.black12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            // ── Updated to Google's official developer logo URL ──
                            icon: Image.network(
                              'https://img.icons8.com/color/48/000000/google-logo.png', 
                              width: 20, 
                              height: 20,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, color: kTextSlate),
                            ),
                            label: const Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.02), blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: kTextSlate, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: kTextSecondary.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: kTextSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}