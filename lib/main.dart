import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'widgets/bottom_navbar.dart';
import 'screens/home_content.dart';
import 'screens/community_screen.dart';
import 'screens/pray_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/prayer_service.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WaqtApp());
}

class WaqtApp extends StatelessWidget {
  const WaqtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WAQT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6F5B),
          background: const Color(0xFFF5E9DA),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final token = await AuthService().getSavedToken();
    setState(() {
      _isLoggedIn = token != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E9DA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1F6F5B)),
        ),
      );
    }

    if (_isLoggedIn!) {
      return HomeScreen(
        onLogout: () {
          setState(() {
            _isLoggedIn = false;
          });
        },
      );
    } else {
      return LoginScreen(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      );
    }
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Global State
  int _streakCount = 0;
  bool _isFrozen = false;
  String _userName = 'User';
  List<Map<String, dynamic>> _qadaList = [];
  Map<String, bool> _prayerStates = {
    'Fajr': false,
    'Dzuhur': false,
    'Ashar': false,
    'Maghrib': false,
    'Isha': false,
  };
  final Map<String, Map<String, bool>> _historyData = {};
  final Set<String> _qadaCompleted = {};
  String _lastUpdateDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final DatabaseService _db = DatabaseService();
  final PrayerService _prayerService = PrayerService();

  bool _isLoading = true; // Mencegah race condition UI

  @override
  void initState() {
    super.initState();
    _loadDataFromDatabase();
    _initNotifications();
    // Check for day change every minute
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _checkDayChange();
      }
    });
  }

  Future<void> _loadDataFromDatabase() async {
    // 1. Load User Profile
    final name = await _db.getUsername();

    // 2. Load Streak Data
    final streak = await _db.getStreak();

    // 3. Load History & Qada
    final history = await _db.getAllHistory();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // --- OFFLINE DAY CHANGE CHECK ---
    int currentStreak = streak['count'];
    bool currentFrozen = streak['is_frozen'] == 1;
    String dbLastUpdate = streak['last_updated_date'] ?? '';

    if (dbLastUpdate.isNotEmpty && dbLastUpdate != today) {
      final unpaidQadaOffline = await _db.getQadaEntries();
      if (unpaidQadaOffline.isNotEmpty) {
        currentStreak = 0;
        currentFrozen = false; // Freeze reset after extinguished
        await _db.deleteAllUncompletedQada();
        NotificationService().showStreakResetAlert();
        debugPrint('OfflineDayChange: Streak EXTINGUISHED.');
      } else {
        currentStreak++;
        debugPrint('OfflineDayChange: Streak incremented to $currentStreak.');
      }
      await _db.updateStreak(currentStreak, currentFrozen, today);
    }
    // --------------------------------

    // Check if we already have misses today to prevent redundant notifications
    final qadaList = await _db.getQadaEntries();

    // 4. Initial Sync Check (Mass Sync if needed)
    final existingTimings = await _db.getTimingsForDate(today);
    if (existingTimings.isEmpty) {
      await _syncMonthlyTimings();
    }

    // 5. Load Current Prayer States for Today
    final todayStatus =
        history[today] ??
        {
          'Fajr': false,
          'Dzuhur': false,
          'Ashar': false,
          'Maghrib': false,
          'Isha': false,
        };

    setState(() {
      _userName = name;
      _streakCount = currentStreak; // USE UPDATED STREAK
      _isFrozen = currentFrozen; // USE UPDATED FROZEN
      _historyData.addAll(history);
      _prayerStates = Map.from(todayStatus);
      _qadaList = qadaList;
      // Self-healing: Paksa frozen jika ada hutang Qada di database
      _isFrozen = qadaList.isNotEmpty;
      _lastUpdateDate = today;
      _isLoading = false; // Data siap, UI boleh render
    });

    // Cleanup old history (older than 7 days)
    await _db.deleteOldHistory(7);
  }

  Future<void> _syncMonthlyTimings() async {
    try {
      final monthlyData = await _prayerService.getMonthlyTimings();
      for (var day in monthlyData) {
        // Convert dd-mm-yyyy to yyyy-MM-dd
        final parts = day['date'].split('-');
        final formattedDate = "${parts[2]}-${parts[1]}-${parts[0]}";

        await _db.upsertHistory(date: formattedDate, timings: day['timings']);
      }
      debugPrint('NotificationService: Monthly sync completed.');
    } catch (e) {
      debugPrint('NotificationService: Monthly sync failed: $e');
    }
  }

  Future<void> _initNotifications() async {
    await NotificationService().init();
  }

  void _updatePrayerStatus(String label, bool status) async {
    setState(() {
      _prayerStates[label] = status;

      if (status == true) {
        // Batalkan jadwal notifikasi "Terlewat" di sistem Android karena sudah dikerjakan
        NotificationService().cancelSpecificQadaAlert(label);
      }

      // Jika semua kondisi terpenuhi (hari ini & Qada), unfreeze streak
      _checkIfTrulyAllDone().then((done) {
        if (done && _isFrozen) {
          setState(() {
            _isFrozen = false;
          });
          _db.updateStreak(_streakCount, _isFrozen, _lastUpdateDate);
        }
      });

      // Sinkronkan ke history data agar langsung tampil di UI HistoryScreen
      _historyData[_lastUpdateDate] = Map.from(_prayerStates);
    });
    await _db.upsertHistory(date: _lastUpdateDate, status: _prayerStates);
    await _db.updateStreak(_streakCount, _isFrozen, _lastUpdateDate);
  }

  /// Called from HomeContent when a prayer is detected as missed in real-time
  void _onPrayerMissed(String prayerName) async {
    // 1. Cek apakah sholat ini sudah ada di daftar Qada aktif kita
    final alreadyInList = _qadaList.any((q) => q['prayer_name'] == prayerName);

    if (!alreadyInList) {
      setState(() {
        _isFrozen = true; // Freeze immediately
      });
      try {
        // Simpan status Frozen ke database agar awet saat aplikasi ditutup
        await _db.updateStreak(_streakCount, true, _lastUpdateDate);

        // Simpan ke database Qada
        await _db.addQadaEntry(prayerName, _lastUpdateDate);
      } catch (e) {
        debugPrint('Main: Database error during _onPrayerMissed: $e');
      }

      // Berikan notifikasi real-time (Tetap eksekusi walaupun DB gagal)
      await NotificationService().showQadaAlert(prayerName);

      try {
        // Refresh list
        final newList = await _db.getQadaEntries();
        setState(() {
          _qadaList = newList;
        });
      } catch (e) {
        debugPrint('Main: Failed to refresh Qada list: $e');
      }
      debugPrint('RealTime: Missed $prayerName recorded as Qada.');
    }
  }

  void _onQadaComplete(int id, String label) async {
    // 1. Hapus dari database secara permanen
    await _db.completeQadaEntry(id);
    final newList = await _db.getQadaEntries();

    setState(() {
      _qadaList = newList;
      _qadaCompleted.add(label);
      _prayerStates[label] =
          true; // Mark as done for visual feedback on Home Screen

      // If all prayers are now truly completed (including Qada), unfreeze
      _checkIfTrulyAllDone().then((done) {
        if (done && _isFrozen) {
          setState(() {
            _isFrozen = false;
          });
          _db.updateStreak(_streakCount, _isFrozen, _lastUpdateDate);
        }
      });

      // Sinkronkan ke history data agar langsung tampil di UI HistoryScreen
      _historyData[_lastUpdateDate] = Map.from(_prayerStates);
    });
    await _db.upsertHistory(date: _lastUpdateDate, status: _prayerStates);
    await _db.updateStreak(_streakCount, _isFrozen, _lastUpdateDate);
  }

  void _updateUserName(String newName) async {
    setState(() {
      _userName = newName;
    });
    await _db.updateUsername(newName);
    await AuthService().updateProfile(newName);
  }

  Future<bool> _checkIfTrulyAllDone() async {
    // Cek apakah masih ada hutang Qada di database
    // Hapus kewajiban allTodayChecked karena membekukan pengguna dari Qada
    final qadaEntries = await _db.getQadaEntries();
    return qadaEntries.isEmpty; // Cukup pastikan tidak ada Qada
  }

  Future<void> _checkDayChange() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (today != _lastUpdateDate) {
      // HUKUMAN TENGAH MALAM: Cek apakah ada hutang Qada dari kemarin yang belum lunas
      final unpaidQada = await _db.getQadaEntries();

      setState(() {
        if (unpaidQada.isNotEmpty) {
          // Jika ada sisa hutang -> Streak Pecah (Reset ke 0)
          _streakCount = 0;
          debugPrint(
            'DayChange: Streak EXTINGUISHED because Qada was not cleared.',
          );
        } else {
          // Jika lunas semua (baik tepat waktu atau via Qada) -> Streak Naik!
          _streakCount++;
          debugPrint('DayChange: Streak incremented to $_streakCount.');
        }

        // Reset untuk hari hari baru
        _isFrozen = false;
        _qadaList = [];
        _qadaCompleted.clear();
        _prayerStates = {
          'Fajr': false,
          'Dzuhur': false,
          'Ashar': false,
          'Maghrib': false,
          'Isha': false,
        };
        _lastUpdateDate = today;
      });

      // Update Database
      if (unpaidQada.isNotEmpty) {
        await _db.deleteAllUncompletedQada(); // Hapus hutang yang basi
        NotificationService().showStreakResetAlert();
      }

      // Upsert baris baru untuk hari yang baru di DB
      await _db.upsertHistory(date: today, status: _prayerStates);
      // Simpan status streak terbaru
      await _db.updateStreak(_streakCount, _isFrozen, today);
      // Jalankan cleanup mingguan
      await _db.deleteOldHistory(7);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E9DA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1F6F5B)),
        ),
      );
    }

    final List<Widget> screens = [
      HomeContent(
        userName: _userName,
        prayerStates: _prayerStates,
        onPrayerToggle: _updatePrayerStatus,
        streakCount: _streakCount,
        isFrozen: _isFrozen,
        qadaCompleted: _qadaCompleted,
        missedPrayers: _qadaList, // Meneruskan daftar Qada dari Database
        onQadaComplete: _onQadaComplete,
        onPrayerMissed: _onPrayerMissed,
        onTabChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      CommunityScreen(
        currentUsername: _userName,
        onTabChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const PrayScreen(),
      HistoryScreen(
        historyData: _historyData,
        qadaList: _qadaList,
      ),
      ProfileScreen(
        userName: _userName, 
        onNameChanged: _updateUserName,
        onLogout: widget.onLogout,
        onTabChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
