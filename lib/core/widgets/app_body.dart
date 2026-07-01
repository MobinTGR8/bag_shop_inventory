import 'package:flutter/material.dart';

import '../utils/responsive.dart';

/// Consistent page padding + max width constraints across screens.
///
/// - Keeps content centered on large displays
/// - Applies sensible padding based on breakpoints
/// - Optional scroll wrapper for column-based pages
class AppBody extends StatelessWidget {
  const AppBody({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.scroll = false,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final bool scroll;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppBreakpoints.pagePadding(context);
    final effectiveMaxWidth =
        maxWidth ?? AppBreakpoints.maxContentWidth(context);

    Widget content = Padding(
      padding: effectivePadding,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: child,
        ),
      ),
    );

    if (scroll) {
      content = SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: content,
      );
    }

    return SafeArea(
      bottom: false,
      child: content,
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A premium card wrapper with consistent styling.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF162A3E)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? scheme.outline.withOpacity(0.3)
                  : scheme.outline.withOpacity(0.6)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// A premium gradient card for hero sections.
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  const HeroCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveGradient = gradient ?? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.primary, const Color(0xFF2E5A8F)],
    );

    return Container(
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: effectiveGradient,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}
