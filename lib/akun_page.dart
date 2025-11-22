import 'dart:io'; // WAJIB: Untuk menggunakan kelas File dan FileImage
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'lari_page.dart';
import 'akun_setgoals_page.dart'; 
import 'akun_riwayatlari_page.dart';
import 'akun_profile.dart'; // Pastikan ini ada
import 'login_page.dart';
import 'akun_achivement.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 2; 

  // --- DATA PROFILE (Dapat diubah) ---
  String _userName = 'Nama';
  String _userEmail = 'Email';
  String _userPhone = 'No. Telepon'; 
  // *STATE BARU UNTUK PATH FOTO*
  String? _profileImagePath; 
  // ------------------------------------
  
  // Data dummy/state awal
  double _weightAwal = 78.0; 
  final double _weightSaatIni = 71.0; 
  
  // --- STATE UNTUK DATA GOALS (Default Awal) ---
  double _tinggiBadanCm = 170.0; 
  String _jenisKelamin = 'Perempuan'; 
  // ---------------------------------------------
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LariPage()),
      );
    } 
  }

  // --- FUNGSI NAVIGASI UNTUK EDIT PROFILE (MENGIRIM DAN MENERIMA DATA) ---
  void _navigateToProfileEdit() async { // Menggunakan async
    // 1. Mengirim data profil saat ini ke halaman edit
    final result = await Navigator.push( // Menggunakan await
      context,
      MaterialPageRoute(
        builder: (context) => AccountProfileScreen(
          // Kirim data state saat ini sebagai nilai awal, termasuk path foto
          initialName: _userName,
          initialEmail: _userEmail,
          initialPhone: _userPhone,
          initialImagePath: _profileImagePath, // Mengirim path foto saat ini
        ), 
      ),
    );

    // 2. Memeriksa jika ada data yang dikembalikan (yaitu setelah tombol SIMPAN ditekan)
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // 3. Memperbarui state dengan data yang baru
        _userName = result['userName'] ?? _userName;
        _userEmail = result['userEmail'] ?? _userEmail;
        _userPhone = result['userPhone'] ?? _userPhone;
        // *MEMPERBARUI PATH FOTO*
        // Pastikan path foto diperbarui (bisa null jika dibatalkan)
        _profileImagePath = result['userProfilePath'] as String?;
      });
      
      // Simpan userName ke SharedPreferences
      _saveUserName(_userName);
    }
  }
  
  // Fungsi untuk menyimpan userName ke SharedPreferences
  Future<void> _saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_display_name', name);
  }
  // --------------------------------------------------------

  // --- FUNGSI PERHITUNGAN BERAT BADAN IDEAL (BBI) ---
  double _calculateIdealBodyWeight() {
    double bbi;
    
    double tbCm = _tinggiBadanCm;
    
    // Menggunakan Rumus Broca yang Disederhanakan
    if (_jenisKelamin == 'Pria') {
      bbi = (tbCm - 100) - (0.10 * (tbCm - 100));
    } else { // Perempuan
      bbi = (tbCm - 100) - (0.15 * (tbCm - 100));
    }

    // Mengembalikan BBI, dibulatkan ke bilangan bulat terdekat untuk tampilan
    return bbi.roundToDouble().clamp(40.0, 150.0);
  }

  double get _calculatedWeightTarget => _calculateIdealBodyWeight();

  // --- FUNGSI LOGOUT ---
  Future<void> _handleLogout() async {
    try {
      // Logout dari Google Sign-In jika sedang login dengan Google
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      
      // Logout dari Firebase Auth
      await FirebaseAuth.instance.signOut();
      
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat logout: $e')),
      );
    }
  }

  // --- LOGIKA NAVIGASI DENGAN MENUNGGU HASIL (SET GOALS) ---
  void _navigateToSetGoals() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AkunSetGoalsPage()),
    );

    // Memeriksa jika ada data yang dikembalikan (Map)
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        // Memperbarui state dengan data goals baru
        _tinggiBadanCm = result['tinggiBadan'] ?? _tinggiBadanCm;
        _jenisKelamin = result['jenisKelamin'] ?? _jenisKelamin;
        _weightAwal = result['beratAwal'] ?? _weightAwal;
      });
    }
  }

  // MARK: - Widget Pembantu

  // Helper function untuk menentukan ImageProvider
  ImageProvider _getProfileImage() {
    if (_profileImagePath != null) {
      // Jika path foto lokal tersedia, gunakan FileImage
      // FileImage membutuhkan import 'dart:io'
      return FileImage(File(_profileImagePath!));
    }
    // Jika tidak, gunakan asset placeholder default
    return const AssetImage('assets/icons/profile_placeholder.png');
  }


  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top; 

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView( 
        padding: const EdgeInsets.only(bottom: 80), 
        child: Column(
          children: [
            // BAGIAN 1: HEADER MERAH
            Container(
              height: 200, 
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE54721),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
              ),
              child: Stack(
                children: [
                  // Menu titik tiga di pojok kanan atas
                  Positioned(
                    top: topPadding + 8,
                    right: 16,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _handleLogout();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Color(0xFFE54721)),
                              SizedBox(width: 8),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Konten utama header
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: topPadding), 
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  // HAPUS 'const' di sini karena CircleAvatar di dalamnya dinamis
                                  CircleAvatar( 
                                    radius: 40, 
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 38, 
                                      // *MENGGUNAKAN FUNGSI BARU UNTUK MENAMPILKAN FOTO*
                                      // Fungsi ini non-const, jadi widget pembungkusnya juga tidak boleh const
                                      backgroundImage: _getProfileImage(),
                                    ),
                                  ),
                                  
                                  // ICON EDIT (PENSIL) - PANGGIL FUNGSI NAVIGASI ASYNC
                                  GestureDetector(
                                    onTap: _navigateToProfileEdit, 
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFE54721), width: 1.5),
                                      ),
                                      child: const Icon(Icons.edit, color: Color(0xFFE54721), size: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Tampilkan data profil terbaru
                              Text(
                                _userName, 
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _userEmail, 
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // BAGIAN 2: KONTEN UTAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, 10), 
                child: Column(
                  children: [
                    // Kartu Berat Badan (MENGGUNAKAN NILAI TARGET BBI)
                    _buildWeightCard(),
                    const SizedBox(height: 10), 

                    // Kartu Statistik Cepat
                    _buildQuickStats(),
                    const SizedBox(height: 30),

                    // Tombol Set Goals
                    _buildMenuButton(
                      title: 'Set Goals',
                      icon: Icons.track_changes,
                      onTap: _navigateToSetGoals,
                    ),
                    const SizedBox(height: 15),

                    // Tombol Riwayat Lari
                    _buildMenuButton(
                      title: 'Riwayat Lari',
                      icon: Icons.history,
                      onTap: () { 
                          Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AkunRiwayatLariPage()),
                        );
                       },
                    ),
                    const SizedBox(height: 15),

                    // Tombol Achievement Board
                    _buildMenuButton(
                      title: 'Achievement Board',
                      icon: Icons.emoji_events,
                      onTap: () { 
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AkunAchievementPage()),
                        );
                       },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30), 
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.run_circle), label: 'Lari'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFE54721),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  // MARK: - Widget Pembantu

  Widget _buildWeightCard() {
    // Menggunakan BBI yang dihitung sebagai target
    final double targetBBI = _calculatedWeightTarget;

    // Perhitungan progress
    final double totalRange = _weightAwal - targetBBI; 
    final double progressMade = _weightAwal - _weightSaatIni;
    double progressValue = totalRange > 0 ? (progressMade / totalRange).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      elevation: 4,
      color: const Color(0xFFE54721), 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'BERAT BADAN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), 
                ),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Image.asset(
                    'assets/icons/body_target.png',
                    height: 40,
                    color: Colors.white, 
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.accessibility_new, 
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: progressValue, 
              backgroundColor: Colors.white.withOpacity(0.5),
              color: Colors.white,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // MENGGUNAKAN _weightAwal DARI STATE
                _weightItem('Awal', '${_weightAwal.toInt()} kg', Colors.white), 
                // MENGGUNAKAN HASIL PERHITUNGAN BBI
                _weightItem('Target (BBI)', '${targetBBI.toInt()} kg', Colors.white), 
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weightItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: color.withOpacity(0.7))), 
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statCircle(Icons.access_time, '0j 50m', 'Total Waktu', Colors.orange),
        _statCircle(Icons.local_fire_department, '747 kal', 'Terbakar', Colors.red),
        _statCircle(Icons.fitness_center, '2 lari', 'Berhasil\ndilakukan', Colors.blue),
      ],
    );
  }

  Widget _statCircle(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFDEAE4),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFE54721), size: 30),
                  const SizedBox(width: 15),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
