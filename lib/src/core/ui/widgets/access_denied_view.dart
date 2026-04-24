import 'package:flutter/material.dart';

class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({
    super.key,
    this.featureName,
    this.message = 'Contact TryUnity Solutions to gain access or upgrade your plan to unlock this feature.',
  });

  final String? featureName;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Access Restricted',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
            ),
            if (featureName != null) ...[
              const SizedBox(height: 8),
              Text(
                featureName!.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
