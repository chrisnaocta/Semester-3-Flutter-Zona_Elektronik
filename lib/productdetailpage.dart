import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import package intl
import 'package:shared_preferences/shared_preferences.dart';
import 'pesan.dart';

class ProductDetailPage extends StatelessWidget {
  final String productName;
  final String productPrice;
  final String productImage;
  final String productDescription;
  final String productId;

  ProductDetailPage({
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.productDescription,
    required this.productId,
  });

  // Fungsi untuk melakukan pembelian produk dan menyimpan ke database
  Future<void> _buyProduct(BuildContext context) async {
    final SharedPreferences session = await SharedPreferences.getInstance();
    String? email = session.getString('email'); // Ambil email dari session
    // Tampilkan pesan loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sedang memproses pembelian...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Membersihkan format harga produk
      String cleanedPrice = productPrice.replaceAll(RegExp(r'[^0-9]'), '');

      // Mengirim POST request ke server untuk menyimpan data pembelian
      final response = await http.post(
        Uri.parse('http://10.0.2.2/Zona_Elektronik/penjualan.php'),
        body: {
          'id_produk': productId,
          'harga_produk': cleanedPrice,
          'quantity': '1',
          'email': email,
        },
      );

      // Log respons untuk debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Cek apakah respons dari server berhasil
      if (response.statusCode == 200) {
        print(productName);
        print(cleanedPrice);
        print(productId);
        print(email);
        var responseData = json.decode(response.body);
        if (responseData['value'] == 1) {
          // Tampilkan pesan sukses jika pembelian berhasil
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembelian berhasil!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Tampilkan pesan error jika terjadi masalah dalam penyimpanan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Gagal melakukan pembelian: ${responseData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Tampilkan pesan error jika respons dari server tidak 200
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan pembelian. Coba lagi!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Tangkap error jika terjadi exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk memformat harga dengan NumberFormat yang sesuai
  String formatCurrency(String price) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
    // Mengubah harga menjadi integer, membagi dengan 100 untuk mengurangi dua digit, lalu memformatnya
    return formatter
        .format(int.parse(price.replaceAll(RegExp(r'[^0-9]'), '')) / 100);
  }

  @override
  Widget build(BuildContext context) {
    // Memformat harga produk menggunakan fungsi formatCurrency
    String formattedPrice = formatCurrency(productPrice);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 252, 252, 255),
        foregroundColor: Color.fromARGB(255, 19, 42, 166),
        toolbarHeight: 80,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
            width: screenWidth,
            height: screenHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 246, 246, 255),
                ],
                stops: [0, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
            Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Image.network(
                    productImage,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.error,
                        size: 100,
                        color: Colors.red,
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  productDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 28),
                // Menampilkan harga yang sudah diformat
                Text(
                  formattedPrice,
                  style: TextStyle(
                    fontSize: 24,
                    color: const Color.fromARGB(255, 0, 160, 5),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PesanPage(
                          productName:
                              productName,
                          productPrice:
                              productPrice,
                          productImage:
                              productImage,
                          productDescription:
                              productDescription,
                          productId:
                              productId,
                        ),
                      ),
                    );},
                  child: Text('Beli Sekarang'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 36),
                    backgroundColor: Color.fromARGB(255, 4, 28, 162),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ]
        ),
      ),
    );
  }
}
