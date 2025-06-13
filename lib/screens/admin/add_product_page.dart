import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import '../user/product_provider.dart';
import '../../pocketbase_services.dart';

class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  double _price = 0.0;
  int _stock = 0;
  String _categoryId = '';
  bool _isFeatured = false;
  String searchQuery = '';
  String? _editingProductId;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.products.isEmpty) {
      productProvider.fetchProducts();
    }
    if (productProvider.categories.isEmpty) {
      productProvider.fetchCategories();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      final pb = PocketBaseService().pb;

      // Ensure authentication
      if (!PocketBaseService().isAuthenticated()) {
        await PocketBaseService().authWithPassword('admin@gmail.com', '12345678');
      }

      final body = {
        'name': _name,
        'description': _description,
        'price': _price,
        'stock': _stock,
        'category': _categoryId,
        'is_featured': _isFeatured,
      };

      if (_editingProductId != null) {
        // Update existing product
        await pb.collection('products').update(
          _editingProductId!,
          body: body,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil diperbarui')),
        );
      } else {
        // Create new product
        await pb.collection('products').create(body: body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil ditambahkan')),
        );
      }

      // Refresh products list
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      await productProvider.fetchProducts();

      _clearForm();
    } catch (e) {
      print('Error saving product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan produk: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _name = '';
      _description = '';
      _price = 0.0;
      _stock = 0;
      _categoryId = '';
      _isFeatured = false;
      _editingProductId = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _deleteProduct(String productId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus produk ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PocketBaseService().pb.collection('products').delete(productId);
        final productProvider = Provider.of<ProductProvider>(context, listen: false);
        await productProvider.fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk berhasil dihapus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus produk: $e')),
        );
      }
    }
  }

  void _editProduct(Map<String, dynamic> product) {
    setState(() {
      _editingProductId = product['id'];
      _name = product['name'] ?? '';
      _description = product['description'] ?? '';
      _price = (product['price'] as num?)?.toDouble() ?? 0.0;
      _stock = (product['stock'] as num?)?.toInt() ?? 0;
      _categoryId = product['category'] ?? '';
      _isFeatured = product['is_featured'] ?? false;
    });
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
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
          ),
          child: Icon(Icons.image, color: Colors.grey, size: 30), // Placeholder tanpa gambar
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
            SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(
                      labelText: 'Nama Produk',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Nama tidak boleh kosong' : null,
                    onSaved: (value) => _name = value ?? '',
                    onChanged: (value) => _name = value,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    initialValue: _description,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    maxLines: 2,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Deskripsi tidak boleh kosong' : null,
                    onSaved: (value) => _description = value ?? '',
                    onChanged: (value) => _description = value,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _price.toString(),
                          decoration: InputDecoration(
                            labelText: 'Harga',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixText: 'Rp ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value?.isEmpty == true ? 'Harga tidak boleh kosong' : null,
                          onSaved: (value) => _price = double.tryParse(value ?? '0') ?? 0.0,
                          onChanged: (value) => _price = double.tryParse(value) ?? 0.0,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _stock.toString(),
                          decoration: InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value?.isEmpty == true ? 'Stok tidak boleh kosong' : null,
                          onSaved: (value) => _stock = int.tryParse(value ?? '0') ?? 0,
                          onChanged: (value) => _stock = int.tryParse(value) ?? 0,
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