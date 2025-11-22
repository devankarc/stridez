import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:intl/date_symbol_data_local.dart'; 

// --- MODEL DATA DUMMY (Disesuaikan untuk menggunakan DateTime) ---
class RunRecord {
  final DateTime dateTime; 
  final double distance;
  final String duration;
  final String pace;
  final String location;
  final bool isFavorite;
  final int calories;

  RunRecord({
    required this.dateTime,
    required this.distance,
    required this.duration,
    required this.pace,
    required this.location,
    this.isFavorite = false,
    required this.calories,
  });
  
  // Getter untuk tampilan tanggal (misal: 'Hari Ini', 'Kemarin', 'Sabtu, 12 September')
  String get dateDisplay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (recordDate.isAtSameMomentAs(today)) {
      return 'Hari Ini';
    } else if (recordDate.isAtSameMomentAs(yesterday)) {
      return 'Kemarin';
    } else {
      // Menggunakan DateFormat('EEEE, d MMMM') dengan locale 'id_ID'
      return DateFormat('EEEE, d MMMM', 'id_ID').format(dateTime); 
    }
  }

  // Getter untuk tampilan waktu
  String get timeDisplay {
    return DateFormat('HH:mm').format(dateTime) + ' WIB';
  }
}

// --- CLASS UNTUK MENAMPUNG HASIL PERHITUNGAN TOTAL ---
class TotalStats {
  final int totalRuns;
  final double totalDistance;
  final Duration totalDuration;
  
  TotalStats(this.totalRuns, this.totalDistance, this.totalDuration);

  // Helper untuk mengubah Duration menjadi format HH:MM
  String get totalDurationFormatted {
    final totalSeconds = totalDuration.inSeconds;
    final minutes = (totalSeconds / 60).truncate();
    final hours = (minutes / 60).truncate();
    final remainingMinutes = minutes % 60;
    
    // Format menjadi HH:MM
    return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}';
  }
}

class AkunRiwayatLariPage extends StatefulWidget {
  const AkunRiwayatLariPage({super.key});

  @override
  State<AkunRiwayatLariPage> createState() => _AkunRiwayatLariPageState();
}

class _AkunRiwayatLariPageState extends State<AkunRiwayatLariPage> {
  String _selectedFilter = 'Semua'; 
  
  final DateTime _today = DateTime.now();

  final List<RunRecord> _allRunHistory = [
    RunRecord(
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      distance: 5.2,
      duration: '28:15',
      pace: '5:26',
      location: 'Taman Bungkul - Surabaya',
      isFavorite: true,
      calories: 435,
    ),
    RunRecord(
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      distance: 3.8,
      duration: '22:30',
      pace: '5:55',
      location: 'Ciputra Waterpark - Surabaya',
      isFavorite: false,
      calories: 312,
    ),
    RunRecord(
      dateTime: DateTime.now().subtract(const Duration(days: 10, hours: 2)), 
      distance: 10.0,
      duration: '50:10',
      pace: '5:01',
      location: 'Perumahan Darmo - Surabaya',
      isFavorite: true,
      calories: 780,
    ),
    RunRecord(
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
      distance: 2.5,
      duration: '15:00',
      pace: '6:00',
      location: 'Keliling Komplek',
      isFavorite: false,
      calories: 150,
    ),
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  // --- LOGIKA FILTERING ---

  List<RunRecord> get _filteredRunHistory {
    if (_selectedFilter == 'Semua') {
      return _allRunHistory;
    }

    final now = _today;
    
    if (_selectedFilter == 'Minggu Ini') {
      final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      return _allRunHistory.where((record) {
        final recordDate = DateTime(record.dateTime.year, record.dateTime.month, record.dateTime.day);
        return recordDate.isAfter(start.subtract(const Duration(milliseconds: 1))) && 
               recordDate.isBefore(_today.add(const Duration(days: 1)));
      }).toList();
    }

    if (_selectedFilter == 'Bulan Ini') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      
      return _allRunHistory.where((record) {
        return record.dateTime.isAfter(startOfMonth.subtract(const Duration(milliseconds: 1))) && 
               record.dateTime.isBefore(nextMonth);
      }).toList();
    }

    return _allRunHistory; 
  }
  
