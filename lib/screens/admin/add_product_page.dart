import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'product_provider.dart'; // Adjust the import path as needed

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  String _categoryId = '';
  bool _isFeatured = false;
  String? _editingProductId;
  String searchQuery = '';
  bool _isLoading = false;
  List<String> _images = [];

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _imageUrlController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.products.isEmpty) productProvider.fetchProducts();
    if (productProvider.categories.isEmpty) productProvider.fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Tidak ada sesi autentikasi, silakan login ulang');
      }

      final product = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'category': _categoryId,
        'is_featured': _isFeatured,
        'images': _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
      };

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      if (_editingProductId != null) {
        await productProvider.updateProduct(_editingProductId!, product);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil diperbarui')));
      } else {
        await productProvider.addProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil ditambahkan')));
      }

      await productProvider.fetchProducts(); // Refresh the product list
      _clearForm();
    } catch (e) {
      print('Error saving product: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan produk: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.clear();
    _imageUrlController.clear();
    setState(() {
      _categoryId = '';
      _isFeatured = false;
      _editingProductId = null;
      _images = [];
    });
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        await productProvider.deleteProduct(productId);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produk berhasil dihapus')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus produk: $e')));
      }
    }
  }

  void _editProduct(Map<String, dynamic> product) {
    setState(() {
      _editingProductId = product['id'] as String;
      _nameController.text = product['name'] ?? '';
      _descriptionController.text = product['description'] ?? '';
      _priceController.text = (product['price'] as num?)?.toString() ?? '0';
      _stockController.text = (product['stock'] as num?)?.toString() ?? '0';
      _categoryId = product['category'] ?? '';
      _isFeatured = product['is_featured'] ?? false;
      _imageUrlController.text = product['images'] != null ? product['images'] as String : '';
    });
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    print('Membangun kartu untuk produk: $product');
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(8),
            image: product['images'] != null && product['images'].isNotEmpty
                ? DecorationImage(
                    image: Image.network(
                      product['images'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Error memuat gambar: $error, URL: ${product['images']}');
                        return Icon(Icons.error, color: Colors.red);
                      },
                    ).image,
                  )
                : null,
          ),
          child: product['images'] == null || product['images'].isEmpty
              ? Icon(Icons.image, color: Colors.grey, size: 30)
              : null,
        ),
        title: Text(product['name'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rp ${product['price'].toStringAsFixed(0)}'),
            Text('Stok: ${product['stock']}'),
            if (product['is_featured'] == true)
              Chip(
                label: Text('Featured', style: TextStyle(fontSize: 10)),
                backgroundColor: Color(0xFFEC4899),
                labelStyle: TextStyle(color: Colors.white),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Color(0xFFEC4899)),
              onPressed: () => _editProduct(product),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProduct(product['id']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;
    final categories = productProvider.categories;

    final filteredProducts = products.where((product) {
      if (searchQuery.isEmpty) return true;
      return product['name'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_editingProductId != null ? 'Edit Produk' : 'Kelola Produk'),
        backgroundColor: Color(0xFFEC4899),
        foregroundColor: Colors.white,
        actions: [
          if (_editingProductId != null)
            IconButton(icon: Icon(Icons.close), onPressed: _clearForm),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search, color: Color(0xFFEC4899)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Color(0xFFF9A8D4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Color(0xFFEC4899)),
                ),
                filled: true,
                fillColor: Color(0xFFFDF2F8),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Produk',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Nama tidak boleh kosong' : null,
                    onSaved: (value) => _nameController.text = value ?? '',
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Deskripsi tidak boleh kosong' : null,
                    onSaved: (value) => _descriptionController.text = value ?? '',
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Harga',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value?.isEmpty == true ? 'Harga tidak boleh kosong' : null,
                          onSaved: (value) => _priceController.text = value ?? '',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value?.isEmpty == true ? 'Stok tidak boleh kosong' : null,
                          onSaved: (value) => _stockController.text = value ?? '',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    value: _categoryId.isNotEmpty ? _categoryId : null,
                    items: categories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'].toString(),
                        child: Text(category['name']),
                      );
                    }).toList(),
                    validator: (value) => value == null ? 'Pilih kategori' : null,
                    onChanged: (value) {
                      setState(() {
                        _categoryId = value ?? '';
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  SwitchListTile(
                    title: Text('Produk Unggulan'),
                    subtitle: Text('Tampilkan di halaman utama'),
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value;
                      });
                    },
                    activeColor: Color(0xFFEC4899),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL Gambar',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'Masukkan URL gambar',
                    ),
                    validator: (value) => value?.isEmpty == true ? 'URL gambar tidak boleh kosong' : null,
                    onSaved: (value) => _imageUrlController.text = value ?? '',
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFEC4899),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white),
                                )
                              : Text(
                                  _editingProductId != null ? 'Perbarui Produk' : 'Tambah Produk',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _clearForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Bersihkan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.inventory, color: Color(0xFFEC4899)),
                SizedBox(width: 8),
                Text(
                  'Daftar Produk (${filteredProducts.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'Belum ada produk\nTambahkan produk pertama Anda!'
                              : 'Tidak ada produk yang cocok\ndengan pencarian "$searchQuery"',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) => _buildProductCard(filteredProducts[index]),
                  ),
          ],
        ),
      ),
    );
  }
}