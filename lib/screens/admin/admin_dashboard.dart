import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'adminprovider.dart';
import 'add_product_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.fetchOrders().then((_) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((e) {
      print('Error in didChangeDependencies: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data: $e';
      });
    });
  }

  void updateOrderStatus(int index, String newStatus) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final orderId = adminProvider.orders[index]['id'].toString();
    adminProvider.updateOrderStatus(orderId, newStatus);
  }

  String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return 'Menunggu';
      case 'confirmed': return 'Dikonfirmasi';
      case 'preparing': return 'Diproses';
      case 'delivering': return 'Dikirim';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default: return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Color(0xFFEC4899);
      case 'delivering': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  int getPendingOrdersCount() {
    return Provider.of<AdminProvider>(context).orders.where((order) => order['status'].toLowerCase() == 'pending').length;
  }

  double getTotalSales() {
    return Provider.of<AdminProvider>(context).orders.fold(0.0, (sum, order) => sum + (order['total'] as num));
  }

Future<void> _logout() async {
  try {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    adminProvider.clearOrders(); // Tambahkan metode ini jika belum ada
    await _supabase.auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal logout: $e')),
    );
  }
}

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final orders = adminProvider.orders;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard Admin')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard Admin')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                  adminProvider.fetchOrders();
                },
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              final adminProvider = Provider.of<AdminProvider>(context, listen: false);
              adminProvider.fetchOrders();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data diperbarui'),
                  backgroundColor: Color(0xFFEC4899),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddProductPage()));
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Color(0xFFFDF2F8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${getPendingOrdersCount()}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                          Text(
                            'Pesanan Baru',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Color(0xFFFDF2F8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Rp ${getTotalSales().toInt()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                          Text(
                            'Total Penjualan',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Pesanan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text('${orders.length} Pesanan'),
                  backgroundColor: Color(0xFFFCE7F3),
                  labelStyle: TextStyle(color: Color(0xFFBE185D)),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final created = order['created'];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pesanan #$index',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: getStatusColor(order['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: getStatusColor(order['status']),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                getStatusText(order['status']),
                                style: TextStyle(
                                  color: getStatusColor(order['status']),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${created.day}/${created.month}/${created.year} ${created.hour}:${created.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: Color(0xFFEC4899)),
                                  SizedBox(width: 8),
                                  Text(
                                    'User ID: ${order['recipient_name'] ?? 'Unknown'}',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Color(0xFFEC4899)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Alamat: ${order['address']}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              if (order['latitude'] != null && order['longitude'] != null) ...[
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.pin_drop, size: 16, color: Color(0xFFEC4899)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lat: ${order['latitude']}, Long: ${order['longitude']}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                              if (order['notes']?.isNotEmpty ?? false) ...[
                                SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.note, size: 16, color: Color(0xFFEC4899)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Catatan: ${order['notes']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Item Pesanan:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text('Item tidak tersedia (perlu relasi ke koleksi items)'),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Rp ${order['total']?.toInt() ?? 0}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (order['status']?.toLowerCase() == 'pending') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'confirmed'),
                                  child: Text('Konfirmasi'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'cancelled'),
                                  child: Text('Batalkan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (order['status']?.toLowerCase() == 'confirmed') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'preparing'),
                                  child: Text('Proses'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFEC4899),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'cancelled'),
                                  child: Text('Batalkan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (order['status']?.toLowerCase() == 'preparing') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'delivering'),
                                  child: Text('Kirim'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'cancelled'),
                                  child: Text('Batalkan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (order['status']?.toLowerCase() == 'delivering') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'completed'),
                                  child: Text('Selesai'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(index, 'cancelled'),
                                  child: Text('Batalkan'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}