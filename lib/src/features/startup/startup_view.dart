import 'package:educore/src/app/navigation/app_routes.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/ui/app_logo.dart';
import 'package:educore/src/core/ui/widgets/app_centered_card.dart';
import 'package:educore/src/core/ui/widgets/app_page_background.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_section_header.dart';
import 'package:educore/src/features/startup/startup_controller.dart';
import 'package:flutter/material.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  late final StartupController _controller;
  final TextEditingController _academyId = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = StartupController();
  }

  @override
  void dispose() {
    _academyId.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ControllerBuilder<StartupController>(
        controller: _controller,
        builder: (context, controller, _) {
          return AppPageBackground(
            child: AppCenteredCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = screenSizeForWidth(constraints.maxWidth);
                  final isTwoColumn = size != ScreenSize.compact;

                  return isTwoColumn
                      ? Row(
                          children: [
                            const Expanded(child: _LeftPanel()),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _RightPanel(
                                academyId: _academyId,
                                busy: controller.busy,
                                onContinue: _onContinue,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _LeftPanel(compact: true),
                            const SizedBox(height: 16),
                            _RightPanel(
                              academyId: _academyId,
                              busy: controller.busy,
                              onContinue: _onContinue,
                            ),
                          ],
                        );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onContinue() async {
    await _controller.continueToApp();
    if (!mounted) return;
    await Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLogo(size: 52),
          const SizedBox(height: 16),
          Text(
            'EduCore',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Education Management System',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage students, fees, attendance, exams, certificates, and expenses with secure institute isolation.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.academyId,
    required this.busy,
    required this.onContinue,
  });

  final TextEditingController academyId;
  final bool busy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(
            title: 'Get started',
            subtitle: 'Enter your academy ID to continue.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: academyId,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Academy ID',
              hintText: 'e.g. ALC-1024',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
            onSubmitted: (_) => onContinue(),
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            busy: busy,
            onPressed: onContinue,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy ? null : () {},
            icon: const Icon(Icons.lock_outline_rounded),
            label: const Text('Sign in (Coming soon)'),
          ),
        ],
      ),
    );
  }
}
