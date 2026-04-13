import 'package:educore/src/core/responsive/breakpoints.dart';
import 'package:flutter/material.dart';

class AuthSplitLayout extends StatelessWidget {
  const AuthSplitLayout({
    super.key,
    required this.left,
    required this.right,
    this.maxWidth = 1100,
    this.rightWidth = 440,
    this.gap = 28,
  });

  final Widget left;
  final Widget right;
  final double maxWidth;
  final double rightWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = screenSizeForWidth(constraints.maxWidth);
              final isTwoColumn = size != ScreenSize.compact;

              if (!isTwoColumn) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    left,
                    SizedBox(height: gap),
                    right,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: left),
                  SizedBox(width: gap),
                  SizedBox(width: rightWidth, child: right),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

