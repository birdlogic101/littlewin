import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/design_system.dart';
import '../../widgets/lw_icon.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _slides = [
    const _OnboardingData(
      icon: 'nav_home',
      title: 'Explore',
      description: 'Discover challenges from the community and see how others are doing.',
      color: Color(0xFF264653),
    ),
    const _OnboardingData(
      icon: 'nav_checkin',
      title: 'Join & Habit',
      description: 'Join a challenge to start your own run. Consistency is key!',
      color: Color(0xFF2A9D8F),
    ),
    const _OnboardingData(
      icon: 'nav_scores',
      title: 'Streak & Records',
      description: 'Check in every day to grow your streak. Miss a day, and you start over.',
      color: Color(0xFFE9C46A),
    ),
    const _OnboardingData(
      icon: 'misc_bet',
      title: 'Bet on Success',
      description: 'Place symbolic bets on yourself or others to stay motivated.',
      color: Color(0xFFE76F51),
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: LWDuration.standard,
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    // Persist completion state
    Hive.box('settings').put('onboarding_completed', true);
    // Navigate to home and replace
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    
    return Scaffold(
      backgroundColor: lw.backgroundApp,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final data = _slides[index];
              return _OnboardingSlide(data: data);
            },
          ),
          
          // Bottom controls
          Positioned(
            left: LWSpacing.xl,
            right: LWSpacing.xl,
            bottom: MediaQuery.of(context).padding.bottom + LWSpacing.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (index) {
                    return AnimatedContainer(
                      duration: LWDuration.standard,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                          ? lw.brandPrimary 
                          : lw.contentSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: LWSpacing.xl),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lw.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LWRadius.pill),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                      style: LWTypography.regularNormalBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Skip button
          if (_currentPage < _slides.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + LWSpacing.md,
              right: LWSpacing.md,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: LWTypography.smallNormalMedium.copyWith(
                    color: lw.contentSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(LWSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: LwIcon(
                data.icon,
                size: 64,
                color: data.color,
              ),
            ),
          ),
          const SizedBox(height: LWSpacing.xxl),
          Text(
            data.title,
            style: LWTypography.title3.copyWith(color: lw.contentPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LWSpacing.lg),
          Text(
            data.description,
            style: LWTypography.regularNormalRegular.copyWith(
              color: lw.contentSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
