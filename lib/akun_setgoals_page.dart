import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Asumsi class AccountPage ada di sini jika file akun_page.dart tidak disertakan


class AkunSetGoalsPage extends StatefulWidget {
  const AkunSetGoalsPage({super.key});

  @override
  State<AkunSetGoalsPage> createState() => _AkunSetGoalsPageState();
}

class _AkunSetGoalsPageState extends State<AkunSetGoalsPage> {
  // === STATE VARIABLES ===
  String _jenisKelamin = 'Pria';
  double _tinggiBadan = 170; // cm
  int _beratBadan = 78; // kg (Ini adalah Berat Badan Awal / Saat Ini)
  int _usia = 25;
  
  // Goals Lari (tidak dikembalikan, hanya untuk kepentingan halaman ini)
  double _langkahTarget = 8000; // steps
  double _jarakTarget = 25; // km
  double _durasiTarget = 60; // menit

  // === WIDGET PEMBANGUN UI KECIL ===

  // Warna dan Konstanta Desain
  static const Color primaryColor = Color.fromARGB(255, 233, 77, 38);
  static const Color secondaryBoxColor = Color.fromARGB(255, 255, 230, 220);
  static const Color darkTextColor = Color.fromARGB(255, 140, 70, 50);

  // 1. Tombol Pria/Wanita
  Widget _buildGenderButton(String gender) {
    bool isSelected = _jenisKelamin == gender;
    const unselectedColor = Color.fromARGB(255, 248, 226, 217); 
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _jenisKelamin = gender;
          });
        },
        child: Container(
          height: 100, 
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : unselectedColor,
            borderRadius: BorderRadius.circular(15),
            border: isSelected ? null : Border.all(color: Colors.black12, width: 1), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                gender == 'Pria' ? Icons.male : Icons.female,
                color: isSelected ? Colors.white : primaryColor, 
                size: 35,
              ),
              const SizedBox(height: 8),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected ? Colors.white : darkTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Kontrol Angka (Berat Badan, Usia)
  Widget _buildNumberControl({
    required String title,
    required String unit,
    required int value,
    required ValueChanged<int> onIncrement,
    required ValueChanged<int> onDecrement,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 248, 226, 217).withOpacity(0.8), 
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3), 
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: darkTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$value $unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onDecrement(value > 1 ? value : 1), 
                      child: const Icon(Icons.remove_circle_outline, color: primaryColor),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onIncrement(value),
                      child: const Icon(Icons.add_circle_outline, color: primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Chip untuk level kesulitan
  Widget _buildLevelChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: (bgColor == Colors.transparent) ? textColor.withOpacity(0.5) : bgColor,
        )
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  // WIDGET UTAMA: Kotak Goal Fleksibel (Menggunakan Image.asset untuk semua ikon)
  Widget _buildGoalBox({
    required String title,
    required String subtitle,
    required String unit,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String assetPath, // Selalu gunakan assetPath
    required String level1,
    required String level2,
    required String level3,
  }) {
    double levelValue = (max - min) / 3;
    
    double localValue = value;
    
    // Tentukan nilai active level
    String getActiveLevel() {
      if (localValue < min + levelValue) return level1;
      if (localValue < max - levelValue * 0.5) return level2;
      return level3;
    }

    Color getLevelColor(String level) {
      if (getActiveLevel() == level) return primaryColor;
      return Colors.transparent;
    }
    
    Color getLevelTextColor(String level) {
      if (getActiveLevel() == level) return Colors.white;
      return darkTextColor;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: secondaryBoxColor, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Kiri: Ikon + Judul
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gunakan Icon sebagai fallback jika assets tidak ada
                  Image.asset(
                    assetPath, 
                    height: 35,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.star, // Ikon fallback
                      color: primaryColor,
                      size: 35,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: primaryColor,
                          height: 1.0, 
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: primaryColor, 
                          height: 1.0, 
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Kanan: Nilai Target
              Text(
                '${localValue.toInt()} $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: primaryColor,
                ),
              ),
            ],
          ),

          // Slider
          Slider(
            value: localValue,
            min: min,
            max: max,
            divisions: (max - min).toInt() * 2,
            activeColor: primaryColor,
            inactiveColor: primaryColor.withOpacity(0.3),
            onChanged: onChanged,
          ),
          
          // Chips Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLevelChip(level1, getLevelColor(level1), getLevelTextColor(level1)),
              _buildLevelChip(level2, getLevelColor(level2), getLevelTextColor(level2)),
              _buildLevelChip(level3, getLevelColor(level3), getLevelTextColor(level3)),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }


  // Widget untuk kotak SET GOALS (tidak berubah)
  Widget _buildSetGoalsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4), 
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.menu, 
            color: primaryColor, 
            size: 30,
          ),
          SizedBox(width: 23),
          Text(
            'SET GOALS',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: primaryColor, 
              fontWeight: FontWeight.bold,
              fontSize: 24, 
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk kotak Jenis Kelamin (tidak berubah)
  Widget _buildJenisKelaminBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: secondaryBoxColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: const Text(
        'Jenis Kelamin',
        style: TextStyle(
          color: darkTextColor, 
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
  
  // WIDGET KONTROL TINGGI BADAN (tidak berubah)
  Widget _buildHeightControl() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: secondaryBoxColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Judul "Tinggi Badan"
              const Text(
                'Tinggi Badan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: darkTextColor,
                ),
              ),
              // Nilai Tinggi Badan dan Unit (di pojok kanan atas)
              Text(
                '${_tinggiBadan.round()} cm',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          // Slider
          Slider(
            value: _tinggiBadan,
            min: 140,
            max: 210,
            divisions: 70,
            activeColor: primaryColor,
            inactiveColor: primaryColor.withOpacity(0.3), 
            onChanged: (double newValue) {
              setState(() {
                _tinggiBadan = newValue.roundToDouble();
              });
            },
          ),
        ],
      ),
    );
  }


  // WIDGET KONTEN HEADER (tidak berubah)
  Widget _buildScrollableHeader(BuildContext context) {
    const headerDarkTextColor = Color.fromARGB(255, 50, 50, 50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 35), 
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: headerDarkTextColor, size: 30),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Spacer(),
              Image.asset(
                'assets/icons/logo_kecil.png', 
                height: 50, 
                errorBuilder: (context, error, stackTrace) => const Text('Logo', style: TextStyle(color: headerDarkTextColor)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4.0), 
            child: Divider(color: Colors.black38, thickness: 1, height: 1), 
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const primaryBackgroundColor = Color.fromARGB(255, 241, 114, 64); 
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 162, 130), 
      
      body: SingleChildScrollView(
        child: Container(
          color: primaryBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16.0), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. KONTEN HEADER YANG BISA DI-SCROLL
              _buildScrollableHeader(context), 
              
              // Jarak ke Kotak Set Goals
              const SizedBox(height: 20.0), 
              
              // 2. KOTAK SET GOALS
              _buildSetGoalsBox(),
              
              const SizedBox(height: 16), 
              
              // 3. KOTAK JENIS KELAMIN
              _buildJenisKelaminBox(),

              const SizedBox(height: 10), 
              
              // 4. PILIHAN GENDER
              Row(
                children: [
                  _buildGenderButton('Pria'),
                  _buildGenderButton('Wanita'),
                ],
              ),
              
              // === TINGGI BADAN ===
              const SizedBox(height: 16),
              _buildHeightControl(),
              
              // === BERAT BADAN & USIA (Berat Badan ini adalah BB Awal/Saat Ini) ===
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildNumberControl(
                    title: 'Berat Badan',
                    unit: 'kg',
                    value: _beratBadan,
                    onIncrement: (val) => setState(() => _beratBadan++),
                    onDecrement: (val) => setState(() => _beratBadan = (val > 1) ? val - 1 : 1),
                  ),
                  _buildNumberControl(
                    title: 'Usia',
                    unit: '',
                    value: _usia,
                    onIncrement: (val) => setState(() => _usia++),
                    onDecrement: (val) => setState(() => _usia = (val > 1) ? val - 1 : 1),
                  ),
                ],
              ),
              
              // === 5. LANGKAH PER HARI ===
              const SizedBox(height: 16),
              _buildGoalBox(
                title: 'Langkah',
                subtitle: 'per hari',
                unit: 'Steps',
                value: _langkahTarget,
                min: 3000,
                max: 15000,
                onChanged: (newValue) => setState(() => _langkahTarget = newValue.roundToDouble()),
                assetPath: 'assets/icons/langkah_kecil.png',
                level1: 'Pemula',
                level2: 'Sedang',
                level3: 'Atlet',
              ),

              // === 6. JARAK LARI PER HARI ===
              _buildGoalBox(
                title: 'Jarak Lari',
                subtitle: 'per hari',
                unit: 'KM',
                value: _jarakTarget,
                min: 1,
                max: 42,
                onChanged: (newValue) => setState(() => _jarakTarget = newValue.roundToDouble()),
                assetPath: 'assets/icons/lari_logo.png',
                level1: 'Pemula',
                level2: 'Sedang',
                level3: 'Atlet',
              ),

              // === 7. DURASI PER HARI ===
              _buildGoalBox(
                title: 'Durasi',
                subtitle: 'per hari',
                unit: 'Menit',
                value: _durasiTarget,
                min: 15,
                max: 120,
                onChanged: (newValue) => setState(() => _durasiTarget = newValue.roundToDouble()),
                assetPath: 'assets/icons/durasi_logo.png', 
                level1: 'Pemula',
                level2: 'Sedang',
                level3: 'Atlet',
              ),
              const SizedBox(height: 20),
              
              // === TOMBOL SIMPAN (LOGIKA BARU) ===
              Container(
                width: double.infinity,
                height: 55,
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                child: ElevatedButton(
                  onPressed: () async {
                    // Simpan goals ke SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setDouble('target_langkah', _langkahTarget);
                    await prefs.setDouble('target_jarak', _jarakTarget);
                    await prefs.setDouble('target_durasi', _durasiTarget);
                    
                    // Simpan tanggal setting goals hari ini
                    final today = DateTime.now();
                    final todayString = '${today.year}-${today.month}-${today.day}';
                    await prefs.setString('goals_set_date', todayString);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sasaran disimpan!')),
                      );
                      
                      // --- LOGIKA MENGEMBALIKAN DATA PENTING KE ACCOUNT PAGE ---
                      Navigator.pop(
                          context,
                          {
                            'tinggiBadan': _tinggiBadan,
                            'jenisKelamin': _jenisKelamin,
                            'beratAwal': _beratBadan.toDouble(),
                          }
                      );
                    }
                    // =========================================================
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
