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
      icon: 'misc_bet',
      title: 'Gamify your routine.',
      description: 'Make good habits hard to quit — with streak-building and friendly bets.',
      color: LWColors.primaryBase,
    ),
    const _OnboardingData(
      icon: 'nav_home',
      title: 'Pick a challenge',
      description: 'Swipe to join or create.',
      color: LWColors.primaryBase,
    ),
    const _OnboardingData(
      icon: 'misc_streak',
      title: 'Check in daily',
      description: 'Keep your streak alive.',
      color: LWColors.primaryBase,
    ),
    const _OnboardingData(
      icon: 'tag_stake_gift',
      title: 'Add stakes',
      description: 'Bet on yourself or friends.',
      color: LWColors.primaryBase,
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
    Hive.box('settings').put('onboarding_completed', true);
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
              return _OnboardingSlide(data: _slides[index]);
            },
          ),
          
          // Bottom controls
          Positioned(
            left: LWSpacing.xl,
            right: LWSpacing.xl,
            bottom: MediaQuery.paddingOf(context).bottom + LWSpacing.xl,
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
                          : lw.brandPrimary.withOpacity(0.2),
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
                      elevation: 0,
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
              top: MediaQuery.paddingOf(context).top + LWSpacing.md,
              right: LWSpacing.md,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Skip',
                  style: LWTypography.smallNormalMedium.copyWith(
                    color: LWColors.inkLighter,
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
    
    return Container(
      width: double.infinity,
      color: lw.backgroundApp,
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Visual Area
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: LwIcon(
                data.icon,
                size: 80,
                color: data.color,
              ),
            ),
          ),
          const Spacer(flex: 2),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LWSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.title,
                  style: LWTypography.title3.copyWith(
                    color: LWColors.inkBase,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: LWSpacing.md),
                Text(
                  data.description,
                  style: LWTypography.regularNormalRegular.copyWith(
                    color: LWColors.inkLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(flex: 4),
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
