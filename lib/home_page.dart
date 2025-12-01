import 'dart:math';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'lari_page.dart';
import 'akun_page.dart';
import 'state_sync.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _displayName = 'User';

  // === DATA HARIAN ===
  int _todaySteps = 0;
  int _targetSteps = 10000;
  double _todayDistance = 0.0;
  int _todayCalories = 0; // Total kalori (pasif + lari)
  int _todayPassiveSteps =
      0; // Langkah pasif saja (untuk kalkulasi kalori pasif)
  Map<String, int> _weeklySteps = {};

  // === VARIABEL SENSOR & DETEKSI LANGKAH ===
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _lastAccMagnitude = 0.0;
  bool _isPeakDetected = false;
  int _stepCooldown = 0;

  // Setting Sensitivitas & Kalori
  static const double STEP_THRESHOLD_MIN = 10.5;
  static const double STEP_THRESHOLD_MAX = 30.0;
  static const int STEP_COOLDOWN_SAMPLES = 8;
  static const double PASSIVE_CALORIES_PER_STEP =
      0.04; // Kalori realistis per langkah pasif

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
    _loadDailyData();
    _loadTargetSteps();
    _startPassiveStepTracking();
    // Initialize shared state and listen for external updates (runs/finished)
    AppState.refreshFromPrefs();
    AppState.todaySteps.addListener(_onTodayStepsChanged);
    AppState.todayDistance.addListener(_onTodayDistanceChanged);
    AppState.todayCalories.addListener(_onTodayCaloriesChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDailyData();
    _loadTargetSteps();
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    AppState.todaySteps.removeListener(_onTodayStepsChanged);
    AppState.todayDistance.removeListener(_onTodayDistanceChanged);
    AppState.todayCalories.removeListener(_onTodayCaloriesChanged);
    super.dispose();
  }

  void _onTodayStepsChanged() {
    if (!mounted) return;
    setState(() {
      _todaySteps = AppState.todaySteps.value;
    });
  }

  void _onTodayDistanceChanged() {
    if (!mounted) return;
    setState(() {
      _todayDistance = AppState.todayDistance.value;
    });
  }

  void _onTodayCaloriesChanged() {
    if (!mounted) return;
    setState(() {
      _todayCalories = AppState.todayCalories.value;
    });
  }

  void _startPassiveStepTracking() {
    _accelSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (_stepCooldown > 0) {
        _stepCooldown--;
      } else {
        if (magnitude > STEP_THRESHOLD_MIN &&
            magnitude < STEP_THRESHOLD_MAX &&
            magnitude > _lastAccMagnitude) {
          _isPeakDetected = true;
        }

        if (_isPeakDetected && magnitude < _lastAccMagnitude) {
          setState(() {
            _todaySteps++;
            _todayPassiveSteps++; // Tambah counter langkah pasif
            _todayDistance += 0.0007;

            // Hitung kalori pasif secara akurat
            int passiveCalories =
                (_todayPassiveSteps * PASSIVE_CALORIES_PER_STEP).round();

            // Total kalori = kalori pasif + kalori dari lari (sudah tersimpan)
            _todayCalories = passiveCalories;
          });

          _saveOneStep();

          _stepCooldown = STEP_COOLDOWN_SAMPLES;
          _isPeakDetected = false;
        }
      }
      _lastAccMagnitude = magnitude;
    });
  }

  Future<void> _saveOneStep() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Simpan langkah total dan langkah pasif terpisah
    await prefs.setInt('steps_$today', _todaySteps);
    await prefs.setInt('passive_steps_$today', _todayPassiveSteps);
    await prefs.setDouble('distance_$today', _todayDistance);

    // Hitung dan simpan total kalori
    int passiveCalories = (_todayPassiveSteps * PASSIVE_CALORIES_PER_STEP)
        .round();
    int runCalories =
        prefs.getInt('run_calories_$today') ?? 0; // Kalori dari lari
    int totalCalories = passiveCalories + runCalories;

    await prefs.setInt('calories_$today', totalCalories);

    print(
      '📊 Passive Step Saved: Total Steps=$_todaySteps, Passive Steps=$_todayPassiveSteps, Passive Cal=$passiveCalories, Run Cal=$runCalories, Total Cal=$totalCalories',
    );
  }

  Future<void> _loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_display_name');

    if (savedName != null && savedName.isNotEmpty) {
      setState(() => _displayName = savedName);
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _displayName =
              (user.displayName != null && user.displayName!.isNotEmpty)
              ? user.displayName!
              : (user.email ?? 'User');
        });
      }
    }
  }

  Future<void> _loadTargetSteps() async {
    final prefs = await SharedPreferences.getInstance();
    double savedTarget = prefs.getDouble('target_langkah') ?? 10000.0;

    setState(() {
      _targetSteps = savedTarget.toInt();
    });
  }

  Future<void> _loadDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    setState(() {
      _todaySteps = prefs.getInt('steps_$today') ?? 0;
      _todayPassiveSteps = prefs.getInt('passive_steps_$today') ?? 0;
      _todayDistance = prefs.getDouble('distance_$today') ?? 0.0;

      // Load total kalori (pasif + lari)
      _todayCalories = prefs.getInt('calories_$today') ?? 0;

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        _weeklySteps[dateStr] = prefs.getInt('steps_$dateStr') ?? 0;
      }
    });

    // Push loaded values to shared state so other pages update immediately
    AppState.todaySteps.value = _todaySteps;
    AppState.todayDistance.value = _todayDistance;
    AppState.todayCalories.value = _todayCalories;

    print(
      '📱 Data Loaded: Steps=$_todaySteps, Passive Steps=$_todayPassiveSteps, Total Calories=$_todayCalories',
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      _loadDailyData();
      _loadTargetSteps();
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LariPage()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AccountPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildHomePageContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.run_circle), label: 'Lari'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Akun'),
        ],
        currentIndex: 0,
        selectedItemColor: const Color(0xFFE54721),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomePageContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE54721),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
            ),
            padding: const EdgeInsets.only(top: 75, left: 24, right: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat pagi, $_displayName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ayo jalan! Langkahmu otomatis terhitung.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: Column(
              children: [
                _buildWeeklyProgress(),
                const SizedBox(height: 30),

                Row(
                  children: [
                    Image.asset(
                      'assets/icons/lari.png',
                      height: 150,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.directions_run,
                        size: 100,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TARGET\nLARI\nKAMU\nHARI INI!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE54721),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${NumberFormat('#,###', 'id_ID').format(_targetSteps)} langkah',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFFE54721),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildProgressBar(current: _todaySteps, target: _targetSteps),

                const SizedBox(height: 30),

                _buildStatsContainer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress Mingguan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (index) {
            final date = weekDates[index];
            final dateStr = DateFormat('yyyy-MM-dd').format(date);
            final steps = _weeklySteps[dateStr] ?? 0;
            final progress = _targetSteps > 0
                ? (steps / _targetSteps).clamp(0.0, 1.0)
                : 0.0;
            final isFuture = date.isAfter(
              DateTime(now.year, now.month, now.day),
            );
            final isToday =
                date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            return Column(
              children: [
                SizedBox(
                  width: 35,
                  height: 35,
                  child: CustomPaint(
                    painter: _ProgressCirclePainter(
                      progress: isFuture ? 0.0 : progress,
                      backgroundColor: Colors.grey[200]!,
                      progressColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.E('id_ID').format(date)[0].toUpperCase(),
                  style: TextStyle(
                    color: isToday ? Colors.orange : Colors.grey,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProgressBar({required int current, required int target}) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Pencapaian Langsung:",
              style: TextStyle(color: Colors.black54),
            ),
            Text(
              '${NumberFormat('#,###', 'id_ID').format(current)} / ${NumberFormat('#,###', 'id_ID').format(target)}',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          color: const Color(0xFFE54721),
          minHeight: 15,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  Widget _buildStatsContainer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE54721),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.directions_walk,
            NumberFormat('#,###', 'id_ID').format(_todaySteps),
            'Langkah',
          ),
          _buildStatItem(
            Icons.location_on,
            _todayDistance.toStringAsFixed(2),
            'Km',
          ),
          _buildStatItem(
            Icons.local_fire_department,
            _todayCalories.toString(),
            'Kalori',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
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
}

class _ProgressCirclePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressCirclePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      backgroundPaint,
    );

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width / 2,
        ),
        -0.5 * pi,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
