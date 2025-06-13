import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../pocketbase_services.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];

  List<Map<String, dynamic>> get cartItems => _cartItems;

  void addToCart(Map<String, dynamic> product, int quantity) {
    final existingItemIndex = _cartItems.indexWhere((item) => item['id'] == product['id']);
    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex]['quantity'] += quantity;
    } else {
      _cartItems.add({
        'id': product['id'],
        'name': product['name'],
        'price': product['price'],
        'image': product['image'],
        'quantity': quantity,
      });
    }
    notifyListeners();
  }

  Future<void> addToCartWithDB(Map<String, dynamic> product, int quantity) async {
    final pb = PocketBaseService().pb;
    try {
      if (!pb.authStore.isValid) {
        print('User not authenticated');
        return;
      }
      await pb.collection('cart_items').create(body: {
        'user': pb.authStore.model.id,
        'product': product['id'],
        'quantity': quantity,
      });
      addToCart(product, quantity); // Update local state
    } catch (e) {
      print('Error saving to cart: $e');
    }
  }

  void updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index]['quantity'] = newQuantity;
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  int getTotalItems() {
    return _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double getTotalPrice() {
    return _cartItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  Future<void> fetchCartItems() async { // Ensure this is marked as async
    final pb = PocketBaseService().pb;
    try {
      if (!pb.authStore.isValid) {
        print('User not authenticated');
        return;
      }
      final records = await pb.collection('cart_items').getFullList(
        filter: 'user = "${pb.authStore.model.id}"',
      );
      _cartItems = await Future.wait(records.map((record) async {
        final productId = record.data['product'];
        final product = await pb.collection('products').getOne(productId); // Async call
        return {
          'id': productId,
          'name': product.data['name'] ?? 'No Name',
          'price': (product.data['price'] ?? 0).toDouble(), // Ensure price is a double
          'image': product.data['image'] != null
              ? 'http://127.0.0.1:8091/api/files/products/${product.id}/${product.data['image']}'
              : '🍞',
          'quantity': record.data['quantity'] ?? 1, // Default to 1 if null
        };
      }).toList());
      notifyListeners();
    } catch (e) {
      print('Error fetching cart items: $e');
      _cartItems = []; // Reset on error
      notifyListeners();
    }
  }
}