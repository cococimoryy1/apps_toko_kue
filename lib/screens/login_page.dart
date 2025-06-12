import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'pocketbase_services.dart'; // Tambahkan ini

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  final PocketBase _pb = PocketBaseService().pb; // Gunakan instance dari singleton

  // ... (kode lainnya tetap sama)

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _pb.collection('users').authWithPassword(
          _emailController.text,
          _passwordController.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ... (build method dan lainnya tetap sama)


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF9F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              
              // Logo and Welcome Text
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          '🍞',
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBE185D),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Masuk ke akun Anda untuk melanjutkan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email Field
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBE185D),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email Anda',
                        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFEC4899)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFF9A8D4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFEC4899), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Password Field
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBE185D),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Masukkan password Anda',
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFEC4899)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Color(0xFFEC4899),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFF9A8D4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFFEC4899), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Color(0xFFEC4899),
                            ),
                            Text(
                              'Ingat saya',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Lupa Password'),
                                  content: Text('Fitur reset password akan segera tersedia!'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text(
                            'Lupa Password?',
                            style: TextStyle(color: Color(0xFFEC4899)),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Masuk...'),
                                ],
                              )
                            : Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Demo Account Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFF9A8D4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔑 Demo Account',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFBE185D),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Email: admin@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            'Password: admin123',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'atau',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Social Login Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Login dengan Google akan segera tersedia!'),
                                  backgroundColor: Color(0xFFEC4899),
                                ),
                              );
                            },
                            icon: Text('🔍', style: TextStyle(fontSize: 20)),
                            label: Text('Google'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Color(0xFFF9A8D4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Login dengan Facebook akan segera tersedia!'),
                                  backgroundColor: Color(0xFFEC4899),
                                ),
                              );
                            },
                            icon: Text('📘', style: TextStyle(fontSize: 20)),
                            label: Text('Facebook'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Color(0xFFF9A8D4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Register Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterPage()),
                        );
                      },
                      child: Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          color: Color(0xFFEC4899),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}