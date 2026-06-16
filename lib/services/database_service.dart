import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'waqt_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. User Profile with token column (Version 2)
    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        username TEXT,
        token TEXT
      )
    ''');
    await db.insert('user_profile', {'id': 1, 'username': 'User', 'token': null});

    // 2. Qada Entries
    await db.execute('''
      CREATE TABLE qada_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prayer_name TEXT,
        date_missed TEXT,
        is_completed INTEGER DEFAULT 0
      )
    ''');

    // 3. Prayer History (Stores both timings from API and user status)
    await db.execute('''
      CREATE TABLE prayer_history (
        date TEXT PRIMARY KEY,
        fajr_time TEXT,
        dzuhur_time TEXT,
        ashar_time TEXT,
        maghrib_time TEXT,
        isha_time TEXT,
        fajr_done INTEGER DEFAULT 0,
        dzuhur_done INTEGER DEFAULT 0,
        ashar_done INTEGER DEFAULT 0,
        maghrib_done INTEGER DEFAULT 0,
        isha_done INTEGER DEFAULT 0
      )
    ''');

    // 4. Streak Data
    await db.execute('''
      CREATE TABLE streak_data (
        id INTEGER PRIMARY KEY,
        count INTEGER DEFAULT 0,
        is_frozen INTEGER DEFAULT 0,
        last_updated_date TEXT
      )
    ''');
    await db.insert('streak_data', {
      'id': 1,
      'count': 0,
      'is_frozen': 0,
      'last_updated_date': '',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE user_profile ADD COLUMN token TEXT");
        debugPrint("SQLite: Column 'token' added successfully to user_profile table.");
      } catch (e) {
        debugPrint("SQLite Warning: failed to add column 'token': $e");
      }
    }
  }

  // --- USER PROFILE ---
  Future<String> getUsername() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
    );
    return maps.isNotEmpty ? maps.first['username'] : 'User';
  }

  Future<void> updateUsername(String name) async {
    final db = await database;
    await db.update(
      'user_profile',
      {'username': name},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // --- STREAK DATA ---
  Future<Map<String, dynamic>> getStreak() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'streak_data',
      where: 'id = ?',
      whereArgs: [1],
    );
    return maps.first;
  }

  Future<void> updateStreak(int count, bool isFrozen, String lastDate) async {
    final db = await database;
    await db.update(
      'streak_data',
      {
        'count': count,
        'is_frozen': isFrozen ? 1 : 0,
        'last_updated_date': lastDate,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // --- QADA ENTRIES ---
  Future<List<Map<String, dynamic>>> getQadaEntries() async {
    final db = await database;
    return await db.query(
      'qada_entries',
      where: 'is_completed = 0',
      orderBy: 'date_missed DESC',
    );
  }

  Future<void> addQadaEntry(String prayer, String date) async {
    final db = await database;
    await db.insert('qada_entries', {
      'prayer_name': prayer,
      'date_missed': date,
      'is_completed': 0,
    });
  }

  Future<void> completeQadaEntry(int id) async {
    final db = await database;
    await db.update(
      'qada_entries',
      {'is_completed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- PRAYER HISTORY ---
  Future<void> upsertHistory({
    required String date,
    Map<String, dynamic>? timings,
    Map<String, bool>? status,
  }) async {
    final db = await database;

    // Check if exists
    final existing = await db.query(
      'prayer_history',
      where: 'date = ?',
      whereArgs: [date],
    );

    Map<String, dynamic> row = {'date': date};

    if (timings != null) {
      row['fajr_time'] = timings['Fajr'];
      row['dzuhur_time'] = timings['Dzuhur'] ?? timings['Dhuhr'];
      row['ashar_time'] = timings['Ashar'] ?? timings['Asr'];
      row['maghrib_time'] = timings['Maghrib'];
      row['isha_time'] = timings['Isha'];
    }

    if (status != null) {
      row['fajr_done'] = status['Fajr'] == true ? 1 : 0;
      row['dzuhur_done'] = status['Dzuhur'] == true ? 1 : 0;
      row['ashar_done'] = status['Ashar'] == true ? 1 : 0;
      row['maghrib_done'] = status['Maghrib'] == true ? 1 : 0;
      row['isha_done'] = status['Isha'] == true ? 1 : 0;
    }

    if (existing.isEmpty) {
      await db.insert('prayer_history', row);
    } else {
      await db.update(
        'prayer_history',
        row,
        where: 'date = ?',
        whereArgs: [date],
      );
    }
  }

  Future<Map<String, Map<String, bool>>> getAllHistory() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('prayer_history');

    Map<String, Map<String, bool>> result = {};
    for (var m in maps) {
      result[m['date']] = {
        'Fajr': m['fajr_done'] == 1,
        'Dzuhur': m['dzuhur_done'] == 1,
        'Ashar': m['ashar_done'] == 1,
        'Maghrib': m['maghrib_done'] == 1,
        'Isha': m['isha_done'] == 1,
      };
    }
    return result;
  }

  Future<Map<String, String>> getTimingsForDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'prayer_history',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isEmpty) return {};

    final m = maps.first;
    return {
      'Fajr': m['fajr_time'] ?? '',
      'Dzuhur': m['dzuhur_time'] ?? '',
      'Ashar': m['ashar_time'] ?? '',
      'Maghrib': m['maghrib_time'] ?? '',
      'Isha': m['isha_time'] ?? '',
    };
  }

  Future<void> deleteOldHistory(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffStr =
        "${cutoffDate.year}-${cutoffDate.month.toString().padLeft(2, '0')}-${cutoffDate.day.toString().padLeft(2, '0')}";

    int count = await db.delete(
      'prayer_history',
      where: 'date < ?',
      whereArgs: [cutoffStr],
    );
    debugPrint(
      'DatabaseService: Cleaned up $count old history records (older than $cutoffStr)',
    );
  }

  Future<void> deleteAllUncompletedQada() async {
    final db = await database;
    int count = await db.delete('qada_entries', where: 'is_completed = 0');
    debugPrint(
      'DatabaseService: Deleted $count uncompleted qada entries due to streak reset.',
    );
  }

  // --- CLEAR USER DATA ON LOGOUT ---
  Future<void> clearAllUserData() async {
    final db = await database;
    await db.delete('prayer_history');
    await db.delete('qada_entries');
    await db.update('streak_data', {
      'count': 0,
      'is_frozen': 0,
      'last_updated_date': '',
    }, where: 'id = ?', whereArgs: [1]);
    debugPrint('DatabaseService: Local user data completely cleared on logout.');
  }

  // --- BACKGROUND SYNC WITH SERVER ---
  Future<void> syncWithServer() async {
    try {
      final db = await database;
      
      // 1. Get Token
      final tokenResult = await db.query('user_profile', where: 'id = 1');
      if (tokenResult.isEmpty || tokenResult.first['token'] == null) {
        debugPrint("Sync: Cancelled, no token found.");
        return;
      }
      final String token = tokenResult.first['token'] as String;

      // 2. Gather Local Data
      final streak = await getStreak();
      final qadaList = await getQadaEntries();
      
      final historyMaps = await db.query('prayer_history');
      final List<Map<String, dynamic>> historyList = [];
      for (var m in historyMaps) {
        historyList.add({
          'date': m['date'],
          'fajr_done': m['fajr_done'] == 1,
          'dzuhur_done': m['dzuhur_done'] == 1,
          'ashar_done': m['ashar_done'] == 1,
          'maghrib_done': m['maghrib_done'] == 1,
          'isha_done': m['isha_done'] == 1,
        });
      }

      // 3. Send to Spring Boot
      final payload = {
        'streak': streak,
        'history': historyList,
        'qada': qadaList,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      // 4. Overwrite Local DB with Consolidated Server Response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Update Streak
          final s = data['streak'];
          await updateStreak(s['count'], s['is_frozen'], s['last_updated_date'] ?? '');

          // Update History
          final hList = data['history'] as List<dynamic>;
          for (var h in hList) {
            await upsertHistory(
              date: h['date'],
              status: {
                'Fajr': h['fajr_done'],
                'Dzuhur': h['dzuhur_done'],
                'Ashar': h['ashar_done'],
                'Maghrib': h['maghrib_done'],
                'Isha': h['isha_done'],
              }
            );
          }

          // Update Qada
          final qList = data['qada'] as List<dynamic>;
          await db.delete('qada_entries'); // Clear local qada
          for (var q in qList) {
            await db.insert('qada_entries', {
              'prayer_name': q['prayer_name'],
              'date_missed': q['date_missed'],
              'is_completed': q['is_completed'] ? 1 : 0,
            });
          }
          
          debugPrint("Sync: Background sync completed successfully.");
        }
      } else {
        debugPrint("Sync Error: Failed to sync with server. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }
}
