import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:mime/mime.dart'; // Tambahkan package ini

class ProductProvider with ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;

  Future<void> fetchProducts() async {
    print('Mengambil produk dari ${_supabase.rest.url}');
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Tidak ada autentikasi, mencoba login dengan kredensial default');
        await _supabase.auth.signInWithPassword(email: 'admin@gmail.com', password: '12345678');
      }

      final response = await _supabase
          .from('products')
          .select('id, name, description, price, stock, category, is_featured, created, updated, image')
          .order('created', ascending: false);

_products = response.map((record) {
  print('Record yang diambil: $record'); // Log setiap record
  return {
    'id': record['id'] as String,
    'name': record['name'] as String? ?? '',
    'description': record['description'] as String? ?? '',
    'price': (record['price'] as num?)?.toDouble() ?? 0.0,
    'stock': (record['stock'] as num?)?.toInt() ?? 0,
    'category': record['category'] as String? ?? '',
    'image': record['image'] as String? ?? '',
    'is_featured': record['is_featured'] as bool? ?? false,
    'created': DateTime.parse(record['created'].toString()),
    'updated': DateTime.parse(record['updated'].toString()),
  };
}).toList();
print('Produk yang dimuat: $_products'); // Log seluruh daftar produk
    } catch (e) {
      print('Error mengambil produk: $e');
      throw e;
    }
  }

  Future<void> fetchCategories() async {
    print('Mengambil kategori dari ${_supabase.rest.url}');
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Tidak ada autentikasi, mencoba login dengan kredensial default');
        await _supabase.auth.signInWithPassword(email: 'admin@gmail.com', password: '12345678');
      }

      final response = await _supabase
          .from('categories')
          .select('id, name')
          .order('name', ascending: true);

      _categories = response.map((record) {
        return {
          'id': record['id'] as String,
          'name': record['name'] as String? ?? '',
        };
      }).toList();

      notifyListeners();
      print('Berhasil mengambil ${_categories.length} kategori');
    } catch (e) {
      print('Error mengambil kategori: $e');
      throw e;
    }
  }

Future<void> addProduct(Map<String, dynamic> product, {List<File> images = const []}) async {
  print('Menambahkan produk ke ${_supabase.rest.url}');
  try {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('Tidak ada autentikasi, mencoba login dengan kredensial default');
      await _supabase.auth.signInWithPassword(email: 'admin@gmail.com', password: '12345678');
    }

    String? imageUrl;
    if (images.isNotEmpty) {
      final file = images[0];
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      try {
        await _supabase.storage.from('product_images').uploadBinary(
          fileName,
          await file.readAsBytes(),
          fileOptions: FileOptions(contentType: mimeType),
        );
        imageUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);
        print('Gambar berhasil diunggah dari Supabase: $imageUrl');
      } catch (e) {
        print('Error mengunggah gambar: $e');
        throw Exception('Gagal mengunggah gambar: $e');
      }
    }

    final body = {
      'name': product['name'],
      'description': product['description'],
      'price': product['price'],
      'stock': product['stock'],
      'category': product['category'],
      'is_featured': product['is_featured'],
      'image': imageUrl,
      'created': DateTime.now().toIso8601String(),
      'updated': DateTime.now().toIso8601String(),
    };

    final response = await _supabase.from('products').insert(body).select();
    if (response.isNotEmpty) {
      print('Produk berhasil dibuat dengan ID: ${response[0]['id']}');
    }

    await fetchProducts();
  } catch (e) {
    print('Error menambahkan produk: $e');
    throw e;
  }
}

  Future<void> updateProduct(String productId, Map<String, dynamic> product, {List<File> images = const []}) async {
    print('Memperbarui produk $productId');
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _supabase.auth.signInWithPassword(email: 'admin@gmail.com', password: '12345678');
      }

      String? imageUrl = product['image'];
      if (images.isNotEmpty) {
        final file = images[0];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        try {
          await _supabase.storage.from('product_images').uploadBinary(
            fileName,
            await file.readAsBytes(),
            fileOptions: FileOptions(contentType: mimeType),
          );
          imageUrl = _supabase.storage.from('product_images').getPublicUrl(fileName);
          print('Gambar berhasil diunggah: $imageUrl');
        } catch (e) {
          print('Error mengunggah gambar: $e');
          throw Exception('Gagal mengunggah gambar: $e');
        }
      }

      final body = {
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'stock': product['stock'],
        'category': product['category'],
        'is_featured': product['is_featured'],
        'image': imageUrl,
        'updated': DateTime.now().toIso8601String(),
      };

      await _supabase.from('products').update(body).eq('id', productId).select();
      print('Produk berhasil diperbarui');

      await fetchProducts();
    } catch (e) {
      print('Error memperbarui produk: $e');
      throw e;
    }
  }

  Future<void> deleteProduct(String productId) async {
    print('Menghapus produk $productId');
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        await _supabase.auth.signInWithPassword(email: 'admin@gmail.com', password: '12345678');
      }

      await _supabase.from('products').delete().eq('id', productId);
      print('Produk berhasil dihapus');

      await fetchProducts();
    } catch (e) {
      print('Error menghapus produk: $e');
      throw e;
    }
  }

  String getImageUrl(Map<String, dynamic> product) {
    if (product['image'] == null || product['image'].isEmpty) {
      return '';
    }
    return product['image'] as String;
  }
}