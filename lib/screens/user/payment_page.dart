import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalPrice;

  PaymentPage({required this.cartItems, required this.totalPrice});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  String _status = 'pending';
  double _latitude = -6.1745; // Default: Jakarta latitude
  double _longitude = 106.8227; // Default: Jakarta longitude

  @override
  void initState() {
    super.initState();
    // Pre-fill recipient name and phone if available from auth (optional)
    final _supabase = Supabase.instance.client;
    if (_supabase.auth.currentUser != null) {
      _recipientNameController.text = _supabase.auth.currentUser!.userMetadata?['name'] ?? '';
      _phoneController.text = _supabase.auth.currentUser!.userMetadata?['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          _latitude = locations.first.latitude;
          _longitude = locations.first.longitude;
        });
        print('Coordinates resolved: Latitude: $_latitude, Longitude: $_longitude');
      } else {
        print('No locations found for address: $address');
        setState(() {
          _latitude = -6.1745; // Fallback to default Jakarta latitude
          _longitude = 106.8227; // Fallback to default Jakarta longitude
        });
      }
    } catch (e) {
      print('Error resolving address: $e');
      setState(() {
        _latitude = -6.1745; // Fallback to default
        _longitude = 106.8227; // Fallback to default
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      final _supabase = Supabase.instance.client;
      try {
        if (_supabase.auth.currentUser == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Silakan login untuk melakukan pemesanan')),
          );
          return;
        }

        // Convert address to coordinates before submitting
        await _getCoordinatesFromAddress(_addressController.text);

        final orderData = {
          'user': _supabase.auth.currentUser!.id,
          'recipient_name': _recipientNameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'latitude': _latitude,
          'longitude': _longitude,
          'total': widget.totalPrice.toInt(),
          'status': _status,
          'notes': _notesController.text,
          'timestamp': DateTime.now().toIso8601String(),
          'created': DateTime.now().toIso8601String(),
          'updated': DateTime.now().toIso8601String(),
        };

        await _supabase.from('orders').insert(orderData);

        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.clearCart();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pesanan berhasil dibuat!')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error submitting order: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detail Pesanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ...widget.cartItems.map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item['name']} x${item['quantity']}'),
                    Text('Rp ${item['price'] * item['quantity']}'),
                  ],
                ),
              )).toList(),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Harga:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Rp ${widget.totalPrice.toInt()}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
                ],
              ),
              SizedBox(height: 16),
              Text('Alamat Pengiriman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _recipientNameController,
                decoration: InputDecoration(labelText: 'Nama Penerima'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Nama penerima tidak boleh kosong';
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Nomor Telepon'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Nomor telepon tidak boleh kosong';
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Masukkan Alamat'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Alamat tidak boleh kosong';
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text('Catatan Tambahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: 'Contoh: Antar ke depan rumah'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              Text('Metode Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                items: ['Cash on Delivery', 'Bank Transfer'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _paymentMethod = newValue!;
                  });
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitOrder,
                  child: Text('Konfirmasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batalkan', style: TextStyle(fontSize: 16, color: Colors.red)),
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}