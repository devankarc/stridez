import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'lari_page.dart';
import 'akun_setgoals_page.dart'; 
import 'akun_riwayatlari_page.dart';
import 'akun_profile.dart'; 
import 'login_page.dart';
import 'akun_achivement.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedIndex = 2; 

  // --- DATA PROFILE ---
  String _userName = 'Pengguna';
  String _userEmail = 'user@email.com';
  String _userPhone = '-'; 
  String? _profileImagePath; 
  
  // --- DATA FISIK ---
  double _weightSaatIni = 60.0; 
  double _tinggiBadanCm = 170.0; 
  String _jenisKelamin = 'Pria'; 

  // --- STATISTIK LARI ---
  int _totalRuns = 0;
  int _totalCalories = 0;
  String _totalDurationFormatted = "0j 0m"; // Default

  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAllUserData(); 
  }

  // ==========================================
  // 1. FUNGSI LOAD SEMUA DATA
  // ==========================================
  Future<void> _loadAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      // A. Load Profil
      _userName = prefs.getString('user_display_name') ?? 'Pengguna';
      _userEmail = prefs.getString('user_email') ?? FirebaseAuth.instance.currentUser?.email ?? 'user@email.com';
      _userPhone = prefs.getString('user_phone') ?? '-';
      _profileImagePath = prefs.getString('user_profile_path');

      // B. Load Data Fisik
      _weightSaatIni = (prefs.getInt('user_weight') ?? 60).toDouble();
      _tinggiBadanCm = prefs.getDouble('user_height') ?? 170.0;
      _jenisKelamin = prefs.getString('user_gender') ?? 'Pria';

      // C. Hitung Statistik
      _calculateRunStats(prefs);
      
      _isLoading = false;
    });
  }

  // ==========================================
  // 2. HITUNG STATISTIK (DIPERBAIKI)
  // ==========================================
  void _calculateRunStats(SharedPreferences prefs) {
    // Mengambil list riwayat lari
    final String? runsJson = prefs.getString('run_history_data');
    
    if (runsJson != null) {
      List<dynamic> historyList = [];
      try {
        historyList = jsonDecode(runsJson);
      } catch (e) {
        print("Error decoding history: $e");
        historyList = [];
      }
      
      int totalCal = 0;
      int totalSeconds = 0;

      for (var item in historyList) {
        // 1. Hitung Kalori
        if (item['calories'] != null) {
          totalCal += (item['calories'] as num).toInt();
        }

        // 2. Hitung Durasi (Support MM:SS dan HH:MM:SS)
        String durationStr = item['duration'] ?? "00:00";
        List<String> parts = durationStr.split(':');
        
        int h = 0, m = 0, s = 0;
        if (parts.length == 3) {
          h = int.tryParse(parts[0]) ?? 0;
          m = int.tryParse(parts[1]) ?? 0;
          s = int.tryParse(parts[2]) ?? 0;
        } else if (parts.length == 2) {
          m = int.tryParse(parts[0]) ?? 0;
          s = int.tryParse(parts[1]) ?? 0;
        }
        totalSeconds += (h * 3600) + (m * 60) + s;
      }

      // 3. Format Tampilan Waktu
      int totalHours = totalSeconds ~/ 3600;
      int remainingMin = (totalSeconds % 3600) ~/ 60;
      
      String timeStr;
      if (totalSeconds > 0 && totalSeconds < 60) {
        timeStr = "< 1m"; // Jika kurang dari 1 menit
      } else {
        timeStr = "${totalHours}j ${remainingMin}m";
      }

      _totalRuns = historyList.length;
      _totalCalories = totalCal;
      _totalDurationFormatted = timeStr;
      
    } else {
      // Jika data kosong
      _totalRuns = 0;
      _totalCalories = 0;
      _totalDurationFormatted = "0j 0m";
    }
  }

  // ==========================================
  // 3. NAVIGASI EDIT PROFILE
  // ==========================================
  void _navigateToProfileEdit() async { 
    final result = await Navigator.push( 
      context,
      MaterialPageRoute(
        builder: (context) => AccountProfileScreen(
          initialName: _userName,
          initialEmail: _userEmail,
          initialPhone: _userPhone,
          initialImagePath: _profileImagePath, 
        ), 
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _userName = result['userName'] ?? _userName;
        _userEmail = result['userEmail'] ?? _userEmail;
        _userPhone = result['userPhone'] ?? _userPhone;
        _profileImagePath = result['userProfilePath'];
      });
      
      await prefs.setString('user_display_name', _userName);
      await prefs.setString('user_email', _userEmail);
      await prefs.setString('user_phone', _userPhone);
      if (_profileImagePath != null) {
        await prefs.setString('user_profile_path', _profileImagePath!);
      }
    }
  }

  // ==========================================
  // 4. NAVIGASI SET GOALS
  // ==========================================
  void _navigateToSetGoals() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AkunSetGoalsPage()),
    );
    // Refresh data saat kembali
    _loadAllUserData();
  }

  // ==========================================
  // 5. HELPER LOGIC
  // ==========================================
  double _calculateIdealBodyWeight() {
    double bbi;
    double tbCm = _tinggiBadanCm;
    
    if (_jenisKelamin == 'Pria') {
      bbi = (tbCm - 100) - (0.10 * (tbCm - 100));
    } else { 
      bbi = (tbCm - 100) - (0.15 * (tbCm - 100));
    }
    return bbi.roundToDouble().clamp(0.0, 200.0);
  }

  ImageProvider _getProfileImage() {
    if (_profileImagePath != null && File(_profileImagePath!).existsSync()) {
      return FileImage(File(_profileImagePath!));
    }
    return const AssetImage('assets/icons/profile_placeholder.png');
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });
    if (index == 0) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LariPage()));
    } 
  }

  Future<void> _handleLogout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top; 

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView( 
        padding: const EdgeInsets.only(bottom: 80), 
        child: Column(
          children: [
            // HEADER MERAH
            Container(
              height: 200, 
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE54721),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: topPadding + 8, right: 16,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 28),
                      onSelected: (value) { if (value == 'logout') _handleLogout(); },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(children: [Icon(Icons.logout, color: Color(0xFFE54721)), SizedBox(width: 8), Text('Logout')]),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: topPadding), 
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatar( 
                                    radius: 40, backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 38, 
                                      backgroundImage: _getProfileImage(),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _navigateToProfileEdit, 
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white, shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFE54721), width: 1.5),
                                      ),
                                      child: const Icon(Icons.edit, color: Color(0xFFE54721), size: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text(_userEmail, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // KONTEN UTAMA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, 10), 
                child: Column(
                  children: [
                    // Kartu Berat Badan
                    _buildWeightCard(),
                    const SizedBox(height: 10), 

                    // Kartu Statistik (Sudah Sinkron)
                    _buildQuickStats(),
                    const SizedBox(height: 30),

                    // Menu Buttons
                    _buildMenuButton(title: 'Set Goals', icon: Icons.track_changes, onTap: _navigateToSetGoals),
                    const SizedBox(height: 15),
                    _buildMenuButton(
                      title: 'Riwayat Lari', icon: Icons.history, 
                      onTap: () async {
                         await Navigator.push(context, MaterialPageRoute(builder: (context) => const AkunRiwayatLariPage()));
                         _loadAllUserData(); // Refresh saat kembali dari riwayat
                      }
                    ),
                    const SizedBox(height: 15),
                    _buildMenuButton(title: 'Achievement Board', icon: Icons.emoji_events, onTap: () { 
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const AkunAchievementPage()));
                    }),
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

  // --- WIDGET HELPER ---

  Widget _buildWeightCard() {
    double targetBBI = _calculateIdealBodyWeight();
    
    // Logic Progress Visual Sederhana
    double progress = 0.5; 
    if (_weightSaatIni > 0 && targetBBI > 0) {
        double diff = (_weightSaatIni - targetBBI).abs();
        if (diff < 3) progress = 0.95; // Sangat dekat
        else if (diff < 10) progress = 0.7;
        else progress = 0.4;
    }
    
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
                const Text('BERAT BADAN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(
                  height: 40, width: 40,
                  child: Image.asset(
                    'assets/icons/body_target.png', height: 40, color: Colors.white, 
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.accessibility_new, color: Colors.white, size: 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.white.withOpacity(0.5),
              color: Colors.white,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _weightItem('Saat Ini', '${_weightSaatIni.toInt()} kg', Colors.white), 
                _weightItem('Target Ideal', '${targetBBI.toInt()} kg', Colors.white), 
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
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // MENAMPILKAN DATA ASLI
        _statCircle(Icons.access_time, _totalDurationFormatted, 'Total Waktu', Colors.orange),
        _statCircle(Icons.local_fire_department, '$_totalCalories kal', 'Terbakar', Colors.red),
        _statCircle(Icons.fitness_center, '$_totalRuns lari', 'Berhasil\ndilakukan', Colors.blue),
      ],
    );
  }

  Widget _statCircle(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFFDEAE4), borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5, offset: const Offset(0, 3))],
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