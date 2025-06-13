import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_detail_page.dart';
import '../auth/login_page.dart';

class ProductListPage extends StatefulWidget {
  final String? categoryId; // Parameter opsional untuk filter kategori

  const ProductListPage({this.categoryId});

  @override
  _ProductListPageState createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _productsFuture = Future.value([]);
  List<Map<String, dynamic>> _categoryList = [];
  Map<String, String> _categoryIdToName = {};
  Map<String, String?> _categoryNameToId = {}; // Changed to String? for nullable IDs
  String selectedCategory = 'Semua';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
  }

  Future<void> _checkAuthAndLoadData() async {
    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null || user.email!.isEmpty) {
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

    // Ambil kategori
    _categoryList = await _fetchCategories();
    _categoryIdToName = {
      for (var cat in _categoryList)
        if (cat['id'] != null) cat['id'] as String: cat['name'] as String
    };
    _categoryNameToId = {
      for (var cat in _categoryList) cat['name'] as String: cat['id'] as String?
    };

    setState(() {
      selectedCategory = 'Semua';
      _productsFuture = _fetchProducts();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      final response = await _supabase.from('categories').select('id, name');
      return [
        {'id': null, 'name': 'Semua'}, // Tambahkan opsi "Semua" secara manual
        ...response.map((cat) {
          return {
            'id': cat['id'] as String,
            'name': cat['name'] as String,
          };
        }).toList()
      ];
    } catch (e) {
      print('Error fetching categories: $e');
      return [{'id': null, 'name': 'Semua'}]; // Fallback dengan opsi "Semua"
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final query = _supabase.from('products').select('id, name, category, description, price, stock, rating, image, is_featured');
      if (selectedCategory != 'Semua') {
        final categoryId = _categoryNameToId[selectedCategory];
        if (categoryId != null) {
          query.eq('category', categoryId);
          print('Applied filter: category = $categoryId');
        }
      } else {
        print('No category filter applied (Semua)');
      }
      final response = await query.order('created', ascending: false);
      print('Raw response from products: $response');
      if (response.isEmpty) {
        print('No records found with category ${selectedCategory != 'Semua' ? _categoryNameToId[selectedCategory] : 'Semua'}');
      }
      return response.map((record) {
        print('Processing record: $record');
        String imageUrl = record['image'] != null
            ? _supabase.storage.from('product_images').getPublicUrl(record['image'])
            : '🍞';
        return {
          'id': record['id'] as String,
          'name': record['name'] as String? ?? 'No Name',
          'category': record['category'] as String? ?? 'Unknown',
          'description': record['description'] as String? ?? 'No description',
          'price': (record['price'] as num?)?.toDouble() ?? 0,
          'stock': (record['stock'] as num?)?.toInt() ?? 0,
          'rating': (record['rating'] as num?)?.toDouble() ?? 0.0,
          'image': imageUrl,
          'is_featured': record['is_featured'] as bool? ?? false,
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
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: Text('Semua'),
                    selected: selectedCategory == 'Semua',
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = 'Semua';
                        _productsFuture = _fetchProducts();
                      });
                    },
                    selectedColor: Color(0xFFF9A8D4),
                    checkmarkColor: Color(0xFFEC4899),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: selectedCategory == 'Semua' ? Color(0xFFBE185D) : Colors.grey[600],
                      fontWeight: selectedCategory == 'Semua' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  ..._categoryList.where((cat) => cat['name'] != 'Semua').map((cat) {
                    final isSelected = selectedCategory == cat['name'];
                    return Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(cat['name']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = cat['name'];
                            _productsFuture = _fetchProducts();
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
                  }).toList(),
                ],
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
                      product['category'] == _categoryNameToId[selectedCategory];
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
                                                  _categoryIdToName[product['category']] ?? 'Unknown',
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