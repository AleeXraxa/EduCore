import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/hover_scale.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:educore/src/features/settings/widgets/sections/general_settings_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/notification_settings_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/payment_settings_panel.dart';

import 'package:educore/src/features/settings/widgets/sections/security_settings_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/system_preferences_panel.dart';
import 'package:educore/src/features/settings/widgets/settings_nav.dart';
import 'package:flutter/material.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ControllerBuilder<SettingsController>(
      controller: _controller,
      builder: (context, controller, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = screenSizeForWidth(constraints.maxWidth);
            final stacked = size == ScreenSize.compact;

            final nav = SettingsNav(
              selected: controller.section,
              onSelect: controller.selectSection,
            );

            final content = AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topLeft,
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, anim) {
                final fade =
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                final slide = Tween<Offset>(
                  begin: const Offset(0.01, 0),
                  end: Offset.zero,
                ).animate(fade);
                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(controller.section),
                child: _SectionBody(controller: controller),
              ),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Platform configuration and preferences.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      HoverScale(
                        child: AppPrimaryButton(
                          label: 'Save changes',
                          icon: Icons.save_rounded,
                          busy: controller.busy,
                          onPressed: () async {
                            await controller.save();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settings saved')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (stacked) ...[
                    nav,
                    const SizedBox(height: 12),
                    content,
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 300, child: nav),
                        const SizedBox(width: 16),
                        Expanded(child: content),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.section) {
      SettingsSection.general => GeneralSettingsPanel(controller: controller),

      SettingsSection.paymentSettings => PaymentSettingsPanel(controller: controller),
      SettingsSection.notificationSettings =>
        NotificationSettingsPanel(controller: controller),
      SettingsSection.security => SecuritySettingsPanel(controller: controller),
      SettingsSection.systemPreferences =>
        SystemPreferencesPanel(controller: controller),
    };
  }
}
