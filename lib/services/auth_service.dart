import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'database_service.dart';

class AuthService {
  static const String baseUrl = '${ApiConfig.apiBaseUrl}/auth';
  final DatabaseService _db = DatabaseService();

  // Registrasi Akun Baru ke Server Backend
  Future<bool> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' || data['token'] != null) {
          await saveTokenLocally(username, data['token']);
          return true;
        }
      }
    } catch (e) {
      debugPrint("AuthService Register HTTP Error: $e");
    }
    return false;
  }

  // Login Akun ke Server Backend
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' || data['token'] != null) {
          await saveTokenLocally(username, data['token']);
          return true;
        }
      }
    } catch (e) {
      debugPrint("AuthService Login HTTP Error: $e");
    }
    return false;
  }

  // Update Profile Username on Server
  Future<bool> updateProfile(String newUsername) async {
    try {
      final token = await getSavedToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({'username': newUsername}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return true;
        }
      }
    } catch (e) {
      debugPrint("AuthService updateProfile HTTP Error: $e");
    }
    return false;
  }

  // Ganti Password di Server
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      final token = await getSavedToken();
      if (token == null) return {'success': false, 'message': 'Sesi tidak valid. Silakan login ulang.'};

      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'message': 'Password berhasil diubah.'};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengubah password.'};
    } catch (e) {
      debugPrint("AuthService changePassword HTTP Error: $e");
      return {'success': false, 'message': 'Tidak dapat terhubung ke server.'};
    }
  }

  // Read saved session token from SQLite local storage
  Future<String?> getSavedToken() async {
    try {
      final db = await _db.database;
      final List<Map<String, dynamic>> result = await db.query('user_profile');
      if (result.isNotEmpty && result.first.containsKey('token')) {
        return result.first['token'] as String?;
      }
    } catch (e) {
      debugPrint("AuthService Error reading token: $e");
    }
    return null;
  }

  // Safely write/upsert token to local SQLite database (ID = 1 row)
  Future<void> saveTokenLocally(String username, String token) async {
    final db = await _db.database;
    
    // Check if user profile row with ID = 1 exists
    final List<Map<String, dynamic>> result = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
    );
    
    if (result.isEmpty) {
      // Safe fallback insert if row is missing
      await db.insert('user_profile', {
        'id': 1,
        'username': username,
        'token': token,
      });
      debugPrint("SQLite Safeguard: Inserted new profile row with token.");
    } else {
      // Standard update
      await db.update(
        'user_profile',
        {
          'username': username,
          'token': token,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
      debugPrint("SQLite Safeguard: Updated profile token successfully.");
    }
  }

  // Clear local token (Logout)
  Future<void> logout() async {
    try {
      // Kritis: Sinkronisasikan data lokal (yg belum terkirim) ke server SEBELUM dihapus!
      debugPrint("AuthService: Attempting final sync before logout...");
      await _db.syncWithServer();

      final db = await _db.database;
      await db.update(
        'user_profile',
        {'token': null},
        where: 'id = ?',
        whereArgs: [1],
      );
      
      // Wipe local data to prevent next user from inheriting it
      await _db.clearAllUserData();
      
      debugPrint("SQLite Safeguard: Token cleared locally.");
    } catch (e) {
      debugPrint("AuthService Error clearing token: $e");
    }
  }
}
