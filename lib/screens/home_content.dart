import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/hero_header.dart';
import '../widgets/main_dashboard.dart';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';

class HomeContent extends StatefulWidget {
  final Map<String, bool> prayerStates;
  final Function(String, bool) onPrayerToggle;
  final int streakCount;
  final bool isFrozen;
  final String userName;
  final Set<String> qadaCompleted;
  final List<Map<String, dynamic>> missedPrayers;
  final Function(int, String) onQadaComplete;
  final Function(String) onPrayerMissed;
  final Function(int) onTabChanged;

  const HomeContent({
    super.key,
    required this.userName,
    required this.prayerStates,
    required this.onPrayerToggle,
    required this.streakCount,
    required this.isFrozen,
    required this.qadaCompleted,
    required this.missedPrayers,
    required this.onQadaComplete,
    required this.onPrayerMissed,
    required this.onTabChanged,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PrayerService _prayerService = PrayerService();
  Map<String, dynamic>? _timings;
  Map<String, dynamic>? _dateInfo;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _now = DateTime.now();
  Timer? _timer;
  final Set<String> _notifiedMissed = {}; // Track which prayers already triggered freeze

  @override
  void initState() {
    super.initState();
    _fetchPrayerData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  Future<void> _fetchPrayerData() async {
    try {
      final data = await _prayerService.getPrayerTimings();
      setState(() {
        _timings = data['timings'];
        _dateInfo = data['date'];
        _isLoading = false;
      });
      if (_timings != null) {
        await NotificationService().schedulePrayerNotifications(_timings!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isPrayerTimeReached(String prayerName) {
    if (_timings == null) return false;
    final timeStr = _timings![prayerName];
    if (timeStr == null) return false;

    final parts = timeStr.split(':');
    final prayerTime = DateTime(
      _now.year,
      _now.month,
      _now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    return _now.isAfter(prayerTime);
  }

  bool _isPrayerMissed(String prayerName) {
    if (_timings == null ||
        widget.prayerStates[prayerName] == true ||
        widget.qadaCompleted.contains(prayerName))
      return false;

    final prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
    int currentIndex = prayerNames.indexOf(prayerName);

    String nextPrayerName;
    bool isNextDay = false;

    if (currentIndex < prayerNames.length - 1) {
      nextPrayerName = prayerNames[currentIndex + 1];
    } else {
      nextPrayerName = 'Fajr';
      isNextDay = true;
    }

    final timeStr = _timings![nextPrayerName];
    if (timeStr == null) return false;

    final parts = timeStr.split(':');
    DateTime endTime = DateTime(
      _now.year,
      _now.month,
      _now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (isNextDay) {
      endTime = endTime.add(const Duration(days: 1));
    }

    final isMissed = _now.isAfter(endTime);
    
    // Trigger freeze in real-time when a prayer is first detected as missed
    if (isMissed && !_notifiedMissed.contains(prayerName)) {
      _notifiedMissed.add(prayerName);
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onPrayerMissed(prayerName);
      });
    }
    
    return isMissed;
  }

  void _togglePrayer(String label) {
    // Pencegahan unclick
    if (widget.prayerStates[label] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sholat sudah selesai, tidak bisa dibatalkan.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isPrayerTimeReached(label)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belum masuk waktu $label.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    widget.onPrayerToggle(label, true); // Update melalui callback ke parent
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1F6F5B)),
      );
    }

    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              // Top Mosque Image Section
              const HeroHeader(),
              // Bottom Content Section starting with a white card
              MainDashboard(
                userName: widget.userName,
                prayerStates: widget.prayerStates,
                onToggle: _togglePrayer,
                timings: _timings ?? {},
                dateInfo: _dateInfo ?? {},
                currentTime: _now,
                isPrayerTimeReached: _isPrayerTimeReached,
                isPrayerMissed: _isPrayerMissed,
                missedPrayers: widget.missedPrayers, // Gunakan data dari Database
                streakCount: widget.streakCount,
                isFrozen: widget.isFrozen,
                onQadaComplete: widget.onQadaComplete,
                onTabChanged: widget.onTabChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
