import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/user/cart_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/user/home_page.dart';
import 'screens/user/product_list_page.dart';
import 'screens/user/product_detail_page.dart';
import 'screens/user/cart_page.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/adminprovider.dart';
import 'screens/admin/add_product_page.dart';
import 'screens/admin/product_provider.dart';
import 'screens/profil/profil_page.dart';
import 'screens/profil/profil_page.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: 'https://eoltmoazpgypwbygtvcm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvbHRtb2F6cGd5cHdieWd0dmNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk3ODYzNTIsImV4cCI6MjA2NTM2MjM1Mn0.eUSPqkyEeDurJKn-7ICUDeiDgPGNcWcIKKyFlpnNxHY',
    debug: true,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();
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
  final SupabaseClient supabase = Supabase.instance.client;

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
    final user = supabase.auth.currentUser;
    if (user == null) {
      return LoginPage();
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: supabase
          .from('profiles')
          .select('name, phone, role')
          .eq('id', user.id)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return ProfilePage(
            name: 'Unknown',
            email: user.email ?? 'No email',
            phone: 'No phone',
            role: 'No role',
          );
        }
        final profile = snapshot.data!;
        return ProfilePage(
          name: profile['name'] ?? 'Unknown',
          email: user.email ?? 'No email',
          phone: profile['phone'] ?? 'No phone',
          role: profile['role'] ?? 'No role',
        );
      },
    );
  }

  Widget _buildEditProfilePage(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return LoginPage();
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: supabase
          .from('profiles')
          .select('name, phone, role')
          .eq('id', user.id)
          .single(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return EditProfilePage(
            name: 'Unknown',
            email: user.email ?? 'No email',
            phone: 'No phone',
            role: 'No role',
          );
        }
        final profile = snapshot.data!;
        return EditProfilePage(
          name: profile['name'] ?? 'Unknown',
          email: user.email ?? 'No email',
          phone: profile['phone'] ?? 'No phone',
          role: profile['role'] ?? 'No role',
        );
      },
    );
  }
}