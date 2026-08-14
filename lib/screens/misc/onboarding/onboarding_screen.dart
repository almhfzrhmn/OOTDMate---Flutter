import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ootdmate_frontend/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildSmoothIndicator(int pageCount) {
    return SmoothPageIndicator(
      controller: _controller,
      count: pageCount,
      effect: ExpandingDotsEffect(
        dotHeight: 8.0,
        dotWidth: 8.0,
        activeDotColor: AppTheme.acidGreen,
        dotColor: Colors.white24,
        expansionFactor: 4,
        spacing: 8,
      ),
    );
  }

  Widget _buildBottomControls() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double page = _controller.hasClients ? (_controller.page ?? 0) : 0;
        bool isLastPage = page.round() == 2; 

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  "SKIP", 
                  style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold),
                ),
              ),
              
              _buildSmoothIndicator(3),
              
              GestureDetector(
                onTap: () {
                  if (isLastPage) {
                    _completeOnboarding();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400), 
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.acidGreen, width: 2),
                    color: isLastPage ? AppTheme.acidGreen : Colors.transparent,
                  ),
                  child: Text(
                    isLastPage ? "START" : "NEXT",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isLastPage ? AppTheme.primary : AppTheme.acidGreen,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                children: [
                  _buildSlide(
                    "AI OOTD Matcher",
                    "Temukan kombinasi pakaian terbaikmu secara instan.",
                    AppTheme.acidGreen,
                  ),
                  _buildSlide(
                    "Smart Wardrobe",
                    "Digitalisasi lemarimu dalam hitungan detik.",
                    AppTheme.neonBlue,
                  ),
                  _buildSlide(
                    "Style Assistant",
                    "AI siap membantu gaya berpakaianmu setiap hari.",
                    AppTheme.glitchMagenta,
                  ),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSlide(String title, String desc, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -1.5,
              shadows: [
                Shadow(
                  color: accentColor, blurRadius: 15
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            style: TextStyle(
              fontSize: 24,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}