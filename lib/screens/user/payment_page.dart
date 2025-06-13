import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import '../../pocketbase_services.dart';
import 'package:flutter/foundation.dart'; // Added missing import for defaultTargetPlatform

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
  late GoogleMapController mapController;
  LatLng _selectedLocation = const LatLng(-6.1745, 106.8227); // Default: Jakarta

  @override
  void initState() {
    super.initState();
    // Pre-fill recipient name and phone if available from auth (optional)
    final pb = PocketBaseService().pb;
    if (pb.authStore.isValid) {
      _recipientNameController.text = pb.authStore.model.data['name'] ?? '';
      _phoneController.text = pb.authStore.model.data['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Cek apakah lokasi aktif
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Layanan lokasi tidak aktif')));
    return;
  }

  // Cek permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Izin lokasi ditolak')));
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Izin lokasi ditolak permanen')));
    return;
  }

  // Ambil posisi
  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  setState(() {
    _selectedLocation = LatLng(position.latitude, position.longitude);
  });

  // Ambil alamat dari koordinat
  List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
  if (placemarks.isNotEmpty) {
    final place = placemarks.first;
    setState(() {
      _addressController.text =
          '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
    });
  }
}

  Future<void> _getCoordinatesFromAddress(String address) async {
    if (!kIsWeb && (defaultTargetPlatform != TargetPlatform.windows)) {
      try {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          setState(() {
            _selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
            mapController.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alamat tidak ditemukan')));
      }
    }
  }

  void _onMapTapped(LatLng position) {
    if (!kIsWeb && (defaultTargetPlatform != TargetPlatform.windows)) {
      setState(() {
        _selectedLocation = position;
        mapController.animateCamera(CameraUpdate.newLatLng(_selectedLocation));
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      final pb = PocketBaseService().pb;
      try {
        if (!pb.authStore.isValid) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please log in to place an order.')));
          return;
        }

        final orderData = {
          'user': pb.authStore.model.id,
          'recipient_name': _recipientNameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'latitude': _selectedLocation.latitude,
          'longitude': _selectedLocation.longitude,
          'total': widget.totalPrice.toInt(),
          'status': _status,
          'notes': _notesController.text,
          'timestamp': DateTime.now().toIso8601String(),
          'created': DateTime.now().toIso8601String(),
          'updated': DateTime.now().toIso8601String(),
        };

        await pb.collection('orders').create(body: orderData);

        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.clearCart();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pesanan berhasil dibuat!')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
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
              onChanged: _getCoordinatesFromAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Alamat tidak boleh kosong';
                return null;
              },
            ),
            SizedBox(height: 8),
          ElevatedButton.icon(
            icon: Icon(Icons.my_location),
            label: Text('Gunakan Lokasi Saya'),
            onPressed: _getCurrentLocation,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),

              SizedBox(height: 16),
              Text('Peta Lokasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
                Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: Center(
                    child: Text('Peta tidak didukung di platform ini. Gunakan koordinat default.'),
                  ),
                )
              else
                Container(
                  height: 200,
                  child: GoogleMap(
                    onMapCreated: (controller) => mapController = controller,
                    initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 12),
                    onTap: _onMapTapped,
                    markers: {
                      Marker(
                        markerId: MarkerId('selected-location'),
                        position: _selectedLocation,
                        infoWindow: InfoWindow(title: 'Lokasi Terpilih'),
                      ),
                    },
                  ),
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