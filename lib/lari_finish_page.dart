import 'package:flutter/material.dart';
// HAPUS: import 'package:latlong2/latlong.dart'; 
import 'home_page.dart';
import 'akun_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class LariFinishPage extends StatelessWidget {
  // Tipe data sudah gmaps.LatLng
  final List<gmaps.LatLng> routePoints; 
  final double distance;
  final int durationMinutes;
  final int durationSeconds;
  final int calories;

  const LariFinishPage({
    super.key,
    required this.routePoints, 
    required this.distance,
    required this.durationMinutes,
    required this.durationSeconds,
    required this.calories,
  });

  // MARK: - LOGIC REAL-TIME TIME OF DAY

  /// Menentukan label waktu (Pagi, Siang, Sore, Malam) berdasarkan jam saat ini.
  String _getRunTimeOfDay() {
    final int hour = DateTime.now().hour;

    if (hour >= 5 && hour <= 10) {
      return 'Pagi'; // Jam 05:00 - 10:59
    } else if (hour >= 11 && hour <= 14) {
      return 'Siang'; // Jam 11:00 - 14:59
    } else if (hour >= 15 && hour <= 18) {
      return 'Sore'; // Jam 15:00 - 18:59
    } else {
      return 'Malam'; // Jam 19:00 - 04:59
    }
  }

  // MARK: - GET START AND END POINTS

  // Titik Awal Lari
  gmaps.LatLng? get _startPoint => routePoints.isNotEmpty ? routePoints.first : null;
  // Titik Akhir Lari
  gmaps.LatLng? get _endPoint => routePoints.isNotEmpty ? routePoints.last : null;
  
  // Lokasi default jika rute kosong
  static const gmaps.LatLng _defaultLocation = gmaps.LatLng(-7.2820, 112.7944);

  // MARK: - CALCULATE PACE (min/km)
  String _calculatePace() {
    if (distance <= 0) return '0:00';
    
    // Total waktu dalam menit
    final double totalMinutes = durationMinutes + (durationSeconds / 60);
    
    // Pace = total menit / jarak (km)
    final double paceValue = totalMinutes / distance;
    
    // Konversi ke format menit:detik
    final int paceMinutes = paceValue.floor();
    final int paceSeconds = ((paceValue - paceMinutes) * 60).round();
    
    return '${paceMinutes.toString()}:${paceSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final String runTimeLabel = _getRunTimeOfDay();
    
    // Tentukan titik yang akan digunakan untuk memusatkan kamera
    final gmaps.LatLng cameraTarget = _startPoint ?? _defaultLocation;


    return Scaffold(
      body: Stack(
        children: [
          // Map with route polyline and markers
          gmaps.GoogleMap(
            // Target peta awal harus berupa gmaps.LatLng
            initialCameraPosition: gmaps.CameraPosition(
              target: cameraTarget,
              zoom: 17.0,
            ),
            markers: {
              if (_startPoint != null)
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('startPoint'),
                  position: _startPoint!, // Tipe sudah gmaps.LatLng
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
                ),
              if (_endPoint != null)
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('endPoint'),
                  position: _endPoint!, // Tipe sudah gmaps.LatLng
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
                ),
            },
            polylines: {
              gmaps.Polyline(
                polylineId: const gmaps.PolylineId('runRoute'),
                points: routePoints, // List<gmaps.LatLng> sudah benar
                color: const Color(0xFFE54721),
                width: 5,
              ),
            },
            
            // =======================================================
            // PETA SEKARANG SEPENUHNYA INTERAKTIF (Semua Gesture Aktif)
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true, 
            scrollGesturesEnabled: true, 
            tiltGesturesEnabled: true, // Aktifkan gesture miring
            rotateGesturesEnabled: true, // Aktifkan gesture putar
            // =======================================================
            
          ),
          
          // Header & summary
          Positioned(
            top: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_run, color: Color(0xFFE54721), size: 35),
                    const SizedBox(width: 8),
                    // MENGGUNAKAN LABEL WAKTU DINAMIS
                    Text(
                      'Lari $runTimeLabel', 
                      style: const TextStyle(
                        fontSize: 30, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFFE54721)
                      )
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  // Format jarak dengan koma sebagai pemisah desimal
                  distance.toStringAsFixed(2).replaceAll('.', ','),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFE54721)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kilometer',
                  style: TextStyle(fontSize: 43, fontWeight: FontWeight.bold, color: Color(0xFFE54721)),
                ),
              ],
            ),
          ),
          // Info panel
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Durasi
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Color(0xFFE54721), size: 28),
                      const SizedBox(width: 8),
                      const Text('DURASI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(width: 12),
                      Text(
                        '${durationMinutes.toString().padLeft(2, '0')} : ${durationSeconds.toString().padLeft(2, '0')} min',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Kalori
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Color(0xFFE54721), size: 28),
                      const SizedBox(width: 8),
                      const Text('KALORI', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(width: 12),
                      Text(
                        '$calories Kcal',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Pace
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFFE54721), size: 28),
                      const SizedBox(width: 8),
                      const Text('PACE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      const SizedBox(width: 12),
                      Text(
                        '${_calculatePace()} min/km',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.run_circle), label: 'Lari'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
        currentIndex: 1,
        selectedItemColor: const Color(0xFFE54721),
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AccountPage()),
            );
          }
        },
      ),
    );
  }
}
