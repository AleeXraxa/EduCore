import 'package:firebase_auth/firebase_auth.dart';
import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/core/services/auth_exceptions.dart';
import 'package:educore/src/features/login/seed/super_admin_seed.dart';
import 'package:flutter/foundation.dart';
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
                final ctx = context;
                AppDialogs.showLoading(ctx, message: 'Seeding Super Admin...');
                try {
                  await _controller.seedSuperAdmin();
                  if (!ctx.mounted) return;
                  AppDialogs.hide(ctx);
                  if (!ctx.mounted) return;
                  AppDialogs.showSuccess(
                    ctx,
                    title: 'Seed Success',
                    message:
                        'Super Admin account created: ${SuperAdminSeed.email}',
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  AppDialogs.hide(ctx);
                  if (!ctx.mounted) return;
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
        context,
        email: _email.text.trim(),
        password: _password.text,
        rememberMe: _rememberMe,
      );

      // If controller has an error (from runGuarded), we stop here.
      if (_controller.hasError) return;

      final session = AppServices.instance.authService?.session;
      if (session == null) {
        throw AuthException(
          'Session failed to initialize.',
          'session-init-error',
        );
      }

      if (!mounted) return;

      String targetRoute = AppRoutes.dashboard;
      if (session.isSuperAdmin) {
        targetRoute = AppRoutes.dashboard;
      } else if (session.isInstituteAdmin) {
        targetRoute = AppRoutes.instituteDashboard;
      } else if (session.isStaff) {
        targetRoute = AppRoutes.staffDashboard;
      } else if (session.isTeacher) {
        targetRoute = AppRoutes.teacherDashboard;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(targetRoute, (route) => false);
    } on InstitutePendingException catch (e) {
      if (!mounted) return;
      AppDialogs.showInfo(
        context,
        title: '⏳ Account Pending Approval',
        message: e.message,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      AppDialogs.showError(
        context,
        title: 'Access Denied',
        message: e.message,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Authentication failed.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Invalid email or password. Please check your credentials.';
      } else if (e.code == 'network-request-failed') {
        message = 'Connection failed. Please check your internet connection.';
      } else {
        message = e.message ?? 'An unexpected authentication error occurred.';
      }

      AppDialogs.showError(context, title: 'Sign In Failed', message: message);
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showError(
        context,
        title: 'Opps! Something went wrong',
        message: e.toString(),
      );
    }
  }
}
