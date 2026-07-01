

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

class LoginScreen extends ConsumerWidget {
  LoginScreen({super.key});

  final form = FormGroup({
    'email': FormControl<String>(
      validators: [Validators.required],
    ),
    'password': FormControl<String>(
      validators: [Validators.required],
    ),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = Theme.of(context).extension<AppBrandColors>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.user == null && next.user != null) {
        context.go('/');
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background with floating particles
          _AnimatedBackground(isDark: isDark, brand: brand, scheme: scheme),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Branding with staggered entrance
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, t, child) {
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, (1 - t) * 30),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            // Premium shimmer logo container
                            _ShimmerLogo(scheme: scheme),
                            const SizedBox(height: 28),
                            Text(
                              'Bag Shop\nInventory',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Manage inventory, sales, and staff\n— fast and secure.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                color: scheme.onPrimary.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Login Card with staggered entrance
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, t, child) {
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, (1 - t) * 40),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surface.withOpacity(0.95)
                                : scheme.surface,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: scheme.outline.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withOpacity(0.08),
                                blurRadius: 60,
                                offset: const Offset(0, 24),
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                                blurRadius: 80,
                                offset: const Offset(0, 40),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: ReactiveForm(
                              formGroup: form,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header with icon
                                  Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              scheme.primary.withOpacity(0.12),
                                              scheme.primary.withOpacity(0.05),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.lock_outline,
                                          color: scheme.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome back',
                                            style: textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Sign in to your account',
                                            style: textTheme.bodyMedium?.copyWith(
                                              color: scheme.onSurface.withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 28),

                                  // Email Field — staggered entrance
                                  _StaggeredFormField(
                                    index: 0,
                                    child: ReactiveTextField(
                                      formControlName: 'email',
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'name@company.com',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: scheme.primary,
                                          size: 20,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? scheme.surfaceContainerHighest.withOpacity(0.3)
                                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: scheme.primary.withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 16,
                                        ),
                                      ),
                                      onChanged: (_) {
                                        if (authState.error != null) {
                                          ref.read(authProvider.notifier).clearError();
                                        }
                                      },
                                    ),
                                  ),
                                  ReactiveValueListenableBuilder<String>(
                                    formControlName: 'email',
                                    builder: (context, control, child) {
                                      if (!control.touched || control.valid) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6, left: 4),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline, size: 14, color: scheme.error),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Email is required',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: scheme.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  // Password Field — staggered entrance
                                  _StaggeredFormField(
                                    index: 1,
                                    child: ReactiveTextField(
                                      formControlName: 'password',
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        hintText: 'Enter your password',
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: scheme.primary,
                                          size: 20,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? scheme.surfaceContainerHighest.withOpacity(0.3)
                                            : scheme.surfaceContainerHighest.withOpacity(0.4),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                            color: scheme.primary.withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 16,
                                        ),
                                      ),
                                      onChanged: (_) {
                                        if (authState.error != null) {
                                          ref.read(authProvider.notifier).clearError();
                                        }
                                      },
                                    ),
                                  ),
                                  ReactiveValueListenableBuilder<String>(
                                    formControlName: 'password',
                                    builder: (context, control, child) {
                                      return control.invalid && control.touched
                                          ? Padding(
                                              padding: const EdgeInsets.only(top: 6, left: 4),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.info_outline, size: 14, color: scheme.error),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Password is required',
                                                    style: textTheme.bodySmall?.copyWith(
                                                      color: scheme.error,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : const SizedBox.shrink();
                                    },
                                  ),

                                  const SizedBox(height: 28),

                                  // Login Button — staggered entrance
                                  _StaggeredFormField(
                                    index: 2,
                                    child: SizedBox(
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: authState.isLoading
                                            ? null
                                            : () async {
                                                if (form.valid) {
                                                  final email = form.control('email').value as String;
                                                  final password = form.control('password').value as String;
                                                  await ref.read(authProvider.notifier).login(
                                                    email: email.trim(),
                                                    password: password,
                                                  );
                                                } else {
                                                  form.markAllAsTouched();
                                                }
                                              },
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: authState.isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Sign In',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Icon(Icons.arrow_forward, size: 20),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 22),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: scheme.outline.withOpacity(0.2))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          'or',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: scheme.onSurface.withOpacity(0.35),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: Divider(color: scheme.outline.withOpacity(0.2))),
                                    ],
                                  ),

                                  const SizedBox(height: 22),

                                  // Register Link
                                  _StaggeredFormField(
                                    index: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: scheme.onSurface.withOpacity(0.5),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => context.go('/register'),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            'Create one',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: scheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Error Message Toast
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: authState.error == null
                  ? const SizedBox.shrink()
                  : Material(
                      key: const ValueKey('auth_error'),
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(18),
                      elevation: 6,
                      shadowColor: scheme.error.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: scheme.error.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.error_outline,
                                color: scheme.error,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref.read(authProvider.notifier).clearError(),
                              icon: Icon(Icons.close, color: scheme.onErrorContainer, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.error.withOpacity(0.08),
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Shimmer Logo
// ===========================================================================

class _ShimmerLogo extends StatefulWidget {
  final ColorScheme scheme;

  const _ShimmerLogo({required this.scheme});

  @override
  State<_ShimmerLogo> createState() => _ShimmerLogoState();
}

class _ShimmerLogoState extends State<_ShimmerLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.scheme.primary.withOpacity(0.25),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.4),
                          Colors.transparent,
                        ],
                        stops: [
                          (_shimmer.value - 0.3).clamp(0.0, 1.0),
                          _shimmer.value.clamp(0.0, 1.0),
                          (_shimmer.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
              // Icon
              Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: widget.scheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Staggered Form Field
// ===========================================================================

class _StaggeredFormField extends StatelessWidget {
  final int index;
  final Widget child;

  const _StaggeredFormField({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 120)),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ===========================================================================
// Animated Background with floating particles
// ===========================================================================

class _AnimatedBackground extends StatefulWidget {
  final bool isDark;
  final AppBrandColors? brand;
  final ColorScheme scheme;

  const _AnimatedBackground({
    required this.isDark,
    required this.brand,
    required this.scheme,
  });

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.brand?.heroGradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(
                      widget.scheme.primary,
                      widget.scheme.secondary,
                      _anim.value * 0.2,
                    )!,
                    Color.lerp(
                      widget.scheme.secondary,
                      widget.scheme.primary,
                      _anim.value * 0.2,
                    )!,
                    widget.scheme.primary.withOpacity(0.9),
                  ],
                ),
          ),
          child: Stack(
            children: [
              const SizedBox.expand(),
              // Floating particles
              _FloatingParticles(isDark: widget.isDark),
            ],
          ),
        );
      },
    );
  }
}

