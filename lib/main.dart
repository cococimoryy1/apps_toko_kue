import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/cart_provider.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/product_list_page.dart';
import 'screens/product_detail_page.dart';
import 'screens/cart_page.dart';
import 'screens/admin_dashboard.dart';
import 'screens/adminprovider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: BakeryApp(),
    ),
  );
}

class BakeryApp extends StatelessWidget {
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
        '/home': (context) => HomePage(),
        '/products': (context) => ProductListPage(),
        '/productDetail': (context) => ProductDetailPage(productId: ModalRoute.of(context)!.settings.arguments as String),
        '/cart': (context) => CartPage(),
        '/admin': (context) => AdminDashboard(),
      },
    );
  }
}