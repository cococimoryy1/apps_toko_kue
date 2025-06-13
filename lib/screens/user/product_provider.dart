import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:dio/dio.dart';
import '../../pocketbase_services.dart';

class ProductProvider with ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  final PocketBase _pb = PocketBaseService().pb;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get categories => _categories;

  Future<void> fetchProducts() async {
    print('Fetching products from ${_pb.baseUrl}');
    try {
      if (!PocketBaseService().isAuthenticated()) {
        print('Not authenticated, attempting to authenticate with default credentials');
        await PocketBaseService().authWithPassword('admin@gmail.com', '12345678');
      }
      
      final records = await _pb.collection('products').getFullList();
      _products = records.map((record) => {
        'id': record.id,
        'name': record.data['name'] ?? '',
        'description': record.data['description'] ?? '',
        'price': (record.data['price'] as num?)?.toDouble() ?? 0.0,
        'stock': record.data['stock'] as int? ?? 0,
        'category': record.data['category'] ?? '',
        'image': record.data['image'] ?? '',
        'is_featured': record.data['is_featured'] ?? false,
      }).toList();
      
      notifyListeners();
      print('Successfully fetched ${_products.length} products');
    } catch (e) {
      print('Error fetching products: $e');
      throw e;
    }
  }

  Future<void> fetchCategories() async {
    print('Fetching categories from ${_pb.baseUrl}');
    try {
      if (!PocketBaseService().isAuthenticated()) {
        print('Not authenticated, attempting to authenticate with default credentials');
        await PocketBaseService().authWithPassword('admin@gmail.com', '12345678');
      }
      
      final records = await _pb.collection('categories').getFullList();
      _categories = records.map((record) => {
        'id': record.id,
        'name': record.data['name'] ?? '',
      }).toList();
      
      notifyListeners();
      print('Successfully fetched ${_categories.length} categories');
    } catch (e) {
      print('Error fetching categories: $e');
      throw e;
    }
  }

  Future<void> addProduct(Map<String, dynamic> product, {List<File> images = const []}) async {
    print('Adding product to ${_pb.baseUrl}');
    try {
      if (!PocketBaseService().isAuthenticated()) {
        print('Not authenticated, attempting to authenticate with default credentials');
        await PocketBaseService().authWithPassword('admin@gmail.com', '12345678');
      }

      final body = {
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'stock': product['stock'],
        'category': product['category'],
        'is_featured': product['is_featured'],
      };

      List<http.MultipartFile> files = [];
      
      // Handle image upload for mobile (with File objects)
      if (images.isNotEmpty) {
        for (File image in images) {
          final bytes = await image.readAsBytes();
          final fileName = image.path.split('/').last;
          files.add(
            http.MultipartFile.fromBytes(
              'image', 
              bytes, 
              filename: fileName
            )
          );
        }
      }
      
      // Handle image upload for web (with URL from temp upload)
      if (product['image'] != null && product['image'].isNotEmpty) {
        // For web, we need to handle the image URL differently
        // Since the image is already uploaded to temp_images, we need to copy it
        body['image'] = product['image'];
      }

      final record = await _pb.collection('products').create(
        body: body, 
        files: files
      );
      
      print('Product created successfully with ID: ${record.id}');
      
      // Refresh the products list
      await fetchProducts();
    } catch (e) {
      print('Error adding product: $e');
      throw e;
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> product, {List<File> images = const []}) async {
    print('Updating product $productId');
    try {
      if (!PocketBaseService().isAuthenticated()) {
        await PocketBaseService().authWithPassword('admin@gmail.com', '12345678');
      }

      final body = {
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'stock': product['stock'],
        'category': product['category'],
        'is_featured': product['is_featured'],
      };

      List<http.MultipartFile> files = [];
      
      // Handle new image upload
      if (images.isNotEmpty) {
        for (File image in images) {
          final bytes = await image.readAsBytes();
          final fileName = image.path.split('/').last;
          files.add(
            http.MultipartFile.fromBytes(
              'image', 
              bytes, 
              filename: fileName
            )
          );
        }
      }

      await _pb.collection('products').update(
        productId,
        body: body,
        files: files
      );
      
      print('Product updated successfully');
      
      // Refresh the products list
      await fetchProducts();
    } catch (e) {
      print('Error updating product: $e');
      throw e;
    }
  }

  Future<void> deleteProduct(String productId) async {
    print('Deleting product $productId');
    try {
      if (!PocketBaseService().isAuthenticated()) {
        await PocketBaseService().authWithPassword('admin@example.com', 'password123');
      }

      await _pb.collection('products').delete(productId);
      
      print('Product deleted successfully');
      
      // Refresh the products list
      await fetchProducts();
    } catch (e) {
      print('Error deleting product: $e');
      throw e;
    }
  }

  // Helper method to get image URL
  String getImageUrl(Map<String, dynamic> product) {
    if (product['image'] == null || product['image'].isEmpty) {
      return '';
    }
    
    return 'https://f4f3-2405-8180-1001-4fd9-fd54-8fe6-86a-767e.ngrok-free.app/api/files/products/${product['id']}/${product['image']}';
  }
}