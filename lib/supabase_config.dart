import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://eoltmoazpgypwbygtvcm.supabase.co', // Perbaiki typo dan sesuai dengan project-ref
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvbHRtb2F6cGd5cHdieWd0dmNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3ODYzNTIsImV4cCI6MjA2NTM2MjM1Mn0.eUSPqkyEeDurJKn-7ICUDeiDgPGNcWcIKKyFlpnNxHY', // Anon Key dari dashboard
    debug: true, // Aktifkan debug untuk melihat log di konsol
  );
}