import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exceptions.dart';

class ErrorHandler {
  static String handle(Object e) {
    if (e is AppException) return e.message;

    if (e is AuthException) {
      return e.message;
    }

    final raw = e.toString();
    final lower = raw.toLowerCase();

    if (e is SocketException ||
        e is TimeoutException ||
        lower.contains('socketexception') ||
        lower.contains('timeoutexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused')) {
      return 'Network error. Check your connection and try again.';
    }

    if (lower.contains('supabase_url') ||
        lower.contains('supabase_anon_key') ||
        lower.contains('configuration')) {
      return 'App configuration is incomplete. Check Supabase settings and restart.';
    }

    if (lower.contains('row-level security') ||
        lower.contains('permission denied') ||
        lower.contains('not authorized')) {
      return 'You do not have permission to perform this action.';
    }

    if (lower.contains('not found')) {
      return 'The requested item could not be found.';
    }

    if (lower.contains('required') ||
        lower.contains('invalid') ||
        lower.contains('validation')) {
      return 'Please check the form and try again.';
    }

    return 'An unexpected error occurred';
  }
}
