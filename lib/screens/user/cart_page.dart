import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'payment_page.dart';
import '../admin/admin_dashboard.dart';

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.fetchCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Keranjang Belanja'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cartProvider.cartItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Hapus Semua'),
                      content: Text('Apakah Anda yakin ingin menghapus semua item dari keranjang?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () {
                            cartProvider.clearCart();
                            Navigator.pop(context);
                          },
                          child: Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          // IconButton(
          //   icon: Icon(Icons.admin_panel_settings),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => AdminDashboard()),
          //     );
          //   },
          // ),
        ],
      ),
      body: cartProvider.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🛒', style: TextStyle(fontSize: 80)),
                  SizedBox(height: 16),
                  Text(
                    'Keranjang Kosong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada produk di keranjang Anda',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/products');
                    },
                    child: Text('Mulai Belanja'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.cartItems[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFDF2F8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: item['image'].startsWith('http')
                                      ? Image.network(
                                          item['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Text('🍞', style: TextStyle(fontSize: 30));
                                          },
                                        )
                                      : Text(
                                          item['image'],
                                          style: TextStyle(fontSize: 30),
                                        ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Rp ${item['price'].toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Color(0xFFEC4899),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Color(0xFFF9A8D4)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () {
                                                  cartProvider.updateQuantity(index, item['quantity'] - 1);
                                                },
                                                icon: Icon(Icons.remove, size: 16),
                                                color: Color(0xFFEC4899),
                                              ),
                                            ),
                                            Container(
                                              width: 40,
                                              child: Text(
                                                '${item['quantity']}',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Color(0xFFF9A8D4)),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () {
                                                  cartProvider.updateQuantity(index, item['quantity'] + 1);
                                                },
                                                icon: Icon(Icons.add, size: 16),
                                                color: Color(0xFFEC4899),
                                              ),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            cartProvider.removeItem(index);
                                          },
                                          icon: Icon(Icons.delete_outline),
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Item:', style: TextStyle(fontSize: 16)),
                                Text('${cartProvider.getTotalItems()} item', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 8),
                            ...cartProvider.cartItems.map((item) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['name']} x${item['quantity']}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    'Rp ${item['price'] * item['quantity']}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )).toList(),
                            Divider(color: Color(0xFFF9A8D4)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Harga:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Rp ${cartProvider.getTotalPrice().toInt()}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEC4899),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentPage(cartItems: cartProvider.cartItems, totalPrice: cartProvider.getTotalPrice()),
                              ),
                            );
                          },
                          child: Text(
                            'Lanjut ke Pembayaran',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}