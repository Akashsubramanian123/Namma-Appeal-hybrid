import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'auth_screen.dart';

// ==========================================
// 1. SPLASH SCREEN — navy bg + saffron glow
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
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthWrapper()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1A237E);
    const saffron = Color(0xFFFF8F00);

    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Saffron circular glow behind logo
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: saffron.withOpacity(0.45),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Semantics(
                  label: 'App Logo',
                  image: true,
                  child: Image.asset(
                    'assets/page_icon_custom.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              "Namma-Appeal",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            const Text(
              "Empowering Citizens. One RTI at a Time.",
              style: TextStyle(fontSize: 13, color: Colors.white60),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: saffron),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. ONBOARDING SCREEN — saffron dots + navy buttons
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
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1A237E);
    const saffron = Color(0xFFFF8F00);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPage(
                icon: Icons.balance,
                title: "Empowering Your Rights",
                description:
                    "Namma-Appeal simplifies the Right to Information process, ensuring your civic voice is heard.",
                navy: navy,
                saffron: saffron,
              ),
              _buildPage(
                icon: Icons.document_scanner_outlined,
                title: "Scan Rejections with AI",
                description:
                    "Take a photo of any rejected RTI response. Our AI will analyze the legal flaws and draft a First Appeal instantly.",
                navy: navy,
                saffron: saffron,
              ),
              _buildPage(
                icon: Icons.auto_awesome,
                title: "Draft Fresh RTIs",
                description:
                    "Describe a civic issue or upload a photo of a problem, and generate a legally sound RTI application in seconds.",
                navy: navy,
                saffron: saffron,
              ),
            ],
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _finishOnboarding,
                  child: Text("Skip",
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 16)),
                ),

                // Dot indicators — active = saffron
                Row(
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? saffron
                            : Colors.grey[350],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_currentPage == 2) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  },
                  child: Text(_currentPage == 2 ? "Get Started" : "Next"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String description,
    required Color navy,
    required Color saffron,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with saffron circle behind it
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: navy.withOpacity(0.06),
              border: Border.all(color: saffron.withOpacity(0.35), width: 2),
            ),
            child: Semantics(
              label: 'Onboarding Graphic',
              image: true,
              child: Icon(icon, size: 72, color: navy),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: navy,
                height: 1.3),
          ),
          const SizedBox(height: 18),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, height: 1.6, color: Colors.black54),
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
              body: Center(child: CircularProgressIndicator()));
        }
        final session = snapshot.data?.session;
        return session != null
            ? const MainNavigationScreen()
            : const AuthScreen();
      },
    );
  }
}
