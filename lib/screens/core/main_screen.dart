import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/widgets/custom_navbar_curved.dart';

import "package:ootdmate_frontend/screens/core/home/home_screen.dart";
import "package:ootdmate_frontend/screens/core/wardrobes/wardrobe_screen.dart";


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. Menyimpan state index yang sedang aktif (dimulai dari 0 yaitu Home)
  int _selectedIndex = 0;

  // 2. Daftar halaman (List of Widgets) yang akan ditampilkan di body
  // Sementara kita pakai Center Text, nanti tinggal kamu ganti dengan HomeScreen(), dsb.
  final List<Widget> _pages = [
    HomeScreen(),
    WardrobeScreen(),
    // const Center(child: Text("Cart Screen", style: TextStyle(fontSize: 24))),
    // const Center(child: Text("Calendar Screen", style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. Menggunakan IndexedStack agar state halaman tidak hilang saat pindah tab
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // 4. Memanggil Navbar buatanmu yang sudah kita perbaiki tadi
      bottomNavigationBar: CustomNavBarCurved(
        currentIndex: _selectedIndex,
        onTap: (int index) {
          // Ketika icon navbar diklik, state ini akan memicu render ulang
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}