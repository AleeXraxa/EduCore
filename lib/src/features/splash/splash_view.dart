import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/core/constants/prefs_keys.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_page_background.dart';
import 'package:educore/src/core/ui/widgets/app_card.dart';
import 'package:educore/src/core/ui/widgets/powered_by_footer.dart';
import 'package:educore/src/features/splash/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final AnimationController _floaty;
  late final Animation<double> _floatOffset;
  late final AnimationController _progress;
  late final SplashController _splash;

  @override
  void initState() {
    super.initState();
    _splash = SplashController();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();

    _floaty = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _floatOffset = CurvedAnimation(
      parent: _floaty,
      curve: Curves.easeInOutSine,
    );

    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _start();
  }

  @override
  void dispose() {
    _splash.dispose();
    _controller.dispose();
    _floaty.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await Future.wait<void>([
      _splash.initializeApp(),
      _progress.forward(from: 0),
    ]);
    if (!mounted) return;

    final expectsSignIn = await AppServices.instance.prefs.getBool(
      PrefsKeys.signedIn,
    );

    bool actualSignIn = false;
    if (expectsSignIn) {
      final authService = AppServices.instance.authService;
      if (authService != null) {
        try {
          // Attempt to restore and re-validate the session.
          // This ensures that even if credentials are locally cached,
          // we still check against server-side status (Blocked Academy, Expired Sub, etc.)
          await authService.refreshSession();
          // Only route to dashboard if the restored session belongs to a Super Admin.
          // Any other role (institute admin, teacher, etc.) is bounced to login.
          actualSignIn = authService.isAuthenticated;
        } catch (_) {
          actualSignIn = false;
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      actualSignIn ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_floaty, _progress]),
        builder: (context, _) {
          final floatY = (-6 + _floatOffset.value * 12);
          return AppPageBackground(
            child: ControllerBuilder<SplashController>(
              controller: _splash,
              builder: (context, controller, _) {
                return SafeArea(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: Transform.translate(
                            offset: Offset(0, floatY),
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 28,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 520,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.asset(
                                        'assets/images/logo_v2.jpg',
                                        width: 320,
                                        height: 320,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 0),
                                    SpinKitSpinningLines(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 72,
                                      lineWidth: 3.2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: PoweredByFooter(
                            primary: 'Alee',
                            secondary: 'TryUnity Solutions',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
