import 'package:flutter/material.dart';
import 'login.dart'; // Import login.dart

// Color.fromARGB(255, 66, 83, 179)
// Color.fromARGB(255, 38, 57, 166)
// Color.fromARGB(255, 0, 15, 107)

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zona Elektronik',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 15, 107)),
      ),
      home:
          LoginPage(), // Menetapkan Login page sebagai halaman utama (Halaman yang akan pertama dibuka jika program dijalankan)
    );
  }
}
