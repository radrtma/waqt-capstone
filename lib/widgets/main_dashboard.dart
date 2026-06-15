import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'greeting_section.dart';
import 'prayer_card.dart';
import 'date_information.dart';
import 'prayer_tracker.dart';
import '../services/community_service.dart';

class MainDashboard extends StatelessWidget {
  final Map<String, bool> prayerStates;
  final Function(String) onToggle;
  final Map<String, dynamic> timings;
  final String userName;
  final Map<String, dynamic> dateInfo;
  final DateTime currentTime;
  final bool Function(String) isPrayerTimeReached;
  final bool Function(String) isPrayerMissed;
  final List<Map<String, dynamic>> missedPrayers;
  final int streakCount;
  final bool isFrozen;
  final Function(int, String) onQadaComplete;
  final Function(int) onTabChanged;

  const MainDashboard({
    super.key,
    required this.userName,
    required this.prayerStates,
    required this.onToggle,
    required this.timings,
    required this.dateInfo,
    required this.currentTime,
    required this.isPrayerTimeReached,
    required this.isPrayerMissed,
    required this.missedPrayers,
    required this.streakCount,
    required this.isFrozen,
    required this.onQadaComplete,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 260), // Overlap slightly
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF5E9DA), // Cream background for content
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GreetingSection(
              userName: userName,
              missedPrayers: missedPrayers,
              streakCount: streakCount,
              isFrozen: isFrozen,
              onQadaComplete: onQadaComplete,
            ),
            const SizedBox(height: 32),
            PrayerCard(
              prayerName: _getNextPrayerName(),
              prayerTime: timings[_getNextPrayerName()] ?? '--:--',
              nextPrayerInfo: 'Next Prayer (${_getNextPrayerName()}) In',
              nextPrayerCountdown: _getCountdown(_getNextPrayerName()),
            ),
            const SizedBox(height: 20),
            DateInformation(
              gDate: dateInfo['gregorian']['date'] ?? '',
              hDate: '${dateInfo['hijri']['day']} ${dateInfo['hijri']['month']['en']} ${dateInfo['hijri']['year']} H',
            ),
            const SizedBox(height: 24),
            PrayerTracker(
              prayerStates: prayerStates,
              onToggle: onToggle,
              isPrayerTimeReached: isPrayerTimeReached,
              isPrayerMissed: isPrayerMissed,
            ),
            const SizedBox(height: 32),
            HighlightKomunitasWidget(onTabChanged: onTabChanged),
            const SizedBox(height: 24),
            const RenunganHarianWidget(),
            const SizedBox(height: 24),
            const MasjidRekomendasiWidget(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getCountdown(String prayerName) {
    if (timings[prayerName] == null) return '--:--:--';
    final parts = timings[prayerName].split(':');
    final prayerTime = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    var diff = prayerTime.difference(currentTime);
    if (diff.isNegative) {
      diff = prayerTime.add(const Duration(days: 1)).difference(currentTime);
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')} : ${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}';
  }

  String _getNextPrayerName() {
    final prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
    for (var name in prayerNames) {
      if (!isPrayerTimeReached(name)) return name;
    }
    return 'Fajr';
  }
}

// Sub-widgets

class HighlightKomunitasWidget extends StatefulWidget {
  final Function(int) onTabChanged;
  const HighlightKomunitasWidget({super.key, required this.onTabChanged});

  @override
  State<HighlightKomunitasWidget> createState() => _HighlightKomunitasWidgetState();
}

class _HighlightKomunitasWidgetState extends State<HighlightKomunitasWidget> {
  final CommunityService _communityService = CommunityService();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    try {
      final posts = await _communityService.fetchPosts();
      if (mounted) {
        setState(() {
          _posts = posts.take(2).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F6F5B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Highlight Komunitas',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () => widget.onTabChanged(1), // Switch to Community Tab
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Lihat Semua →',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2),
            ),
          )
        else if (_posts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Center(
              child: Text(
                'Belum ada postingan komunitas.',
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          )
        else
          Column(
            children: _posts.map((post) {
              final String username = post['username'] ?? 'Anonymous';
              final String content = post['content'] ?? '';
              final String postType = post['post_type'] ?? 'reflection';
              String typeLabel = 'Refleksi';
              if (postType == 'mosque') typeLabel = 'Masjid';
              if (postType == 'event') typeLabel = 'Event';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '@$username',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class RenunganHarianWidget extends StatefulWidget {
  const RenunganHarianWidget({super.key});

  @override
  State<RenunganHarianWidget> createState() => _RenunganHarianWidgetState();
}

class _RenunganHarianWidgetState extends State<RenunganHarianWidget> {
  late Map<String, String> _selectedRenungan;

  final List<Map<String, String>> _renunganList = [
    {
      'quote': '“Perumpamaan orang yang membaca Al-Qur\'an dan mengamalkannya bagaikan buah utrujah, rasanya lezat dan baunya harum.”',
      'source': '— HR. Bukhari & Muslim'
    },
    {
      'quote': '“Senyummu di hadapan saudaramu adalah sedekah bagimu.”',
      'source': '— HR. Tirmidzi'
    },
    {
      'quote': '“Barangsiapa yang menempuh suatu jalan untuk menuntut ilmu, maka Allah SWT akan memudahkan baginya jalan menuju surga.”',
      'source': '— HR. Muslim'
    },
    {
      'quote': '“Kekayaan (yang hakiki) bukanlah dengan banyaknya harta benda. Namun kekayaan (yang hakiki) adalah hati yang selalu merasa cukup.”',
      'source': '— HR. Bukhari & Muslim'
    }
  ];

  @override
  void initState() {
    super.initState();
    final random = Random();
    _selectedRenungan = _renunganList[random.nextInt(_renunganList.length)];
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F6F5B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📖 Renungan Harian',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 6),
          Text(
            _selectedRenungan['quote']!,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              _selectedRenungan['source']!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MasjidRekomendasiWidget extends StatelessWidget {
  const MasjidRekomendasiWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F6F5B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🕌 Rekomendasi Masjid',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 8),
          
          // Masjid 1
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masjid Raya Al-Azhar',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '9.2 km · AC Berfungsi & Ramah Jamaah',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade50),
          const SizedBox(height: 8),

          // Masjid 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masjid Istiqlal Jakarta',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '12.4 km · Tempat Wudhu Bersih & Luas',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
