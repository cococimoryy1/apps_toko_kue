import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://eoltmoazpgpywbygtvm.supabase.co', // Sesuaikan dengan Project URL Anda
    anonKey: 'your-anon-key', // Ganti dengan Anon Key yang Anda salin
    debug: true, // Aktifkan debug untuk log di konsol (opsional)
  );
}