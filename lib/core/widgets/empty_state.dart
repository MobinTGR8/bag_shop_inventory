import 'package:flutter/material.dart';

import 'animations.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = 'Nothing here yet',
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FadeInSlide(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 48, color: scheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              if (message != null && message!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
