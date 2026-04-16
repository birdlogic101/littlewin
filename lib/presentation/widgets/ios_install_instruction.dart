import 'dart:html' if (dart.library.io) 'html_stub.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'lw_icon.dart';
import '../../core/theme/design_system.dart';

/// A widget that provides instructions on how to install the PWA on iOS.
/// 
/// It only displays if:
/// 1. The platform is iOS.
/// 2. The app is running in the browser (not standalone/installed).
/// 3. The user has not dismissed the instruction in this session.
class IosInstallInstruction extends StatefulWidget {
  const IosInstallInstruction({super.key});

  @override
  State<IosInstallInstruction> createState() => _IosInstallInstructionState();
}

class _IosInstallInstructionState extends State<IosInstallInstruction> {
  bool _isVisible = false;
  static bool _sessionDismissed = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  void _checkVisibility() {
    if (!kIsWeb || _sessionDismissed) return;

    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isIos = userAgent.contains('iphone') || 
                    userAgent.contains('ipad') || 
                    userAgent.contains('ipod');
      
      // Check if running in standalone mode (already installed)
      // On iOS Safari, window.navigator.standalone is the way.
      // On other browsers, we check the display-mode media query.
      final isStandalone = html.window.matchMedia('(display-mode: standalone)').matches || 
                           (html.window.navigator as dynamic).standalone == true;

      if (isIos && !isStandalone) {
        setState(() {
          _isVisible = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking PWA visibility: $e');
    }
  }

  void _dismiss() {
    setState(() {
      _isVisible = false;
      _sessionDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final lw = LWThemeExtension.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lw.backgroundSheet.withOpacity(0.9),
          borderRadius: BorderRadius.circular(LWRadius.md),
          border: Border.all(color: lw.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: lw.backgroundOverlay.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Install Littlewin',
                        style: LWTypography.title3.copyWith(color: lw.contentPrimary),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                          children: [
                            const TextSpan(text: 'Tap the '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Icon(
                                  CupertinoIcons.share,
                                  size: 18,
                                  color: lw.brandPrimary,
                                ),
                              ),
                            ),
                            const TextSpan(text: ' Share button then select '),
                            TextSpan(
                              text: '"Add to Home Screen"',
                              style: TextStyle(
                                color: lw.contentPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close, size: 20, color: lw.contentDisabled),
                  onPressed: _dismiss,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
