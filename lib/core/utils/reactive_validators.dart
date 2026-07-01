import 'package:reactive_forms/reactive_forms.dart';

class ReactiveValidators {
  /// A deliberately simple email validator:
  /// - trims whitespace
  /// - requires one '@'
  /// - requires at least one '.' after '@'
  ///
  /// This is meant to be user-friendly (avoid rejecting valid real-world
  /// addresses due to overly strict rules). Supabase will still validate on
  /// sign-in/up if needed.
  static Map<String, dynamic>? simpleEmail(AbstractControl<dynamic> control) {
    final raw = control.value;
    final value = (raw is String ? raw : raw?.toString())?.trim() ?? '';

    if (value.isEmpty) {
      return <String, dynamic>{ValidationMessage.required: true};
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return <String, dynamic>{ValidationMessage.email: true};
    }

    return null;
  }
}
