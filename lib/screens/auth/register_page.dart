import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../user/home_page.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final response = await _supabase.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          data: {
            'display_name': _nameController.text,
          },
        );
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registrasi berhasil! Silakan verifikasi email Anda.')),
          );
          // Mengarahkan ke halaman login setelah SnackBar ditampilkan
          await Future.delayed(Duration(seconds: 1)); // Memberi waktu untuk SnackBar muncul
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAF9F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFEC4899)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text('🍞', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text('Buat Akun Baru', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFBE185D))),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama Lengkap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFBE185D))),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Masukkan nama lengkap Anda',
                        prefixIcon: Icon(Icons.person_outline, color: Color(0xFFEC4899)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFF9A8D4))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFEC4899), width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? 'Nama tidak boleh kosong' : null,
                    ),
                    SizedBox(height: 16),
                    Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFBE185D))),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Masukkan email Anda',
                        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFEC4899)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFF9A8D4))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFEC4899), width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => (value == null || value.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) ? 'Email tidak valid' : null,
                    ),
                    SizedBox(height: 16),
                    Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFBE185D))),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Buat password (min 6 karakter)',
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFEC4899)),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Color(0xFFEC4899)),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFF9A8D4))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFEC4899), width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => (value == null || value.isEmpty || value.length < 6) ? 'Password minimal 6 karakter' : null,
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                                SizedBox(width: 12),
                                Text('Mendaftar...'),
                              ])
                            : Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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