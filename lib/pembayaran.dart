import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Untuk mengambil gambar
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Untuk parsing JSON
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_elektronik/dashboard_page.dart';

class PembayaranPage extends StatefulWidget {
  final String productName;
  final String productPrice;
  final String productImage;
  final String productDescription;
  final String productId;
  final String quantity;
  
  PembayaranPage({
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.productDescription,
    required this.productId,
    required this.quantity}) : super();

  @override
  _PembayaranPageState createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  final TextEditingController _quantityController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String total = '0';
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userAlamat = 'Loading...';
  String userTelepon = 'Loading...';
  bool isLoading = true; // Menyimpan status loading
  String errorMessage = ''; // Menyimpan pesan error jika ada
  bool uploaded = false;

  // Fungsi untuk memilih gambar
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Batas lebar maksimum gambar
      maxHeight: 800, // Batas tinggi maksimum gambar
      imageQuality: 80, // Kualitas gambar (0-100)
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        uploaded = true;
      });
    }
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

  void setQuantity () {
    _quantityController..text = widget.quantity;
  }

  void calculateTotal() {
    String cleanedPrice = widget.productPrice.replaceAll(RegExp(r'[^0-9]'), '');
    int price = int.parse(cleanedPrice);
    int qty = int.parse(widget.quantity);

    double totalprice = price * qty * 0.01;

    total = totalprice.toString();
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile(); // Ambil data pengguna
    setQuantity();
    calculateTotal();
  }

  Future<void> _Order(BuildContext context) async {
    // Tampilkan pesan loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sedang memproses pembelian...'),
        duration: Duration(seconds: 2),
      ),
    );
    final String quantity = _quantityController.text;

    int q = int.parse(quantity);

    if (q < 1) {
      errorMessage = "Quantity tidak boleh kurang dari 1";
      return;
    } else if (q > 300) {
      errorMessage = "Quantity tidak boleh lebih dari 300";
    }

    try {
      var uri = Uri.http('10.0.2.2', '/Zona_Elektronik/pesan.php');
      var request = http.MultipartRequest('POST', uri);

      // Menambahkan field ke request
      request.fields['id_produk'] = widget.productId;
      request.fields['quantity'] = quantity;
      request.fields['email'] = userEmail;

      // Add image file
      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'bukti_trf',
          _imageFile!.path,
        ));
      }

      // Send the request
      var response = await request.send();
      // Cek apakah respons dari server berhasil
      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);
        var jsonData = jsonDecode(responseData.body);
        if (jsonData['value'] == 1) {
          // Tampilkan pesan sukses jika pembelian berhasil
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pesanan berhasil diproses!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        } else {
          // Tampilkan pesan error jika terjadi masalah dalam penyimpanan
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Gagal melakukan pesanan: ${jsonData['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Tampilkan pesan error jika respons dari server tidak 200
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal melakukan pesanan. Coba lagi!'),
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

  // Fungsi untuk memformat harga
  String formatCurrency(String price) {
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
    return formatter.format(double.parse(price));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    var uploadedText = Text("");

    if (uploaded) {
      uploadedText = Text("Uploaded ", style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 19, 42, 166)),);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Pembayaran"
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
                                              SizedBox(height: 4,),
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
                                            SizedBox(
                                              width: 50,
                                              height: 30,
                                              child: TextField(
                                                enabled: false,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  color: const Color.fromARGB(255, 90, 90, 90),
                                                  fontSize: 16,
                                                ),
                                                keyboardType: TextInputType.number,
                                                inputFormatters: <TextInputFormatter>[
                                                    FilteringTextInputFormatter.digitsOnly
                                                    ], // Only numbers can be entered
                                                controller: _quantityController,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(
                                                    borderSide: BorderSide(width: 1, color: const Color.fromARGB(255, 31, 31, 31)),
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
                        SizedBox(height: 8,),
                        Container(
                          color: Color.fromARGB(220, 19, 42, 166),
                          height: 4,
                        ),
                        Container(
                          color: Colors.white,
                          width: screenWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Total",
                                  style: TextStyle(
                                  color: Color.fromARGB(200, 19, 42, 166),
                                  ),
                                ),
                                SizedBox(height: 8,),
                                Text(formatCurrency(total),
                                style: TextStyle(
                                  fontSize: 16,
                                ),),
                              ]  
                            ),
                          ),
                        ),
                        Container(
                          color: Color.fromARGB(220, 230, 230, 230),
                          height: 4,
                        ),
                        Container(
                          width: screenWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 8,),
                                Text("Mohon cantumkan email anda pada pesan transfer."),
                                SizedBox(height: 8,),
                                Text(
                                  "BCA\nXXXXXXXXXX\nA.N ZONA ELEKTRONIK",
                                  style: TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: _pickImage,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color.fromARGB(255, 240, 240, 240),
                                          foregroundColor: Color.fromARGB(255, 39, 39, 39),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Upload Bukti Transfer',
                                          style: TextStyle(
                                            fontSize: 16,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    uploadedText,
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 24),
                          child: 
                            Text(
                              "Pastikan semua data sudah benar sebelum melakukan pembayaran. Apabila ada kekeliruan pada nominal transfer, jumlah seluruhnya akan dikembalikan ke rekening Anda setelah pesanan melewati review. Kekeliruan apapun dalam rekening yang dituju tidak ditanggung oleh Zona Elektronik. Hubungi customer service kami pada 08XXXXXXXXXX bila butuh bantuan."
                            ),
                        )
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
                              onPressed: () {_Order(context);},
                              child: Text('Buat Pesanan'),
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
