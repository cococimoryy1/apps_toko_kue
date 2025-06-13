import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> get orders => _orders;
  void clearOrders() {
  _orders = [];
  notifyListeners();
}
  Future<void> fetchOrders() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Tidak ada sesi autentikasi, silakan login ulang');
      }

      // Ambil data dari tabel orders dengan join ke auth.users untuk detail user
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            "recipient_name",
            address,
            latitude,
            longitude,
            total,
            status,
            notes,
            timestamp,
            created,
            updated
          ''')
          .order('created', ascending: false);

      _orders = response.map((record) {
        return {
          'id': record['id'] as String,
          'recipient_name': record['recipient_name'] as String? ?? 'Unknown', // Menggunakan recipient_name
          'address': record['adresss'] as String? ?? 'N/A', // Perbaiki typo
          'latitude': (record['latitude'] as num?)?.toDouble() ?? 0.0,
          'longitude': (record['longitude'] as num?)?.toDouble() ?? 0.0,
          'total': (record['total'] as num?)?.toDouble() ?? 0.0,
          'status': record['status'] as String? ?? 'pending',
          'notes': record['notes'] as String? ?? '',
          'timestamp': record['timpestamp'] != null ? DateTime.parse(record['timpestamp'].toString()) : null, // Perbaiki typo
          'created': DateTime.parse(record['created'].toString()),
          'updated': DateTime.parse(record['updated'].toString()),
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
      throw e;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Pastikan status sesuai dengan constraint
      final validStatuses = ['pending', 'confirmed', 'preparing', 'delivering', 'completed', 'cancelled'];
      if (!validStatuses.contains(newStatus.toLowerCase())) {
        throw Exception('Status tidak valid: $newStatus');
      }

      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      await fetchOrders();
    } catch (e) {
      print('Error updating status: $e');
      throw e;
    }
  }
}