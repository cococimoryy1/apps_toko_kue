import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'adminprovider.dart';

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
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'preparing':
        return 'Diproses';
      case 'delivering':
        return 'Dikirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Color(0xFFEC4899);
      case 'delivering':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int getPendingOrdersCount() {
    return Provider.of<AdminProvider>(context).orders.where((order) => order['status'] == 'pending').length;
  }

  double getTotalSales() {
    return Provider.of<AdminProvider>(context).orders.fold(0.0, (sum, order) => sum + (order['total'] as num));
  }

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                // Pengecekan null untuk created
                final created = order['created'] ?? DateTime.now();
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
                              'Pesanan #${order['id']}',
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
                                    order['customer']['name'],
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: Color(0xFFEC4899)),
                                  SizedBox(width: 8),
                                  Text(order['customer']['phone']),
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
                                      order['address'],
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              if (order['customer']['notes'].isNotEmpty) ...[
                                SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.note, size: 16, color: Color(0xFFEC4899)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Catatan: ${order['customer']['notes']}',
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
                              'Rp ${order['total']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFEC4899),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        if (order['status'] == 'pending') ...[
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
                        ] else if (order['status'] == 'confirmed') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => updateOrderStatus(index, 'preparing'),
                              child: Text('Mulai Proses'),
                            ),
                          ),
                        ] else if (order['status'] == 'preparing') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => updateOrderStatus(index, 'delivering'),
                              child: Text('Kirim Pesanan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ] else if (order['status'] == 'delivering') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => updateOrderStatus(index, 'completed'),
                              child: Text('Selesaikan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
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