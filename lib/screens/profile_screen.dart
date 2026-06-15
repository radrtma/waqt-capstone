import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import 'community_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final Function(String) onNameChanged;
  final VoidCallback onLogout;
  final Function(int) onTabChanged;

  const ProfileScreen({
    super.key,
    required this.userName,
    required this.onNameChanged,
    required this.onLogout,
    required this.onTabChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedAdzan = 'bilal';
  String _selectedCity = 'Jakarta';
  String _selectedCountry = 'Indonesia';
  String _memberSince = '...';
  String? _profileImagePath;
  bool _isMuted = false;

  final Map<String, String> _cityOptions = {
    'Jakarta': 'Indonesia',
    'Bandung': 'Indonesia',
    'Surabaya': 'Indonesia',
    'Semarang': 'Indonesia',
    'Medan': 'Indonesia',
    'Makassar': 'Indonesia',
    'Yogyakarta': 'Indonesia',
    'Palembang': 'Indonesia',
    'Denpasar': 'Indonesia',
    'Kuala Lumpur': 'Malaysia',
    'Mecca': 'Saudi Arabia',
    'London': 'United Kingdom',
  };

  final Map<String, String> _adzanOptions = {
    'bilal': 'Adzan Bilal',
    'rcti': 'Adzan RCTI',
    'rost_1': 'Adzan Rost 1',
    'rost_2': 'Adzan Rost 2',
    'upinipin': 'Adzan Upin Ipin',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Member Since logic
    String? storedDate = prefs.getString('member_since');
    if (storedDate == null) {
      storedDate = DateFormat('MMMM yyyy').format(DateTime.now());
      await prefs.setString('member_since', storedDate);
    }
    setState(() {
      _isMuted = prefs.getBool('mute_adzan') ?? false;
      _selectedAdzan = prefs.getString('selected_adzan') ?? 'bilal';
      _selectedCity = prefs.getString('selected_city') ?? 'Jakarta';
      _selectedCountry = prefs.getString('selected_country') ?? 'Indonesia';
      _memberSince = storedDate!;
      _profileImagePath = prefs.getString('profile_image_path');
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', image.path);
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E9DA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'About WAQT',
          style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF1F6F5B)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque_rounded, size: 48, color: Color(0xFF1F6F5B)),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0+1',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1F6F5B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Raffi and Ridhwan project prayer app for fullfill CCIT project assignment',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.inter(color: const Color(0xFF1F6F5B))),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdzanSelectionDialog(BuildContext context) async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E9DA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Adzan',
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF1F6F5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _adzanOptions.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value, style: GoogleFonts.inter()),
              value: entry.key,
              groupValue: _selectedAdzan,
              activeColor: const Color(0xFF1F6F5B),
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null && selected != _selectedAdzan) {
      await NotificationService().setSelectedAdzan(selected);
      setState(() {
        _selectedAdzan = selected;
      });
      // Reschedule notifications with new sound
      final prayerService = PrayerService();
      try {
        final result = await prayerService.getPrayerTimings();
        final timings = result['timings'] as Map<String, dynamic>;
        await NotificationService().schedulePrayerNotifications(timings);
      } catch (e) {
        debugPrint('Failed to reschedule notifications: $e');
      }
    }
  }

  Future<void> _toggleMute(bool value) async {
    await NotificationService().setAdzanMuted(value);
    setState(() {
      _isMuted = value;
    });

    // Reschedule notifications to apply mute/unmute
    final prayerService = PrayerService();
    try {
      final result = await prayerService.getPrayerTimings();
      final timings = result['timings'] as Map<String, dynamic>;
      await NotificationService().schedulePrayerNotifications(timings);
    } catch (e) {
      debugPrint('Failed to reschedule notifications after mute: $e');
    }
  }

  Future<void> _testAdzanNotification() async {
    final adzanName = _adzanOptions[_selectedAdzan] ?? 'Adzan';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mengirim test notifikasi $adzanName...')),
    );
    await NotificationService().showNotification(
      id: 999,
      title: 'Test $adzanName Tiba!',
      body: 'Ini adalah uji coba suara $adzanName.',
      useAdzanChannel: true,
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E9DA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Name',
          style: GoogleFonts.dmSerifDisplay(
            color: const Color(0xFF1F6F5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1F6F5B)),
            ),
          ),
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.onNameChanged(controller.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6F5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5E9DA),
          title: Text(
            'Pilih Kota',
            style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF1F6F5B)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300, // Limit height to allow scrolling
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _cityOptions.length,
              itemBuilder: (context, index) {
                final city = _cityOptions.keys.elementAt(index);
                final country = _cityOptions[city]!;
                return ListTile(
                  title: Text(city, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1F6F5B))),
                  subtitle: Text(country, style: GoogleFonts.inter(fontSize: 12)),
                  trailing: (_selectedCity == city) ? const Icon(Icons.check_circle, color: Color(0xFF1F6F5B)) : null,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('selected_city', city);
                    await prefs.setString('selected_country', country);
                    if (mounted) {
                      setState(() {
                        _selectedCity = city;
                        _selectedCountry = country;
                      });
                    }
                    // Clear cache because location changed
                    await PrayerService().clearCache();
                    if (context.mounted) Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup', style: GoogleFonts.inter(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E9DA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                _buildProfileCard(context),
                const SizedBox(height: 24),
                _buildSettingsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F6F5B),
          ),
        ),
        Text(
          'Manage your account and preferences',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF6B6B6B),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1F6F5B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF2C94C).withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F6F5B).withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow( // Gold Glow
            color: const Color(0xFFF2C94C).withValues(alpha: 0.15),
            blurRadius: 50,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF2C94C), width: 2), // Gold border
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFF2C94C).withValues(alpha: 0.3), blurRadius: 15),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFF5E9DA),
                    backgroundImage: _profileImagePath != null 
                        ? FileImage(File(_profileImagePath!)) 
                        : null,
                    child: _profileImagePath == null
                        ? const Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: Color(0xFF1F6F5B),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C94C), // Gold camera button
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFF2C94C).withValues(alpha: 0.4), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF1F6F5B),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.userName,
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF2C94C),
                  shadows: [Shadow(color: const Color(0xFFF2C94C).withValues(alpha: 0.3), blurRadius: 10)],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showEditNameDialog(context),
                icon: const Icon(Icons.edit_rounded, size: 20),
                color: const Color(0xFFF2C94C),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          Text(
            'Anggota sejak $_memberSince',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: [
        _buildSettingsItem(
          Icons.notifications_active_rounded,
          'Notifikasi',
          'Adzan: ${_adzanOptions[_selectedAdzan]}',
          onTap: () => _showAdzanSelectionDialog(context),
        ),
        _buildSettingsItem(
          _isMuted ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
          'Bisukan Adzan',
          _isMuted ? 'Suara adzan dimatikan' : 'Suara adzan aktif',
          trailing: Switch(
            value: _isMuted,
            onChanged: _toggleMute,
            activeColor: const Color(0xFFF2C94C),
            activeTrackColor: const Color(0xFF1F6F5B).withOpacity(0.5),
          ),
        ),
        _buildSettingsItem(
          Icons.volume_up_rounded,
          'Test Suara Adzan',
          'Coba mainkan notifikasi Adzan sekarang',
          onTap: _testAdzanNotification,
        ),
        _buildSettingsItem(
          Icons.location_on_rounded,
          'Lokasi',
          '$_selectedCity, $_selectedCountry',
          onTap: () => _showLocationDialog(context),
        ),
        _buildSettingsItem(
          Icons.forum_rounded,
          'Kelola Kiriman Saya',
          'Lihat, edit, atau hapus kiriman komunitas Anda',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunityScreen(
                  currentUsername: widget.userName,
                  showOnlyOwnPosts: true,
                ),
              ),
            );
          },
        ),
        _buildSettingsItem(
          Icons.info_rounded,
          'Tentang WAQT',
          'Versi 1.0.0+1',
          onTap: () => _showAboutDialog(context),
        ),
        _buildSettingsItem(
          Icons.logout_rounded,
          'Keluar Akun',
          'Keluar dari sesi saat ini',
          onTap: widget.onLogout,
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle,
      {VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F6F5B), // Deep Green Box
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFF2C94C).withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: const Color(0xFFF2C94C), size: 24, shadows: [
                Shadow(
                    color: const Color(0xFFF2C94C).withValues(alpha: 0.4),
                    blurRadius: 8)
              ]), // Glowing Gold Icon
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1F6F5B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
