import 'package:educore/src/core/mvc/controller_builder.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/ui/widgets/access_denied_view.dart';
import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/hover_scale.dart';
import 'package:educore/src/features/settings/models/settings_models.dart';
import 'package:educore/src/features/settings/settings_controller.dart';
import 'package:educore/src/features/settings/widgets/sections/general_settings_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/notification_settings_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/payment_settings_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/plan_features_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/security_settings_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/system_preferences_panel.dart';
import 'package:educore/src/features/settings/widgets/sections/document_settings_panel.dart';
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
        final featureSvc = AppServices.instance.featureAccessService;
        if (featureSvc == null || !featureSvc.canAccess('settings_view')) {
          return AccessDeniedView(
            featureName:
                controller.isSuperAdmin ? 'Platform Settings' : 'Institute Settings',
          );
        }
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
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedSlideIn(
                    delayIndex: 0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.isSuperAdmin
                                    ? 'Platform Settings'
                                    : 'Institute Settings',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Platform configuration and preferences.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (featureSvc.canAccess('settings_edit'))
                          HoverScale(
                            child: AppPrimaryButton(
                              label: 'Save changes',
                              icon: Icons.save_rounded,
                              busy: controller.busy,
                              onPressed: () async {
                                AppDialogs.showLoading(context, message: 'Syncing settings...');
                                await controller.save();
                                if (!context.mounted) return;
                                AppDialogs.hide(context);
                                AppDialogs.showSuccess(
                                  context,
                                  title: 'Settings Saved',
                                  message: 'Your configuration preferences have been successfully updated and synced across the platform.',
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _AnimatedSlideIn(
                    delayIndex: 1,
                    child: Builder(builder: (context) {
                      if (stacked) {
                        return Column(
                          children: [
                            nav,
                            const SizedBox(height: 12),
                            content,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 300, child: nav),
                          const SizedBox(width: 32),
                          Expanded(child: content),
                        ],
                      );
                    }),
                  ),
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
      SettingsSection.planAndFeatures =>
        PlanFeaturesPanel(controller: controller),
      SettingsSection.paymentSettings =>
        PaymentSettingsPanel(controller: controller),
      SettingsSection.documentCustomization =>
        DocumentSettingsPanel(controller: controller),
      SettingsSection.notificationSettings =>
        NotificationSettingsPanel(controller: controller),
      SettingsSection.security => SecuritySettingsPanel(controller: controller),
    };
  }
}

class _AnimatedSlideIn extends StatelessWidget {
  const _AnimatedSlideIn({required this.child, required this.delayIndex});
  final Widget child;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delayIndex * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
