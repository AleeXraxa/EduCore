import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/core/services/auth_exceptions.dart';
import 'package:educore/src/features/login/seed/super_admin_seed.dart';
import 'package:flutter/foundation.dart';
import 'package:educore/src/core/constants/prefs_keys.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_page_background.dart';
import 'package:educore/src/core/ui/widgets/auth_split_layout.dart';
import 'package:educore/src/features/login/login_controller.dart';
import 'package:educore/src/features/login/widgets/login_form_card.dart';
import 'package:educore/src/features/login/widgets/login_marketing_panel.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late final LoginController _controller;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late final AnimationController _anim;
  late final Animation<double> _leftFade;
  late final Animation<Offset> _rightSlide;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _leftFade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _rightSlide = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _controller.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ControllerBuilder<LoginController>(
        controller: _controller,
        builder: (context, controller, _) {
          return AppPageBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: AuthSplitLayout(
                      left: FadeTransition(
                        opacity: _leftFade,
                        child: const LoginMarketingPanel(),
                      ),
                      right: SlideTransition(
                        position: _rightSlide,
                        child: Form(
                          key: _formKey,
                          child: LoginFormCard(
                            email: _email,
                            password: _password,
                            busy: controller.busy,
                            obscurePassword: _obscurePassword,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            rememberMe: _rememberMe,
                            onRememberChanged: (value) =>
                                setState(() => _rememberMe = value),
                            onSignIn: _onSignIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () async {
                // ignore: use_build_context_synchronously
                final ctx = context;
                AppDialogs.showLoading(
                  ctx,
                  message: 'Seeding Super Admin...',
                );
                try {
                  await _controller.seedSuperAdmin();
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  AppDialogs.hide(ctx);
                  // ignore: use_build_context_synchronously
                  AppDialogs.showSuccess(
                    ctx,
                    title: 'Seed Success',
                    message:
                        'Super Admin account created: ${SuperAdminSeed.email}',
                  );
                } catch (e) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  AppDialogs.hide(ctx);
                  // ignore: use_build_context_synchronously
                  AppDialogs.showError(
                    ctx,
                    title: 'Seed Failed',
                    message: e.toString(),
                  );
                }
              },
              icon: const Icon(Icons.code_rounded),
              label: const Text('DEBUG SEED'),
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            )
          : null,
    );
  }

  Future<void> _onSignIn() async {
    if (_formKey.currentState?.validate() != true) return;

    try {
      await _controller.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );

      // Role guard: this shell is exclusively for Super Admins. If a valid
      // Firebase account exists but belongs to a teacher/staff/institute admin,
      // immediately sign them out and present an access-denied message.
      final session = AppServices.instance.authService?.session;
      if (session == null || !session.isSuperAdmin) {
        await AppServices.instance.authService?.signOut();
        if (!mounted) return;
        AppDialogs.showError(
          context,
          title: 'Access Denied',
          message:
              'This portal is restricted to Super Administrators only. '
              'Please use the correct application for your account role.',
        );
        return;
      }

      // Persist the signed-in flag so the splash screen can route to the
      // dashboard on next app restart without waiting on the Firebase stream.
      await AppServices.instance.prefs.setBool(PrefsKeys.signedIn, true);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      AppDialogs.showError(
        context,
        title: 'Security Access Denied',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showError(
        context,
        title: 'Sign In Failed',
        message:
            'We could not authenticate your credentials. Please verify your email and password and try again.',
      );
    }
  }
}
