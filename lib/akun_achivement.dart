import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AkunAchievementPage extends StatefulWidget {
  const AkunAchievementPage({super.key});

  @override
  State<AkunAchievementPage> createState() => _AkunAchievementPageState();
}

class _AkunAchievementPageState extends State<AkunAchievementPage> {
  // Data target dari SharedPreferences
  double _targetLangkah = 8000;
  double _targetJarak = 25;
  double _targetDurasi = 60;
  bool _hasSetGoals = false; // Flag untuk cek apakah sudah set goals
  
  // Data progress saat ini (nanti bisa diambil dari database lari)
  final double _currentLangkah = 5000;
  final double _currentJarak = 25;
  final double _currentDurasi = 60;

  bool get _isLangkahAchieved => _currentLangkah >= _targetLangkah;
  bool get _isJarakAchieved => _currentJarak >= _targetJarak;
  bool get _isDurasiAchieved => _currentDurasi >= _targetDurasi;
  bool get _allAchieved => _isLangkahAchieved && _isJarakAchieved && _isDurasiAchieved;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil tanggal terakhir setting goals
    final lastSetDate = prefs.getString('goals_set_date');
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';
    
    setState(() {
      // Cek apakah sudah set goals DAN apakah setting hari ini
      _hasSetGoals = prefs.containsKey('target_langkah') && lastSetDate == todayString;
      
      if (_hasSetGoals) {
        _targetLangkah = prefs.getDouble('target_langkah') ?? 8000;
        _targetJarak = prefs.getDouble('target_jarak') ?? 25;
        _targetDurasi = prefs.getDouble('target_durasi') ?? 60;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header dengan background orange (bisa di-scroll)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE54721),
                ),
                child: Column(
                  children: [
                    // AppBar custom - simple row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Image.asset(
                            'assets/icons/logo_kecil.png',
                            height: 50,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                'Stridez',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Garis putih di bawah header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    // Trophy icon dan title
                    const SizedBox(height: 10),
                    Image.asset(
                      'assets/icons/Trophy.png',
                      height: 60,
                      width: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 60,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ACHIEVEMENT BOARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                  // Cek apakah sudah set goals atau belum
                  if (!_hasSetGoals) ...[
                    // Pesan jika belum set goals
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Anda belum membuat target untuk hari ini 😢',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                  // Achievement Cards (tampil jika sudah set goals)
                  _buildAchievementCard(
                    imagePath: 'assets/icons/langkah_kecil.png', // Ganti dengan path gambar Anda
                    title: 'Langkah',
                    value: '${_targetLangkah.toInt()} langkah',
                    isAchieved: _isLangkahAchieved,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildAchievementCard(
                    imagePath: 'assets/icons/lari_logo.png', // Ganti dengan path gambar Anda
                    title: 'Jarak Lari',
                    value: '${_targetJarak.toInt()} km',
                    isAchieved: _isJarakAchieved,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildAchievementCard(
                    imagePath: 'assets/icons/durasi_logo.png', // Ganti dengan path gambar Anda
                    title: 'Durasi',
                    value: '${_targetDurasi.toInt()} menit',
                    isAchieved: _isDurasiAchieved,
                  ),
                  
                  // Congratulations banner
                  if (_allAchieved) ...[
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE54721),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // Decorative elements
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildConfetti('assets/icons/Party_Popper.png'),
                              _buildConfetti('assets/icons/Confetti_Ball.png'),
                              _buildConfetti('assets/icons/Ribbon.png'),
                              _buildConfetti('assets/icons/Confetti_Ball.png'),
                              _buildConfetti('assets/icons/Party_Popper.png'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'SELAMAT!!!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'ANDA TELAH MENYELESAIKAN\nSEMUA GOALS ANDA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          // Decorative elements bottom
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildConfetti('assets/icons/Party_Popper.png'),
                              _buildConfetti('assets/icons/Confetti_Ball.png'),
                              _buildConfetti('assets/icons/Ribbon.png'),
                              _buildConfetti('assets/icons/Confetti_Ball.png'),
                              _buildConfetti('assets/icons/Party_Popper.png'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ], // Closing for if (_allAchieved)
                  ], // Closing for else (achievements cards)
                ], // Closing for inner Column children (achievement cards + banner)
              ), // Closing for Padding's child (Column)
            ), // Closing for Padding
          ], // Closing for outer Column children (header + content)
        ), // Closing for SingleChildScrollView child (Column)
      ), // Closing for SafeArea child (SingleChildScrollView)
    ), // Closing for Scaffold body (SafeArea)
  );
}

  Widget _buildAchievementCard({
    required String imagePath,
    required String title,
    required String value,
    required bool isAchieved,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isAchieved ? Colors.green : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE54721).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                // Fallback ke icon jika gambar tidak ditemukan
                return const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFE54721),
                  size: 32,
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Check icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAchieved ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAchieved ? Icons.check : Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfetti(String imagePath) {
    return Image.asset(
      imagePath,
      width: 32,
      height: 32,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.celebration,
          color: Colors.white,
          size: 32,
        );
      },
    );
  }
}
