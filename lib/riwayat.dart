import 'package:flutter/material.dart';
import 'dart:convert'; // Untuk parsing JSON
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Impor intl untuk memformat angka
import 'login.dart'; // Impor halaman login
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_elektronik/dashboard_page.dart';
import 'package:zona_elektronik/riwayat.dart';
import 'package:zona_elektronik/pesanan.dart';

class RiwayatPage extends StatefulWidget {
  final String email;

  RiwayatPage({
    required this.email,
  });

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List pesanan = [];
  List products = [];
  Map<String, String> productImages = Map();
  bool isLoading = true; // Menyimpan status loading
  String errorMessage = ''; // Menyimpan pesan error jika ada
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userProfilePhoto = 'Loading...';
  bool empty = true;

  // Fungsi untuk mengambil data produk dari API
  Future<void> fetchPesanan() async {
    String email = widget.email;
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/Zona_Elektronik/get_riwayat.php'),
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
            pesanan = responseData['data'];
            if (pesanan.length > 0) {
              empty = false; 
            }
            isLoading =
                false; // Set loading ke false setelah data berhasil diambil
          });
        }
      } else {
        throw Exception('Failed to load pesanan');
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
    fetchPesanan(); // Panggil fungsi untuk mengambil data saat widget diinisialisasi
    fetchProducts();
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
          for(var i=0;i<products.length;i++){
            String key = products[i]["idproduct"];
            String value = products[i]["image"];
            productImages[key] = value;
          }
        }
        );
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString(); // Simpan pesan error
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

  String? getImage(String id) {
    return productImages[id];
  }

  // Fungsi untuk memformat harga
  String formatCurrency(String price) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
    return formatter.format(int.parse(price));
  }

  // Fungsi untuk memformat harga
  String formatTotal(String price, String quantity) {
    int harga = int.parse(price);
    int qty = int.parse(quantity);
    int total = harga * qty;

    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
    return formatter.format(total);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    var page = Column(
      children: [
        Container(
          width: screenHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10)
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Tidak ada pesanan yang telah di-review! Cek halaman pesanan untuk melihat pesanan yang sedang berlangsung!",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );

    if (!empty) {
      page = Column(
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
                                crossAxisCount: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2.2,
                              ),
                            itemCount: pesanan.length,
                            itemBuilder: (context, index) {
                              final itempesanan = pesanan[index];
                              final String img = productImages[itempesanan["idproduct"]]!;
                              final harga = itempesanan['quantity'] +" x " + formatCurrency(itempesanan['price']);
                              final total = formatTotal(itempesanan['price'], itempesanan['quantity']);
                              var status = itempesanan["order_status"];
                              var order_status = Text(status,
                              style: TextStyle(
                                color: Color.fromARGB(255, 19, 166, 46)
                              ),);

                              if (status == "Rejected") {
                                order_status = Text(status,
                                style: TextStyle(
                                color: Color.fromARGB(255, 166, 19, 19)
                              ),);
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column( 
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(itempesanan['tgljual'],
                                          style: TextStyle(
                                            color: const Color.fromARGB(177, 0, 0, 0)),
                                          ),
                                          order_status,
                                        ],
                                      ),
                                      SizedBox(height: 8,),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 60,
                                            width: 60,
                                            child: Image.network(
                                          img,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.error,
                                              size: 100,
                                              color: const Color.fromARGB(255, 175, 33, 23),
                                            );
                                            }),
                                          ),
                                          SizedBox(width: 12,),
                                          SizedBox(
                                            width: screenWidth-160,
                                            child: Text(itempesanan['product'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold
                                            ),),
                                          )
                                        ],
                                      ),
                                      SizedBox(height: 12,),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(harga),
                                              Text("Total: " + total,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 36,
                                            width: 88,
                                            child: ElevatedButton(
                                              onPressed: (){}, 
                                              child: Text("View info"),
                                              style: ButtonStyle(
                                                backgroundColor: WidgetStatePropertyAll(const Color.fromARGB(255, 238, 238, 238)),
                                                foregroundColor: WidgetStatePropertyAll(Color.fromARGB(255, 19, 42, 166)),
                                                shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                                                padding: WidgetStatePropertyAll(EdgeInsets.all(4)),
                                                elevation: WidgetStatePropertyAll(0),
                                              ),
                                              ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
    }


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
          padding: const EdgeInsets.all(12.0),
          child: page,
        ),
        ]
      ),
    );
  }
}
