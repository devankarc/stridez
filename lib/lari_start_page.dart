import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';

// Import lokal
import 'home_page.dart';
import 'lari_finish_page.dart';
import 'akun_page.dart';

// Custom painter untuk progress lingkaran
class TargetProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  
  TargetProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.1416,
      false,
      bgPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1416 / 2,
      2 * 3.1416 * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LariStartPage extends StatefulWidget {
  final bool isTargetJarak;
  final double targetJarak;
  final int targetWaktu;

  const LariStartPage({
    super.key,
    required this.isTargetJarak,
    required this.targetJarak,
    required this.targetWaktu,
  });

  @override
  State<LariStartPage> createState() => _LariStartPageState();
}

class _LariStartPageState extends State<LariStartPage> {
  // === STATE VARIABLES ===
  gmaps.LatLng? _currentLocation = const gmaps.LatLng(-7.2820, 112.7944);
  Position? _previousPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<gmaps.LatLng> _routePoints = [];

  // Variabel Tracking
  bool isPaused = false;
  Timer? _timer;
  double currentProgress = 0.0;
  double currentDistance = 0.0;
  int durationMinutes = 0;
  int durationSeconds = 0;
  int calories = 0;
  int totalSteps = 0;
  String? _currentAddress;
  bool _isLoading = true;

  // === SENSOR & ML VARIABLES ===
  StreamSubscription? _accelSubscription;
  StreamSubscription? _gyroSubscription;
  
  // Buffer untuk windowing (analisis aktivitas)
  final List<double> _accelMagnitudeBuffer = [];
  final List<double> _gyroMagnitudeBuffer = [];
  final int _windowSize = 30; // 30 samples (~1 detik)
  
  // Deteksi aktivitas
  String _detectedActivity = 'IDLE';
  double _activityConfidence = 0.0;
  
  // Deteksi langkah
  double _lastAccMagnitude = 0.0;
  int _stepCooldown = 0;
  bool _isPeakDetected = false;

  // === THRESHOLDS (TUNED) ===
  static const double IDLE_ACCEL_THRESHOLD = 1.5;
  static const double WALKING_ACCEL_THRESHOLD = 3.5;
  static const double RUNNING_ACCEL_THRESHOLD = 3.5;
  
  static const double STEP_THRESHOLD_MIN = 12.0;
  static const double STEP_THRESHOLD_MAX = 25.0;
  static const int STEP_COOLDOWN_SAMPLES = 10; // ~0.3 detik

  // --- GETTERS DAN HELPER ---
  bool get isTanpaTarget => widget.targetJarak == 0 && widget.targetWaktu == 0;

