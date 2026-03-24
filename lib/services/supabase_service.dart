import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {

  static Future init() async {
    await Supabase.initialize(
      url: "https://ohxavvrycomipescjbau.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9oeGF2dnJ5Y29taXBlc2NqYmF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4Mjc4MjUsImV4cCI6MjA4OTQwMzgyNX0.TJr7HkqQwWAjYhHOORB0a-6hpAvhgvKlj8swqHhVsYs",
    );
  }

  static SupabaseClient client = Supabase.instance.client;
}