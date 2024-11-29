// core/config/supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';



class SupabaseConfig {
  static final String url = 'https://iuwqyyoriitqlkcuhiba.supabase.co'; // Replace with your Supabase project URL
  static final String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml1d3F5eW9yaWl0cWxrY3VoaWJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE2NzkyMDUsImV4cCI6MjA0NzI1NTIwNX0.uLGKDuTLLpK4oN9NSWupheL-Z0eBExe91nwz54jL_CA'; // Replace with your Supabase anon key

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}


