import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../pocketbase_services.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  ProductDetailPage({required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final PocketBase _pb = PocketBaseService().pb;
  late Future<Map<String, dynamic>> _productFuture;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _productFuture = _fetchProduct();
  }

  Future<Map<String, dynamic>> _fetchProduct() async {
    try {
      final record = await _pb.collection('products').getOne(widget.productId);
      String imageUrl = record.data['image'] != null
          ? 'http://127.0.0.1:8091/api/files/products/${record.id}/${record.data['image']}'
          : '🍞';
      return {
        'id': record.id,
        'name': record.data['name'] ?? 'No Name',
        'category': record.data['category'] ?? 'Unknown',
        'description': record.data['description'] ?? 'No description',
        'price': record.data['price'] ?? 0,
        'stock': record.data['stock'] ?? 0,
        'rating': record.data['rating'] ?? 0.0,
        'image': imageUrl,
        'is_featured': record.data['is_featured'] ?? false,
      };
    } catch (e) {
      print('Error fetching product: $e');
      return {
        'id': widget.productId,
        'name': 'No Name',
        'category': 'Unknown',
        'description': 'No description',
        'price': 0,
        'stock': 0,
        'rating': 0.0,
        'image': '🍞',
        'is_featured': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading product: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No data found'));
          }

          final product = snapshot.data!;

          return Scaffold(
            appBar: AppBar(
              title: Text('Detail Produk'),
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ditambahkan ke wishlist'),
                        backgroundColor: Color(0xFFEC4899),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: product['image'].startsWith('http')
                          ? Image.network(
                              product['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text('🍞', style: TextStyle(fontSize: 120));
                              },
                            )
                          : Text(
                              product['image'],
                              style: TextStyle(fontSize: 120),
                            ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                product['name'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFFFCE7F3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                product['category'].toString(),
                                style: TextStyle(
                                  color: Color(0xFFBE185D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 4),
                            Text(
                              '${product['rating'].toStringAsFixed(1)}',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Stok tersedia: ${product['stock']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          product['description'],
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Harga',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Rp ${product['price'].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEC4899),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Jumlah',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xFFF9A8D4)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: quantity > 1
                                        ? () {
                                            setState(() {
                                              quantity--;
                                            });
                                          }
                                        : null,
                                    icon: Icon(Icons.remove),
                                    color: Color(0xFFEC4899),
                                  ),
                                  Container(
                                    width: 50,
                                    child: Text(
                                      '$quantity',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: quantity < product['stock']
                                        ? () {
                                            setState(() {
                                              quantity++;
                                            });
                                          }
                                        : null,
                                    icon: Icon(Icons.add),
                                    color: Color(0xFFEC4899),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Maksimal ${product['stock']} item',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFFDF2F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFFF9A8D4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Harga:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Rp ${product['price'] * quantity}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEC4899),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: product['stock'] > 0
                          ? () async {
                              final cartProvider = Provider.of<CartProvider>(context, listen: false);
                              await cartProvider.addToCartWithDB(product, quantity); // Gunakan metode ini
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$quantity ${product['name']} ditambahkan ke keranjang!'),
                                  backgroundColor: Color(0xFFEC4899),
                                  action: SnackBarAction(
                                    label: 'Lihat Keranjang',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/cart');
                                    },
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: Icon(Icons.shopping_cart),
                      label: Text(
                        product['stock'] > 0 ? 'Tambah ke Keranjang' : 'Stok Habis',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: product['stock'] > 0 ? Color(0xFFEC4899) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}