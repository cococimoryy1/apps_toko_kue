import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  static PocketBase _pb = PocketBase('http://127.0.0.1:8091'); // Ganti dengan URL server Anda

  factory PocketBaseService() {
    return _instance;
  }

  PocketBaseService._internal();

  // Getter untuk mengakses instance PocketBase
  PocketBase get pb => _pb;

  // Metode untuk autentikasi dengan email dan password
  Future<void> authWithPassword(String email, String password) async {
    try {
      await _pb.collection('users').authWithPassword(email, password);
      print('Authentication successful: ${_pb.authStore.isValid}');
    } catch (e) {
      print('Authentication error: $e');
      throw Exception('Failed to authenticate: $e');
    }
  }

  // Metode untuk logout
  Future<void> logout() async {
    try {
      _pb.authStore.clear();
      print('Logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      throw Exception('Failed to logout: $e');
    }
  }

  // Metode untuk memeriksa status autentikasi
  bool isAuthenticated() {
    return _pb.authStore.isValid;
  }

  // Metode untuk menyegarkan token autentikasi (jika diperlukan)
  Future<void> refreshAuth() async {
    try {
      await _pb.collection('users').authRefresh();
      print('Auth refreshed successfully');
    } catch (e) {
      print('Auth refresh error: $e');
      throw Exception('Failed to refresh auth: $e');
    }
  }
}