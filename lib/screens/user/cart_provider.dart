import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final _supabase = Supabase.instance.client;
    try {
      print('Current user ID: ${_supabase.auth.currentUser?.id}'); // Added debug log
      if (_supabase.auth.currentUser == null) {
        print('User not authenticated');
        return;
      }
      await _supabase.from('cart_items').insert({
        'user': _supabase.auth.currentUser!.id,
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

  Future<void> fetchCartItems() async {
    final _supabase = Supabase.instance.client;
    try {
      if (_supabase.auth.currentUser == null) {
        print('User not authenticated');
        return;
      }
      final response = await _supabase
          .from('cart_items')
          .select('id, product, quantity')
          .eq('user', _supabase.auth.currentUser!.id);
      _cartItems = await Future.wait(response.map((record) async {
        final product = await _supabase
            .from('products')
            .select('id, name, price, image')
            .eq('id', record['product'])
            .single();
        String imageUrl = product['image'] != null
            ? _supabase.storage.from('product_images').getPublicUrl(product['image'])
            : '🍞';
        return {
          'id': record['product'],
          'name': product['name'] as String? ?? 'No Name',
          'price': (product['price'] as num?)?.toDouble() ?? 0,
          'image': imageUrl,
          'quantity': record['quantity'] as int? ?? 1,
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