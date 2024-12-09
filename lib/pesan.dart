import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Untuk parsing JSON
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pembayaran.dart';

class PesanPage extends StatefulWidget {
  final String productName;
  final String productPrice;
  final String productImage;
  final String productDescription;
  final String productId;
  
  PesanPage({
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.productDescription,
    required this.productId,}) : super();

  @override
  _PesanPageState createState() => _PesanPageState();
}

class _PesanPageState extends State<PesanPage> {
  final TextEditingController _quantityController = TextEditingController()..text = '1';

  List profile = [];
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userAlamat = 'Loading...';
  String userTelepon = 'Loading...';
  String quantity = '1';
  bool isLoading = true; // Menyimpan status loading
  String errorMessage = ''; // Menyimpan pesan error jika ada
  
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
            userAlamat = responseData['data']['alamat'] ?? 'Alamat Tidak Tersedia';
            userTelepon = responseData['data']['telepon'] ?? 'Telepon Tidak Tersedia';
            isLoading = false;
          });
        } else {
          // Tangani kesalahan
          setState(() {
            userName = 'Error';
            userEmail = responseData['message'] ?? 'Gagal memuat profil';
            userAlamat = responseData['message'] ?? 'Gagal memuat profil';
            userTelepon = responseData['message'] ?? 'Gagal memuat profil';
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

  @override
  void initState() {
    super.initState();
    fetchUserProfile(); // Ambil data pengguna
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _order(BuildContext context) {
    final String quantity = _quantityController.text;

    int q = int.parse(quantity);

    if (q < 1) {
      return ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Quantity tidak boleh kurang dari 1"),
            backgroundColor: Colors.red,
          ),
        );
    } else if (q > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Quantity tidak boleh lebih dari 300"),
            backgroundColor: Colors.red,
          ),
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PembayaranPage(
          productName:
              widget.productName,
          productPrice:
              widget.productPrice,
          productImage:
              widget.productImage,
          productDescription:
              widget.productDescription,
          productId:
              widget.productId,
          quantity:
              quantity
        ),
      ),
    );
    return ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(microseconds: 1),
              content: Text(''),
              backgroundColor: const Color.fromARGB(0, 255, 255, 255),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pemesanan"
        ),
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
                    Color.fromARGB(255, 246, 246, 255),
                    Color.fromARGB(255, 246, 246, 255),
                  ],
                  stops: [0, 1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Container(
              height: screenHeight-140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text("Make sure that your order information is correct",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(230, 19, 42, 166),
                            ),),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          width: screenWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                color: Color.fromARGB(220, 19, 42, 166),
                                height: 4,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Alamat",
                                    style: TextStyle(
                                      color: Color.fromARGB(220, 19, 42, 166),
                                    ),),
                                    SizedBox(height: 8,),
                                    Text(userName + " | " + userTelepon,
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),),
                                    SizedBox(height: 4,),
                                    Text(userAlamat,
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8,),
                        Container(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Pesanan",
                                      style: TextStyle(
                                      color: Color.fromARGB(200, 19, 42, 166),
                                    ),),
                                    SizedBox(height: 8,),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: screenWidth-106,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Image.network(widget.productImage,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.error,
                                                    size: 50,
                                                    color: Colors.red,
                                                  );
                                                },
                                              ),
                                              SizedBox(height: 12,),
                                              Text(widget.productName, 
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                    ),
                                                ),
                                              Text(widget.productPrice),
                                            ],
                                          ),
                                        ),
                                        Container(
                                        width: 50,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text("Jumlah"),
                                            SizedBox(height: 4,),
                                            SizedBox(
                                              width: 50,
                                              height: 30,
                                              child: TextField(
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                ),
                                                keyboardType: TextInputType.number,
                                                inputFormatters: <TextInputFormatter>[
                                                    FilteringTextInputFormatter.digitsOnly
                                                    ], // Only numbers can be entered
                                                controller: _quantityController,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(width: 1),
                                                  ),
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      ],
                                    ),
                                  ]  
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: 
                      Column(
                        children: [
                          SizedBox(
                            width: screenWidth - 80,
                            child: ElevatedButton(
                              onPressed: () {_order(context);},
                              child: Text('Next'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 36),
                                backgroundColor: Color.fromARGB(255, 4, 28, 162),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