  // --- LOGIKA PERHITUNGAN TOTAL STATISTIK ---
  TotalStats get _totalStats {
    final list = _filteredRunHistory;
    
    final totalRuns = list.length;
    final totalDistance = list.fold<double>(0.0, (sum, item) => sum + item.distance);
    
    Duration totalDuration = Duration.zero;
    for (var record in list) {
      final parts = record.duration.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        totalDuration += Duration(minutes: minutes, seconds: seconds);
      } else if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        totalDuration += Duration(hours: hours, minutes: minutes, seconds: seconds);
      }
    }
    
    return TotalStats(totalRuns, totalDistance, totalDuration);
  }


  // --- WIDGET PEMBANGUN UI KECIL ---

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    const Color primaryOrange = Color(0xFFE54721);
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        child: Container(
          height: 45, 
          margin: const EdgeInsets.symmetric(horizontal: 4), 
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primaryOrange : Colors.white,
            borderRadius: BorderRadius.circular(30), 
            border: isSelected 
                ? null 
                : Border.all(color: primaryOrange, width: 2), 
            boxShadow: [
              BoxShadow(
                color: isSelected ? primaryOrange.withOpacity(0.3) : Colors.transparent,
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRunCard(RunRecord record) {
    const Color primaryOrange = Color(0xFFE54721);
    double kmFontSize = record.distance >= 10.0 ? 28.0 : 32.0; 

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: primaryOrange.withOpacity(0.2), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.dateDisplay, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      record.timeDisplay, 
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItemNew(
                  record.distance.toStringAsFixed(1), 'KM', 
                  kmFontSize 
                ),
                _buildMetricItemNew(record.duration, 'WAKTU'),
                _buildMetricItemNew(record.pace, 'PACE'),
              ],
            ),
            
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.location,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          record.isFavorite 
                              ? 'Rute favorit • ${record.calories} kalori terbakar'
                              : 'Rute baru • ${record.calories} kalori terbakar',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
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
    );
  }

  Widget _buildMetricItemNew(String value, String unit, [double valueFontSize = 32.0]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1, 
          ),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTotalStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  // WIDGET HEADER (Tombol More Dihapus di sini)
  Widget _buildHeaderSesuaiDesain(double topPadding) {
    final stats = _totalStats; 
    const Color primaryOrange = Color(0xFFE54721);
    const Color statBoxColor = Color.fromRGBO(255, 255, 255, 0.2); 
    
    return Container(
      color: primaryOrange, 
      padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              // HILANGKAN WIDGET INI: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              // Karena hanya ada satu ikon (back), kita perlu menambahkan Spacer/SizedBox
              // agar judul Riwayat Lari tetap di sebelah kiri.
              const SizedBox(width: 30), // Mengganti ikon more_vert dengan spasi
            ],
          ),
          
          const SizedBox(height: 10),
          const Text(
            'Riwayat Lari',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Total Aktivitas Lari Anda',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            decoration: BoxDecoration(
              color: statBoxColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalStatItem(stats.totalRuns.toString(), 'Total Lari'),
                
                Column(
                  children: [
                    Text(
                      stats.totalDistance.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Km',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                
                _buildTotalStatItem(stats.totalDurationFormatted, 'Jam'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER ORANYE (REAL-TIME) ===
            _buildHeaderSesuaiDesain(topPadding),

            // === FILTER CHIP TERPISAH ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFilterChip('Semua'),
                  _buildFilterChip('Minggu Ini'),
                  _buildFilterChip('Bulan Ini'),
                ],
              ),
            ),

            // === DAFTAR RIWAYAT LARI (DIFILTER) ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredRunHistory.length, 
                itemBuilder: (context, index) {
                  return _buildRunCard(_filteredRunHistory[index]); 
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