  String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, d MMMM', 'id_ID').format(now);
  }

  String _formatDuration(int minutes, int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  // --- FUNGSI PENYIMPANAN DATA ---
  Future<void> _saveDailyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Ambil data existing
      int existingSteps = prefs.getInt('steps_$today') ?? 0;
      double existingDistance = prefs.getDouble('distance_$today') ?? 0.0;
      int existingCalories = prefs.getInt('calories_$today') ?? 0;
      int existingDuration = prefs.getInt('duration_$today') ?? 0;
      
      // Tambahkan data sesi ini
      await prefs.setInt('steps_$today', existingSteps + totalSteps);
      await prefs.setDouble('distance_$today', existingDistance + currentDistance);
      await prefs.setInt('calories_$today', existingCalories + calories);
      await prefs.setInt('duration_$today', existingDuration + (durationMinutes * 60 + durationSeconds));
      
      print('✅ Data tersimpan: Steps=$totalSteps, Distance=${currentDistance.toStringAsFixed(2)}km, Calories=$calories');
    } catch (e) {
      print('❌ Error menyimpan data: $e');
    }
  }

  // === DETEKSI AKTIVITAS DENGAN ML ===
  void _classifyActivity() {
    if (_accelMagnitudeBuffer.length < _windowSize) return;
    
    // Hitung statistik
    double accelMean = _calculateMean(_accelMagnitudeBuffer);
    double accelStdDev = sqrt(_calculateVariance(_accelMagnitudeBuffer, accelMean));
    
    double gyroMean = _gyroMagnitudeBuffer.isNotEmpty 
        ? _calculateMean(_gyroMagnitudeBuffer) 
        : 0.0;
    
    // Decision Tree Classification
    String newActivity;
    double newConfidence;
    
    if (accelStdDev < IDLE_ACCEL_THRESHOLD && gyroMean < 0.5) {
      newActivity = 'IDLE';
      newConfidence = 0.95;
    } else if (accelStdDev >= RUNNING_ACCEL_THRESHOLD && gyroMean > 1.0) {
      newActivity = 'RUNNING';
      newConfidence = 0.90;
    } else if (accelStdDev >= IDLE_ACCEL_THRESHOLD) {
      newActivity = 'WALKING';
      newConfidence = 0.85;
    } else {
      newActivity = 'IDLE';
      newConfidence = 0.70;
    }
    
    // Update hanya jika berubah
    if (newActivity != _detectedActivity) {
      setState(() {
        _detectedActivity = newActivity;
        _activityConfidence = newConfidence;
      });
      print('🏃 Activity: $newActivity (${(newConfidence * 100).toStringAsFixed(0)}%) - StdDev: ${accelStdDev.toStringAsFixed(2)}');
    }
  }

  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _calculateVariance(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;
    return values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
  }

  // === DETEKSI LANGKAH (PEAK DETECTION) ===
  void _detectStep(double magnitude) {
    // Cooldown untuk mencegah double detection
    if (_stepCooldown > 0) {
      _stepCooldown--;
      return;
    }
    
    // Deteksi peak (naik lalu turun)
    if (magnitude > STEP_THRESHOLD_MIN && 
        magnitude < STEP_THRESHOLD_MAX &&
        _lastAccMagnitude < magnitude) {
      _isPeakDetected = true;
    }
    
    // Deteksi valley (turun setelah peak)
    if (_isPeakDetected && magnitude < _lastAccMagnitude) {
      // Hanya hitung jika sedang bergerak
      if (_detectedActivity == 'RUNNING' || _detectedActivity == 'WALKING') {
        setState(() {
          totalSteps++;
        });
        _stepCooldown = STEP_COOLDOWN_SAMPLES;
        print('👟 Step detected! Total: $totalSteps');
      }
      _isPeakDetected = false;
    }
    
    _lastAccMagnitude = magnitude;
  }

  // === UPDATE KALORI ===
  void _updateCalories() {
    // Rumus: 0.04 kcal per step OR 60 kcal per km (ambil yang lebih besar)
    const double caloriesPerStep = 0.04;
    const double caloriesPerKm = 60.0;
    
    int caloriesFromSteps = (totalSteps * caloriesPerStep).round();
    int caloriesFromDistance = (currentDistance * caloriesPerKm).round();
    
    setState(() {
      calories = caloriesFromSteps > caloriesFromDistance 
          ? caloriesFromSteps 
          : caloriesFromDistance;
    });
  }

  // === TIMER LOGIC ===
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update HANYA saat bergerak (running/walking) dan tidak di-pause
      if (!isPaused &&
          (_detectedActivity == 'RUNNING' || _detectedActivity == 'WALKING')) {
        setState(() {
          // Update durasi
          if (durationSeconds < 59) {
            durationSeconds++;
          } else {
            durationSeconds = 0;
            durationMinutes++;
          }

          // Update kalori
          _updateCalories();

          // Update progress
          if (widget.isTargetJarak) {
            currentProgress = widget.targetJarak == 0
                ? 0
                : (currentDistance / widget.targetJarak);
          } else {
            currentProgress = widget.targetWaktu == 0
                ? 0
                : ((durationMinutes * 60 + durationSeconds) /
                    (widget.targetWaktu * 60));
          }

          currentProgress = currentProgress.clamp(0.0, 1.0);
        });
      }
    });
  }

  // === INISIALISASI SENSOR ===
  void _startSensorListening() {
    // Accelerometer
    _accelSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (isPaused) return;
      
      // Hitung magnitude
      double magnitude = sqrt(
        event.x * event.x + 
        event.y * event.y + 
        event.z * event.z
      );
      
      // Tambah ke buffer
      _accelMagnitudeBuffer.add(magnitude);
      if (_accelMagnitudeBuffer.length > _windowSize) {
        _accelMagnitudeBuffer.removeAt(0);
      }
      
      // Deteksi langkah
      _detectStep(magnitude);
      
      // Klasifikasi aktivitas setiap buffer penuh
      if (_accelMagnitudeBuffer.length == _windowSize) {
        _classifyActivity();
      }
    });

    // Gyroscope
    _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (isPaused) return;
      
      double magnitude = sqrt(
        event.x * event.x + 
        event.y * event.y + 
        event.z * event.z
      );
      
      _gyroMagnitudeBuffer.add(magnitude);
      if (_gyroMagnitudeBuffer.length > _windowSize) {
        _gyroMagnitudeBuffer.removeAt(0);
      }
    });
  }

  // === GPS TRACKING ===
  void _startPositionStream() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5, // Update setiap 5 meter
      ),
    ).listen((Position position) {
      if (!mounted) return;

      setState(() {
        gmaps.LatLng newPoint = gmaps.LatLng(position.latitude, position.longitude);
        _currentLocation = newPoint;
        _isLoading = false;

        // Rekam rute HANYA saat bergerak
        if (!isPaused &&
            (_detectedActivity == 'RUNNING' || _detectedActivity == 'WALKING')) {
          _routePoints.add(newPoint);

          // Hitung jarak
          if (_previousPosition != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              _previousPosition!.latitude,
              _previousPosition!.longitude,
              position.latitude,
              position.longitude,
            );

            // Filter noise (max 100m per update)
            if (distanceInMeters > 0 && distanceInMeters < 100) {
              currentDistance += distanceInMeters / 1000;
            }
          }
        }
        
        _previousPosition = position;
      });

      _updateAddressFromLocation();
    });
  }

  Future<void> _updateAddressFromLocation() async {
    if (_currentLocation == null ||
        (_currentLocation!.latitude == -7.2820 &&
            _currentLocation!.longitude == 112.7944)) {
      if (_currentAddress == null || _currentAddress!.isEmpty) {
        setState(() {
          _currentAddress = "Mencari lokasi...";
        });
      }
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _currentAddress = [
            if (p.name != null && p.name!.isNotEmpty) p.name,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
            if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
              p.administrativeArea,
          ].whereType<String>().where((e) => e.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  // === LIFECYCLE ===
  @override
  void initState() {
    super.initState();
    _updateAddressFromLocation();
    _startPositionStream();
    _startTimer();
    _startSensorListening();
    
    print('🚀 Lari Start Page initialized');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }

  // === WIDGETS ===
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine icon & color based on activity
    IconData activityIcon;
    Color activityColor;
    
    switch (_detectedActivity) {
      case 'RUNNING':
        activityIcon = Icons.directions_run;
        activityColor = Colors.red;
        break;
      case 'WALKING':
        activityIcon = Icons.directions_walk;
        activityColor = Colors.green;
        break;
      default:
        activityIcon = Icons.pause;
        activityColor = Colors.grey;
    }

    return Scaffold(
      body: Stack(
        children: [
          // === GOOGLE MAP ===
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentLocation!,
              zoom: 17.0,
            ),
            markers: {
              if (_currentLocation != null)
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('currentLocation'),
                  position: _currentLocation!,
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueBlue,
                  ),
                ),
            },
            polylines: {
              gmaps.Polyline(
                polylineId: const gmaps.PolylineId('runRoute'),
                points: _routePoints,
                color: const Color(0xFFE54721),
                width: 5,
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // === LOADING OVERLAY ===
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Mencari lokasi Anda..."),
                  ],
                ),
              ),
            ),

          // === HEADER ===
          Positioned(
            top: 40,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LARI',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.black87, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _currentAddress ?? 'Lokasi tidak terdeteksi',
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Activity Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activityColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(activityIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '$_detectedActivity (${(_activityConfidence * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // === PROGRESS CIRCLE ===
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: TargetProgressPainter(
                        progress: currentProgress,
                        color: const Color(0xFFE54721),
                        strokeWidth: 18,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (widget.isTargetJarak || isTanpaTarget)
                              ? '${currentDistance.toStringAsFixed(2)} Km'
                              : _formatDuration(durationMinutes, durationSeconds),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (!isTanpaTarget) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.isTargetJarak
                                ? '${widget.targetJarak.toStringAsFixed(1)} Km'
                                : '${widget.targetWaktu} Min',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Target Harian',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === STATS INFO ===
          Positioned(
            bottom: 140,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: widget.isTargetJarak ? Icons.timer : Icons.directions_run,
                    label: widget.isTargetJarak ? 'DURASI' : 'JARAK',
                    value: widget.isTargetJarak
                        ? _formatDuration(durationMinutes, durationSeconds)
                        : '${currentDistance.toStringAsFixed(2)} Km',
                  ),
                  _buildStatItem(
                    icon: Icons.directions_walk,
                    label: 'LANGKAH',
                    value: totalSteps.toString(),
                  ),
                  _buildStatItem(
                    icon: Icons.local_fire_department,
                    label: 'KALORI',
                    value: calories.toString(),
                  ),
                ],
              ),
            ),
          ),

          // === CONTROL BUTTONS ===
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause/Resume Button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isPaused = !isPaused;
                      if (isPaused) {
                        print('⏸️ Paused');
                      } else {
                        print('▶️ Resumed');
                      }
                    });
                  },
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE54721), width: 7),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isPaused ? 'LANJUT' : 'JEDA',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE54721),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                // Finish Button
                GestureDetector(
                  onTap: () async {
                    _timer?.cancel();
                    
                    // Simpan data
                    await _saveDailyData();
                    
                    print('🏁 Finish: Distance=${currentDistance.toStringAsFixed(2)}km, Steps=$totalSteps, Calories=$calories');

                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => LariFinishPage(
                          routePoints: _routePoints,
                          distance: currentDistance,
                          durationMinutes: durationMinutes,
                          durationSeconds: durationSeconds,
                          calories: calories,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE54721),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'FINISH',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Helper widget untuk stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.deepOrange, size: 20),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}