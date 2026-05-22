import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../shared/widgets/custom_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingCardData> _slides = [
    const OnboardingCardData(
      title: 'Smart Tourist Safety',
      description: 'Real-time location sharing, automatic geofencing alert zones, and dynamic route monitoring to keep you safe.',
      icon: Icons.shield_outlined,
      gradient: [Color(0xFF1E3C72), Color(0xFF2A5298)],
    ),
    const OnboardingCardData(
      title: 'AI Safety Assistant',
      description: 'An AI-powered local assistant running on Ollama, responding instantly to emergency questions, weather changes, and safety guidelines.',
      icon: Icons.psychology_outlined,
      gradient: [Color(0xFF3A1C71), Color(0xFFD76D77)],
    ),
    const OnboardingCardData(
      title: 'Offline Emergency Mesh',
      description: 'Offline-first safety reporting using BLE, Wi-Fi Direct multi-hop mesh routing, and automated SMS relays when network coverage is lost.',
      icon: Icons.wifi_off_outlined,
      gradient: [Color(0xFF0F2027), Color(0xFF203A43)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _slides[_currentPage].gradient,
              ),
            ),
          ),
          // Subtle circular ambient lights
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Onboarding Slides Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: UiConstants.spaceLG),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.travel_explore, color: Colors.white, size: 28),
                    const SizedBox(width: UiConstants.spaceSM),
                    Text(
                      'TravelTrek',
                      style: AppTextStyles.appTitle.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UiConstants.spaceLG,
                          vertical: UiConstants.spaceXL,
                        ),
                        child: Center(
                          child: GlassCard(
                            opacity: 0.12,
                            padding: const EdgeInsets.all(UiConstants.spaceLG),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  child: Icon(
                                    slide.icon,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: UiConstants.spaceLG),
                                Text(
                                  slide.title,
                                  style: AppTextStyles.screenTitle.copyWith(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: UiConstants.spaceMD),
                                Text(
                                  slide.description,
                                  style: AppTextStyles.bodyText.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Indicators & Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: UiConstants.spaceLG),
                  child: Column(
                    children: [
                      // Page Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: _currentPage == index ? 24.0 : 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: UiConstants.spaceXL),
                      // CTA Button
                      LoadingButton(
                        backgroundColor: Colors.white,
                        textColor: AppColors.primaryNavy,
                        onPressed: () {
                          context.go('/login');
                        },
                        text: 'Get Started',
                      ),
                      const SizedBox(height: UiConstants.spaceLG),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingCardData {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  const OnboardingCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
