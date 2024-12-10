import 'package:flutter/material.dart';
import 'dart:convert'; // Untuk parsing JSON
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Impor intl untuk memformat angka
import 'login.dart'; // Impor halaman login
import 'productdetailpage.dart'; // Impor halaman ProductDetailPage
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_elektronik/dashboard_page.dart';
import 'package:zona_elektronik/riwayat.dart';
import 'package:zona_elektronik/pesanan.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List products = [];
  bool isLoading = true; // Menyimpan status loading
  String errorMessage = ''; // Menyimpan pesan error jika ada
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userProfilePhoto = 'Loading...';

  // Fungsi untuk mengambil data produk dari API
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2/Zona_Elektronik/get_products.php'), // Ganti dengan URL API Anda
      );

      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading =
              false; // Set loading ke false setelah data berhasil diambil
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Set loading ke false jika terjadi error
        errorMessage = e.toString(); // Simpan pesan error
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProducts(); // Panggil fungsi untuk mengambil data saat widget diinisialisasi
    fetchUserProfile(); // Panggil fungsi untuk mengambil profil pengguna
  }

  // Fungsi untuk mengambil profil pengguna
  Future<void> fetchUserProfile() async {
    try {
      final SharedPreferences session = await SharedPreferences.getInstance();
      String? email = session.getString('email'); // Ambil email dari session

      if (email == null) {
        setState(() {
          userName = 'Email tidak tersedia';
          userEmail = 'Email tidak tersedia';
          isLoading = false;
        });
        return; // Keluar dari fungsi jika email tidak ada
      }
      final response = await http.post(
        Uri.parse('http://10.0.2.2/Zona_Elektronik/get_users.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $email',
        },
        body: json.encode({'email': email}), // Mengirim email dalam body
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'success') {
          setState(() {
            userName = responseData['data']['nama'] ?? 'Nama Tidak Tersedia';
            userEmail = responseData['data']['email'] ?? 'Email Tidak Tersedia';
            userProfilePhoto =
                responseData['data']['foto'] ?? 'Foto Tidak Tersedia';
            isLoading = false;
          });
        } else {
          // Tangani kesalahan
          setState(() {
            userName = 'Error';
            userEmail = responseData['message'] ?? 'Gagal memuat profil';
            isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat profil pengguna');
      }
    } catch (e) {
      setState(() {
        userName = 'Error';
        userEmail = e.toString();
        isLoading = false;
      });
    }
  }

  //Function logout
  Future<void> _logout() async {
    try {
      // Hapus data sesi SharedPreferences
      final SharedPreferences session = await SharedPreferences.getInstance();
      await session.remove('isLogin');
      await session.remove('email');
      print(session.getString(
          'email')); //debug apakah email akan kosong setelah di remove
      await session.remove('password');

      // Navigasi kembali ke halaman login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      // Tangani error jika terjadi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal logout: ${e.toString()}')),
      );
    }
  }

  // Fungsi untuk memformat harga
  String formatCurrency(String price) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
    return formatter.format(int.parse(price));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          child: Image.asset("assets/images/zona_elektronik2.png"),
        ),
        backgroundColor: Color.fromARGB(255, 252, 252, 255),
        foregroundColor: Color.fromARGB(255, 19, 42, 166),
        toolbarHeight: 80,
        scrolledUnderElevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(              
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 19, 42, 166),
                
              ),
              accountName: Text(
                userName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),  
              ), // Nama pengguna
              accountEmail: Text(
                userEmail,
                style: TextStyle(
                  color: Colors.white,
                ),
                ), // Email pengguna
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(
                  'http://10.0.2.2/Zona_Elektronik/uploads/$userProfilePhoto', // Ganti dengan URL foto pengguna
                ),
                onBackgroundImageError: (_, __) =>
                    Icon(Icons.person), // Tampilkan icon default jika gagal
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text(
                'Home',
                style: TextStyle(
                )
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart,),
              title: Text(
                'Pesanan',
                style: TextStyle(
                )
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => PesananPage(email: userEmail)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history,),
              title: Text(
                'Riwayat Pesanan',
                style: TextStyle(
                )
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => RiwayatPage(email: userEmail)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings,),
              title: Text('Settings',
                style: TextStyle(
                )
              ),
              onTap: () {
                // Tambahkan logika untuk navigasi ke halaman pengaturan
              },
            ),
            ListTile(
              leading: Icon(Icons.logout,),
              title: Text('Logout',
                style: TextStyle(
                )
              ),
              onTap: () {
                _logout();
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 246, 246, 255),
                  Color.fromARGB(255, 246, 246, 255),
                ],
                stops: [0, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : errorMessage.isNotEmpty
                        ? Center(
                            child: Text(errorMessage)) // Menampilkan pesan error
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Card(
                                color: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(10),
                                          ),
                                          child: Image.network(
                                            product['image'],
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Icon(
                                                Icons.error,
                                                size: 100,
                                                color: const Color.fromARGB(255, 175, 33, 23),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['product'],
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            // Gunakan format angka untuk harga
                                            Text(
                                              formatCurrency(product['price']),
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ProductDetailPage(
                                                      productName:
                                                          product['product'] ??
                                                              'Unknown Product',
                                                      productPrice: formatCurrency(
                                                          product['price'] ?? '0'),
                                                      productImage:
                                                          product['image'] ?? '',
                                                      productDescription:
                                                          product['description'] ??
                                                              'No description',
                                                      productId:
                                                          product['idproduct'] ??
                                                              '0',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Text('Beli'),
                                              style: ElevatedButton.styleFrom(
                                                minimumSize: Size(double.infinity, 36),
                                                elevation: 0,
                                                backgroundColor: Color.fromARGB(255, 19, 42, 166),
                                                foregroundColor: Colors.white
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
        ]
      ),
    );
  }
}