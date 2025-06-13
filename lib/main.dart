import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'screens/user/cart_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/user/home_page.dart';
import 'screens/user/product_list_page.dart';
import 'screens/user/product_detail_page.dart';
import 'screens/user/cart_page.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/adminprovider.dart';
import 'screens/admin/add_product_page.dart';
import 'screens/user/product_provider.dart';
import 'screens/profil/profil_page.dart';
import 'screens/profil/edit_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: BakeryApp(),
    ),
  );
}

class BakeryApp extends StatelessWidget {
  final PocketBase pb = PocketBase('http://127.0.0.1:8090'); // Ganti dengan URL PocketBase Anda

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Roti Bahagia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFFEC4899, {
          50: Color(0xFFFDF2F8),
          100: Color(0xFFFCE7F3),
          200: Color(0xFFFBCFE8),
          300: Color(0xFFF9A8D4),
          400: Color(0xFFF472B6),
          500: Color(0xFFEC4899),
          600: Color(0xFFDB2777),
          700: Color(0xFFBE185D),
          800: Color(0xFF9D174D),
          900: Color(0xFF831843),
        }),
        primaryColor: Color(0xFFEC4899),
        scaffoldBackgroundColor: Color(0xFFFAF9F7),
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/products': (context) => ProductListPage(),
        '/productDetail': (context) => ProductDetailPage(productId: ModalRoute.of(context)!.settings.arguments as String),
        '/cart': (context) => CartPage(),
        '/admin': (context) => AdminDashboard(),
        '/addProduct': (context) => AddProductPage(),
        '/profile': (context) => _buildProfilePage(context),
        '/edit_profile': (context) => _buildEditProfilePage(context),
      },
    );
  }

  Widget _buildProfilePage(BuildContext context) {
    final user = pb.authStore.model;
    if (user == null) {
      return LoginPage(); // Redirect ke login jika belum login
    }
    return ProfilePage(
      name: user.data['name'] ?? 'Unknown',
      email: user.data['email'] ?? 'No email',
      phone: user.data['phone'] ?? 'No phone',
      role: user.data['role'] ?? 'No role',
    );
  }

  Widget _buildEditProfilePage(BuildContext context) {
    final user = pb.authStore.model;
    if (user == null) {
      return LoginPage(); // Redirect ke login jika belum login
    }
    return EditProfilePage(
      name: user.data['name'] ?? 'Unknown',
      email: user.data['email'] ?? 'No email',
      phone: user.data['phone'] ?? 'No phone',
      role: user.data['role'] ?? 'No role',
    );
  }
}