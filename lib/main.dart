import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? bootError;

  try {
    // Load .env from assets
    try {
      await dotenv.load(fileName: 'env.json');
    } catch (e) {
      debugPrint('dotenv: .env not loaded ($e). Falling back to --dart-define.');
    }

    final supabaseUrl =
        dotenv.env['SUPABASE_URL'] ??
        const String.fromEnvironment('SUPABASE_URL');

    final supabaseAnonKey =
        dotenv.env['SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment('SUPABASE_ANON_KEY');

    if (supabaseUrl.isEmpty) {
      throw Exception(
        'Missing SUPABASE_URL. Add it to .env or pass via --dart-define.',
      );
    }

    if (supabaseAnonKey.isEmpty) {
      throw Exception(
        'Missing SUPABASE_ANON_KEY. Add it to .env or pass via --dart-define.',
      );
    }

    debugPrint('Supabase: initializing with URL=$supabaseUrl');

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode,
    );

    debugPrint('Supabase: initialized successfully');
  } catch (e) {
    bootError = e;
    debugPrint('Supabase: initialization failed: $e');
  }

  runApp(
    ProviderScope(
      child: bootError == null
          ? const BagShopInventoryApp()
          : BootstrapErrorApp(error: bootError),
    ),
  );
}

class BootstrapErrorApp extends StatelessWidget {
  final Object error;

  const BootstrapErrorApp({
    super.key,
    required this.error,
  });

  String get _userHint {
    final msg = error.toString().toLowerCase();

    if (msg.contains('.env') ||
        msg.contains('supabase_url') ||
        msg.contains('supabase_anon_key')) {
      return 'Your .env file is missing or incomplete. Copy .env.example to .env and fill in your Supabase project URL and anon key from Settings → API in the Supabase dashboard.';
    }

    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('failed host lookup')) {
      return 'Could not connect to Supabase. Check your internet connection and verify the SUPABASE_URL is correct.';
    }

    if (msg.contains('cors') ||
        (msg.contains('http error') && kIsWeb)) {
      return 'CORS error on web. Add your app URL (e.g. http://localhost:3000) to Supabase → Settings → API → CORS Origins.';
    }

    return 'See details below. Check your Supabase project settings and .env file.';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Configuration Error'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                _userHint,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error details:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    error.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}