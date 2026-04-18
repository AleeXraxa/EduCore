import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_animated_slide.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:educore/src/core/ui/widgets/app_search_field.dart';
import 'package:flutter/material.dart';

class ClassesView extends StatelessWidget {
  const ClassesView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAnimatedSlide(
            delayIndex: 0,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Management',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.2,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Define classes, sections, and assign class teachers.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                const AppSearchField(width: 320, hintText: 'Search classes...'),
                const SizedBox(width: 16),
                AppPrimaryButton(
                  onPressed: () {},
                  icon: Icons.add_rounded,
                  label: 'Add Class',
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          AppAnimatedSlide(
            delayIndex: 1,
            child: Container(
              padding: const EdgeInsets.all(48),
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: AppRadii.r24,
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Icon(Icons.class_outlined, size: 64, color: cs.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),
                  Text(
                    'No Classes Defined',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get started by creating your first class and adding sections.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 32),
                  AppPrimaryButton(
                    onPressed: () {},
                    label: 'Create First Class',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
