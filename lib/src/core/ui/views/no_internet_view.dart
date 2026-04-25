import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

/// A full-screen empty state for when a major section fails to load due to connectivity.
class NoInternetView extends StatelessWidget {
  const NoInternetView({
    super.key,
    this.onRetry,
    this.message = 'Please check your connection and try again.',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Premium Illustration / Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 40),
            
            // Action
            if (onRetry != null)
              AppPrimaryButton(
                label: 'Retry Connection',
                onPressed: onRetry!,
                width: 200,
              ),
          ],
        ),
      ),
    );
  }
}
