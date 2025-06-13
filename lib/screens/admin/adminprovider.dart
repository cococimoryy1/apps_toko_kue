import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../pocketbase_services.dart';

class AdminProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  final PocketBase _pb = PocketBaseService().pb;

  List<Map<String, dynamic>> get orders => _orders;

  Future<void> fetchOrders() async {
    print('Fetching orders from ${_pb.baseUrl}');
    try {
      // Pastikan autentikasi jika diperlukan
      if (!PocketBaseService().isAuthenticated()) {
        print('Not authenticated, attempting to authenticate with default credentials');
        await PocketBaseService().authWithPassword('admin@example.com', 'password123'); // Ganti dengan kredensial yang benar
      }

      final records = await _pb.collection('orders').getFullList(sort: '-created');
      print('Records fetched: ${records.length} records');
      _orders = records.map((record) {
        print('Processing record: ${record.data}');
        return {
          'id': record.id,
          'customer': {
            'name': record.data['user']?.toString() ?? 'Unknown',
            'phone': record.data['phone'] ?? '',
            'notes': record.data['notes'] ?? '',
          },
          'location': {
            'latitude': record.data['latitude'] ?? -6.1745,
            'longitude': record.data['longitude'] ?? 106.8227,
          },
          'address': record.data['adresss'] ?? 'N/A',
          'total': (record.data['total'] as num?)?.toDouble() ?? 0.0,
          'status': record.data['status'] ?? 'pending',
          'created': DateTime.parse(record.data['created'] ?? DateTime.now().toIso8601String()),
          'updated': DateTime.parse(record.data['updated'] ?? DateTime.now().toIso8601String()),
        };
      }).toList();
      print('Orders after mapping: $_orders');
      if (_orders.isEmpty) {
        print('Warning: No orders found after mapping');
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
      throw e;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _pb.collection('orders').update(orderId, body: {'status': newStatus});
      await fetchOrders();
    } catch (e) {
      print('Error updating status: $e');
      throw e;
    }
  }
}