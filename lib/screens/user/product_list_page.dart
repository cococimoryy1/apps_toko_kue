import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'product_detail_page.dart';
import '../auth/login_page.dart';
import '../../pocketbase_services.dart';

class ProductListPage extends StatefulWidget {
  final String? categoryId; // Parameter opsional untuk filter kategori

  const ProductListPage({this.categoryId});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final PocketBase _pb = PocketBaseService().pb; // Gunakan singleton dari PocketBaseService
  late Future<List<Map<String, dynamic>>> _productsFuture = Future.value([]);
  String selectedCategory = 'Semua';
  String searchQuery = '';

  // Gunakan String? untuk mengizinkan null
  final Map<String, String?> categoryMap = {
    'Semua': null, // null menunjukkan semua kategori
    '5kh2n433m0uzy7c': 'Roti',
    '56j0fam3444x1s4': 'Kue',
    'ax3633h8z3ntft2': 'Pastry',
    '0741jtcj1zzs9oj': 'Donat',
  };

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  Future<void> _checkAuthAndFetchData() async {
    if (!_pb.authStore.isValid) {
      print('Sesi tidak valid di ProductListPage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesi tidak valid, silakan login kembali')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
      return;
    }
    setState(() {
      _productsFuture = _fetchProducts();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      String? filter;
      if (widget.categoryId != null) {
        filter = 'category = "${widget.categoryId}"';
      } else if (selectedCategory != 'Semua') {
        final categoryId = categoryMap.entries.firstWhere(
          (entry) => entry.value == selectedCategory,
          orElse: () => MapEntry('', null),
        )?.key;
        if (categoryId != null && categoryId.isNotEmpty) {
          filter = 'category = "$categoryId"';
        }
      }
      final records = await _pb.collection('products').getFullList(
        filter: filter,
      );
      print('Raw records from products with filter $filter: $records');
      if (records.isEmpty) {
        print('No records found in products collection with filter $filter');
      }
      return records.map((record) {
        print('Processing record: ${record.data}');
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
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Produk'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFFEC4899)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Color(0xFFF9A8D4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide(color: Color(0xFFEC4899)),
                  ),
                  filled: true,
                  fillColor: Color(0xFFFDF2F8),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: categoryMap.values.length,
                itemBuilder: (context, index) {
                  final categoryName = categoryMap.values.elementAt(index) ?? 'Semua'; // Handle null
                  final isSelected = selectedCategory == categoryName;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(categoryName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategory = categoryName;
                          _productsFuture = _fetchProducts(); // Perbarui data saat kategori berubah
                        });
                      },
                      selectedColor: Color(0xFFF9A8D4),
                      checkmarkColor: Color(0xFFEC4899),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Color(0xFFBE185D) : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading products: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔍', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada produk ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final products = snapshot.data!;
                final filteredProducts = products.where((product) {
                  final matchesCategory = selectedCategory == 'Semua' ||
                      (widget.categoryId != null
                          ? product['category'] == widget.categoryId
                          : categoryMap.entries.any((entry) => entry.value == selectedCategory && entry.key == product['category']));
                  final matchesSearch = product['name'].toLowerCase().contains(searchQuery.toLowerCase());
                  print('Product: ${product['name']}, Category: ${product['category']}, Matches Category: $matchesCategory, Matches Search: $matchesSearch');
                  return matchesCategory && matchesSearch;
                }).toList();

                return filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🔍', style: TextStyle(fontSize: 64)),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada produk ditemukan',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(productId: product['id']),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFDF2F8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: product['image'].startsWith('http')
                                            ? Image.network(
                                                product['image'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Text('🍞', style: TextStyle(fontSize: 40));
                                                },
                                              )
                                            : Text(
                                                '🍞',
                                                style: TextStyle(fontSize: 40),
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
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
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFFCE7F3),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  categoryMap[product['category']] ?? product['category'].toString(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFFBE185D),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            product['description'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Rp ${product['price'].toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: Color(0xFFEC4899),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '${product['rating'].toStringAsFixed(1)}',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Stok: ${product['stock']}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}