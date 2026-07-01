import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Central animation durations for consistency across the app.
class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 300);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.elasticOut;
  static const Curve bounceCurve = Curves.easeOutBack;
}

/// Helper to wrap a list of children with staggered slide-in animations.
class StaggeredFadeIn {
  static Widget item({
    required int index,
    required Widget child,
    Duration duration = const Duration(milliseconds: 350),
    Offset slideOffset = const Offset(0, 20),
  }) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: duration,
      child: SlideAnimation(
        verticalOffset: slideOffset.dy,
        horizontalOffset: slideOffset.dx,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  static Widget build({
    required int index,
    required Widget child,
    Duration duration = const Duration(milliseconds: 350),
  }) {
    return item(index: index, child: child, duration: duration);
  }
}

/// A wrapper that slides and fades its child in when it first appears.
class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.offset = 20,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// A branded loading indicator with subtle animation.
class BrandedLoadingIndicator extends StatelessWidget {
  const BrandedLoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            width: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: scheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scale animation for press/tap feedback on cards and buttons.
class AnimatedPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const AnimatedPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  @override
  State<AnimatedPressScale> createState() => _AnimatedPressScaleState();
}

class _AnimatedPressScaleState extends State<AnimatedPressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
      value: 1,
    );
    _animation = Tween<double>(begin: 1, end: widget.scale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _controller.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return Transform.scale(
            scale: _animation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Pulse animation for attention-grabbing elements (e.g., notification badges).
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}
