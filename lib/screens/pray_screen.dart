import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/prayer_service.dart';
import '../services/notification_service.dart';

class PrayScreen extends StatefulWidget {
  const PrayScreen({super.key});

  @override
  State<PrayScreen> createState() => _PrayScreenState();
}

class _PrayScreenState extends State<PrayScreen> {
  Map<String, dynamic>? _timings;
  bool _isLoading = true;
  String? _error;
  Timer? _timer;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadMuteStatus();
    _fetchPrayerTimes();
    // Refresh UI every minute to update "Next Prayer" highlight
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadMuteStatus() async {
    final status = await NotificationService().isAdzanMuted();
    if (mounted) {
      setState(() {
        _isMuted = status;
      });
    }
  }

  Future<void> _toggleMute() async {
    final newStatus = !_isMuted;
    await NotificationService().setAdzanMuted(newStatus);
    if (mounted) {
      setState(() {
        _isMuted = newStatus;
      });
    }

    // Reschedule notifications to apply mute/unmute
    if (_timings != null) {
      await NotificationService().schedulePrayerNotifications(_timings!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPrayerTimes() async {
    try {
      final prayerService = PrayerService();
      // getPrayerTimings now defaults to Jakarta, Indonesia
      final data = await prayerService.getPrayerTimings();
      
      if (mounted) {
        setState(() {
          _timings = data['timings'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection error. Please check your internet.';
          _isLoading = false;
        });
      }
    }
  }

  String _getActivePrayer() {
    if (_timings == null) return '';
    final now = DateTime.now();
    final format = DateFormat("HH:mm");

    final prayers = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
    String active = 'Isha'; // Default to Isha (before Fajr, previous night's Isha is still active)
    
    for (var prayer in prayers) {
      final timeStr = _timings![prayer];
      final prayerTime = format.parse(timeStr);
      final todayPrayer = DateTime(now.year, now.month, now.day, prayerTime.hour, prayerTime.minute);
      
      if (now.isAfter(todayPrayer) || now.isAtSameMomentAs(todayPrayer)) {
        active = prayer;
      } else {
        break;
      }
    }
    return active;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E9DA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchPrayerTimes,
          color: const Color(0xFF1F6F5B),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 100),
                          child: CircularProgressIndicator(color: Color(0xFF1F6F5B)),
                        ),
                      )
                    else if (_error != null)
                      _buildErrorState()
                    else
                      _buildPrayerList(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal Sholat',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F6F5B),
                  ),
                ),
                Text(
                  'Jakarta, Indonesia',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _toggleMute,
                  icon: Icon(
                    _isMuted
                        ? Icons.notifications_off_rounded
                        : Icons.notifications_active_rounded,
                    color: const Color(0xFF1F6F5B),
                    size: 28,
                  ),
                  tooltip: _isMuted ? 'Aktifkan Suara Adzan' : 'Bisukan Adzan',
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F6F5B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFF1F6F5B),
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: const Color(0xFF6B6B6B)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchPrayerTimes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6F5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerList() {
    final activePrayer = _getActivePrayer();
    final prayers = [
      {'label': 'Fajr', 'icon': Icons.wb_twilight_rounded},
      {'label': 'Dzuhur', 'icon': Icons.wb_sunny_rounded},
      {'label': 'Ashar', 'icon': Icons.wb_cloudy_rounded},
      {'label': 'Maghrib', 'icon': Icons.nights_stay_rounded},
      {'label': 'Isha', 'icon': Icons.bedtime_rounded},
    ];

    return Column(
      children: prayers.map((p) {
        final isActive = p['label'] == activePrayer;
        return _buildPrayerItem(
          p['label'] as String,
          _timings![p['label']] ?? '--:--',
          p['icon'] as IconData,
          isActive,
        );
      }).toList(),
    );
  }

  Widget _buildPrayerItem(String label, String time, IconData icon, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1F6F5B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isActive ? Border.all(color: const Color(0xFFF2C94C).withValues(alpha: 0.2), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          if (isActive)
            BoxShadow(
              color: const Color(0xFFF2C94C).withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 0),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF2C94C).withValues(alpha: 0.15) : const Color(0xFFF5E9DA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFFF2C94C) : const Color(0xFF1F6F5B),
              size: 24,
              shadows: isActive ? [Shadow(color: const Color(0xFFF2C94C).withValues(alpha: 0.3), blurRadius: 10)] : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFFF2C94C) : const Color(0xFF1F6F5B),
                    shadows: isActive ? [Shadow(color: const Color(0xFFF2C94C).withValues(alpha: 0.2), blurRadius: 8)] : null,
                  ),
                ),
                if (isActive)
                  Text(
                    'Aktif Sekarang',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFF2C94C).withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFFF2C94C) : const Color(0xFF1F6F5B),
              shadows: isActive ? [Shadow(color: const Color(0xFFF2C94C).withValues(alpha: 0.2), blurRadius: 8)] : null,
            ),
          ),
        ],
      ),
    );
  }
}
