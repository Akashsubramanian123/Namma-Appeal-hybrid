import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'auth_screen.dart';

// ── Premium SaaS Color Tokens ──
const kRoyalBlue = Color(0xFF2563EB);
const kBackgroundOffWhite = Color(0xFFF8FAFC);
const kTextSlate = Color(0xFF1E293B);
const kTextSecondary = Color(0xFF64748B);
const kRejectedRed = Color(0xFFEF4444);
// ==========================================
// 1. SPLASH SCREEN — Premium Clean Look
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    if (!mounted) return;
    
    if (hasSeenOnboarding) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWrapper()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundOffWhite,
      body: Stack(
        children: [
          // ── Ambient Glow ──
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                height: 300,
                decoration: BoxDecoration(shape: BoxShape.circle, color: kRoyalBlue.withOpacity(0.15)),
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Floating Logo
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: kRoyalBlue.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 10))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset('assets/page_icon_custom.png', width: 110, height: 110, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  "Namma-Appeal",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: kTextSlate, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  "Empowering Citizens. One RTI at a Time.",
                  style: TextStyle(fontSize: 15, color: kTextSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 50),
                
                const CircularProgressIndicator(color: kRoyalBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. ONBOARDING SCREEN — Glassmorphism Cards
// ==========================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundOffWhite,
      body: Stack(
        children: [
          // ── Ambient Orbs ──
          Positioned(
            top: -100, left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: kRoyalBlue.withOpacity(0.15))),
            ),
          ),
          Positioned(
            bottom: -150, right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981).withOpacity(0.1))),
            ),
          ),
          
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPage(
                icon: Icons.balance,
                title: "Empowering Your Rights",
                description: "Namma-Appeal simplifies the Right to Information process, ensuring your civic voice is heard.",
              ),
              _buildPage(
                icon: Icons.document_scanner_outlined,
                title: "Scan Rejections with AI",
                description: "Take a photo of any rejected RTI response. Our AI will analyze the legal flaws and draft a First Appeal instantly.",
              ),
              _buildPage(
                icon: Icons.auto_awesome,
                title: "Draft Fresh RTIs",
                description: "Describe a civic issue or upload a photo of a problem, and generate a legally sound RTI application in seconds.",
              ),
            ],
          ),

          // ── Bottom Navigation Controls ──
          Positioned(
            bottom: 50, left: 30, right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text("Skip", style: TextStyle(color: kTextSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                
                // ── Animated Dots ──
                Row(
                  children: List.generate(3, (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? kRoyalBlue : kRoyalBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
                ),
                
                // ── Action Button ──
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: kRoyalBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRoyalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (_currentPage == 2) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                    child: Text(_currentPage == 2 ? "Get Started" : "Next", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Page Component ──
  Widget _buildPage({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glass Icon Container
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: kTextSlate.withOpacity(0.05), blurRadius: 20)],
                ),
                child: Icon(icon, size: 64, color: kRoyalBlue),
              ),
            ),
          ),
          const SizedBox(height: 50),
          
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kTextSlate, height: 1.2, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.6, color: kTextSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ==========================================
// 3. AUTH WRAPPER
// ==========================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: kBackgroundOffWhite,
            body: Center(child: CircularProgressIndicator(color: kRoyalBlue)),
          );
        }
        final session = snapshot.data?.session;
        return session != null ? const MainNavigationScreen() : const AuthScreen();
      },
    );
  }
}