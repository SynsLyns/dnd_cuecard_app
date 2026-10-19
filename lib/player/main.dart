import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/player_app.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initializationError;
  if (_supabaseUrl.trim().isEmpty || _supabaseAnonKey.trim().isEmpty) {
    initializationError =
        'Player sharing is not configured. Build with SUPABASE_URL and '
        'SUPABASE_ANON_KEY.';
  } else {
    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabaseAnonKey,
      );
    } catch (error) {
      initializationError = 'Could not connect to the sharing service: $error';
    }
  }

  runApp(PlayerApp(initializationError: initializationError));
}
