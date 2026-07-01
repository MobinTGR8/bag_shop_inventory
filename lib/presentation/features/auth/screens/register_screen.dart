import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  late final FormGroup form;

  @override
  void initState() {
    super.initState();
    form = FormGroup({
      'shopName': FormControl<String>(validators: [Validators.required]),
      'name': FormControl<String>(validators: [Validators.required]),
      'phone': FormControl<String>(validators: [Validators.required]),
      'email': FormControl<String>(
        validators: [Validators.required],
      ),
      'password': FormControl<String>(
        validators: [Validators.required, Validators.minLength(6)],
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brand = Theme.of(context).extension<AppBrandColors>();

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.user == null && next.user != null) {
        context.go('/');
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: brand?.heroGradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.secondary],
                  ),
            ),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with back button
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 1),
                        builder: (context, t, child) {
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, (1 - t) * 10),
                              child: child,
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => context.go('/login'),
                                icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
                                tooltip: 'Back',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Create account',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form Card
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 50,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: ReactiveForm(
                              formGroup: form,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Set up your account',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Create your shop to get started',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurface.withOpacity(0.6),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  ReactiveTextField<String>(
                                    formControlName: 'shopName',
                                    validationMessages: {
                                      ValidationMessage.required: (_) =>
                                          'Shop name is required',
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Shop name',
                                      hintText: 'e.g. Bag Paradise',
                                      prefixIcon: Icon(Icons.store_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  ReactiveTextField<String>(
                                    formControlName: 'name',
                                    decoration: const InputDecoration(
                                      labelText: 'Full name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  ReactiveTextField<String>(
                                    formControlName: 'phone',
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                      prefixIcon: Icon(Icons.phone_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  ReactiveTextField<String>(
                                    formControlName: 'email',
                                    keyboardType: TextInputType.emailAddress,
                                    validationMessages: {
                                      ValidationMessage.required: (_) =>
                                          'Email is required',
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  ReactiveTextField<String>(
                                    formControlName: 'password',
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Password (min 6 chars)',
                                      prefixIcon: Icon(Icons.lock_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  if (authState.error != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.errorContainer,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: scheme.error, size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              authState.error!,
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: scheme.onErrorContainer,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  SizedBox(
                                    height: 54,
                                    child: FilledButton(
                                      onPressed: authState.isLoading
                                          ? null
                                          : () async {
                                              form.control('shopName').updateValueAndValidity();
                                              form.markAllAsTouched();
                                              if (!form.valid) return;

                                              final name = (form.control('name').value as String).trim();
                                              final phone = (form.control('phone').value as String).trim();
                                              final email = (form.control('email').value as String).trim();
                                              final password = form.control('password').value as String;
                                              final shopName = (form.control('shopName').value as String).trim();

                                              await ref.read(authProvider.notifier).registerAdmin(
                                                email: email,
                                                password: password,
                                                shopName: shopName,
                                                phone: phone,
                                                name: name,
                                              );
                                            },
                                      style: FilledButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: authState.isLoading
                                          ? const SizedBox(
                                              width: 24, height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                                SizedBox(width: 8),
                                                Icon(Icons.arrow_forward, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () => context.go('/login'),
                                    child: const Text('Already have an account? Sign in'),
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
        ],
      ),
    );
  }
}
