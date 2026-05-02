import 'package:flutter/material.dart';

class PaPageBackground extends StatelessWidget {
  const PaPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.surface.withValues(alpha: 0.35),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: child,
    );
  }
}

class PaScreenShell extends StatelessWidget {
  const PaScreenShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return PaPageBackground(
      child: SafeArea(
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
