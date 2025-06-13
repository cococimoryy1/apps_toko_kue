import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'product_list_page.dart';
import 'cart_page.dart';
import '../profil/profil_page.dart';
import '../auth/login_page.dart';
import '../../pocketbase_services.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PocketBase _pb = PocketBaseService().pb;
  late Future<List<Map<String, dynamic>>> _categoriesFuture = Future.value([]);
  late Future<List<Map<String, dynamic>>> _featuredProductsFuture = Future.value([]);
  int _currentIndex = 0;
  int cartItemCount = 3;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchData();
  }

  Future<void> _checkAuthAndFetchData() async {
    if (!_pb.authStore.isValid) {
      print('Sesi tidak valid di HomePage');
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
    _authenticateAndFetchData();
  }

  Future<void> _authenticateAndFetchData() async {
    setState(() {
      _categoriesFuture = _fetchCategories();
      _featuredProductsFuture = _fetchFeaturedProducts();
    });
  }

  Future<void> _logout() async {
    try {
      _pb.authStore.clear(); // clear() adalah metode sinkron
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berhasil logout')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      final records = await _pb.collection('categories').getFullList();
      print('Raw categories data: $records');
      if (records.isEmpty) {
        print('No categories found');
        return [];
      }
      return records.map((record) {
        String icon = '🍞';
        switch (record.data['name']?.toString().toLowerCase()) {
          case 'kue':
            icon = '🎂';
            break;
          case 'pastry':
            icon = '🥐';
            break;
          case 'donat':
            icon = '🍩';
            break;
          case 'roti':
            icon = '🍞';
            break;
        }
        print('Processing category: ${record.data}');
        return {
          'id': record.id,
          'name': record.data['name'] ?? 'No Name',
          'icon': icon,
          'color': Color(0xFFF9A8D4),
        };
      }).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFeaturedProducts() async {
    try {
      final records = await _pb.collection('products').getFullList(
        filter: 'is_featured = true',
      );
      print('Raw featured products data: $records');
      if (records.isEmpty) {
        print('No featured products found, check if is_featured is true');
      }
      return records.map((record) {
        print('Processing featured product data: ${record.data}');
        return {
          'id': record.id,
          'name': record.data['name'] ?? 'No Name',
          'price': record.data['price'] ?? 0,
          'image': record.data['image'] ?? '',
          'rating': record.data['rating'] ?? 0.0,
          'category': record.data['category'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      print('Error fetching featured products: $e');
      return [];
    }
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('0x', ''), radix: 16));
    } catch (e) {
      return Color(0xFFFCE7F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              '🍞 Toko Roti',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC4899),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, color: Color(0xFFEC4899)),
            onPressed: () {
              final user = _pb.authStore.model;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      name: user.data['name'] ?? 'Unknown',
                      email: user.data['email'] ?? 'No email',
                      phone: user.data['phone'] ?? 'No phone',
                      role: user.data['role'] ?? 'No role',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Silakan login terlebih dahulu')),
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFFEC4899)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPage()),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(0xFFEC4899),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFFEC4899)),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: FutureBuilder<List<dynamic>>(
            future: Future.wait([_categoriesFuture, _featuredProductsFuture]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading data: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data![0].isEmpty) {
                return Center(child: Text('No data found'));
              }

              final categories = snapshot.data![0] as List<Map<String, dynamic>>;
              final featuredProducts = snapshot.data![1] as List<Map<String, dynamic>>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toko Roti Bahagia',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Roti dan kue segar setiap hari 🌟',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProductListPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFFEC4899),
                          ),
                          child: Text('Lihat Produk'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Kategori Produk',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProductListPage(categoryId: category['id'])),
                          );
                        },
                        child: Card(
                          color: category['color'],
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  category['icon'],
                                  style: TextStyle(fontSize: 40),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  category['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xFFBE185D),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Produk Unggulan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredProducts.length,
                      itemBuilder: (context, index) {
                        final product = featuredProducts[index];
                        return Container(
                          width: 160,
                          margin: EdgeInsets.only(right: 12),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(
                                    child: product['image'].isNotEmpty && (product['image'] as String).startsWith('http')
                                        ? Image.network(
                                            product['image'],
                                            height: 60,
                                            width: 60,
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
                                  SizedBox(height: 8),
                                  Text(
                                    product['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Rp ${product['price'].toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: Color(0xFFEC4899),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.amber, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        '${product['rating'].toStringAsFixed(1)}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFEC4899),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Color(0xFFEC4899),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$cartItemCount',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Keranjang',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductListPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
              break;
          }
        },
      ),
    );
  }
}