// ===========================================================================
// Floating Particles (bag icons)
// ===========================================================================

class _FloatingParticles extends StatelessWidget {
  final bool isDark;

  const _FloatingParticles({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final particles = [
      const _ParticleData(
        icon: Icons.shopping_bag_outlined,
        size: 24,
        left: 0.08,
        top: 0.12,
        delay: 0,
        duration: 6,
      ),
      const _ParticleData(
        icon: Icons.inventory_2_outlined,
        size: 20,
        left: 0.85,
        top: 0.08,
        delay: 1.5,
        duration: 7,
      ),
      const _ParticleData(
        icon: Icons.local_mall_outlined,
        size: 18,
        left: 0.12,
        top: 0.78,
        delay: 0.8,
        duration: 5.5,
      ),
      const _ParticleData(
        icon: Icons.label_outline,
        size: 16,
        left: 0.9,
        top: 0.75,
        delay: 2,
        duration: 6.5,
      ),
      const _ParticleData(
        icon: Icons.qr_code,
        size: 14,
        left: 0.78,
        top: 0.88,
        delay: 3,
        duration: 8,
      ),
      const _ParticleData(
        icon: Icons.sell_outlined,
        size: 20,
        left: 0.05,
        top: 0.55,
        delay: 1,
        duration: 5,
      ),
      const _ParticleData(
        icon: Icons.receipt_outlined,
        size: 16,
        left: 0.92,
        top: 0.5,
        delay: 2.5,
        duration: 7.5,
      ),
      const _ParticleData(
        icon: Icons.store_outlined,
        size: 22,
        left: 0.5,
        top: 0.04,
        delay: 0.5,
        duration: 6,
      ),
    ];

    return Stack(
      children: particles.map((p) {
        return _FloatingParticle(
          icon: p.icon,
          size: p.size.toDouble(),
          left: p.left,
          top: p.top,
          delay: p.delay,
          duration: p.duration,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _ParticleData {
  final IconData icon;
  final double size;
  final double left;
  final double top;
  final double delay;
  final double duration;

  const _ParticleData({
    required this.icon,
    required this.size,
    required this.left,
    required this.top,
    required this.delay,
    required this.duration,
  });
}

class _FloatingParticle extends StatefulWidget {
  final IconData icon;
  final double size;
  final double left;
  final double top;
  final double delay;
  final double duration;
  final bool isDark;

  const _FloatingParticle({
    required this.icon,
    required this.size,
    required this.left,
    required this.top,
    required this.delay,
    required this.duration,
    required this.isDark,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _float;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.duration.round()),
    );
    _float = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).round()), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Positioned(
          left: widget.left * MediaQuery.of(context).size.width,
          top: widget.top * MediaQuery.of(context).size.height +
              _float.value * 12,
          child: Opacity(
            opacity: _opacity.value * 0.15,
            child: Transform.rotate(
              angle: _float.value * 0.3,
              child: Icon(
                widget.icon,
                size: widget.size,
                color: widget.isDark ? Colors.white : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
