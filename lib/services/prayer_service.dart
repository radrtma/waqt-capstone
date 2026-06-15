import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class PrayerService {
  static const String baseUrl = 'https://api.aladhan.com/v1/timingsByCity';

  Future<Map<String, dynamic>> getPrayerTimings({
    String city = 'Jakarta',
    String country = 'Indonesia',
    int method = 11, // Kemenag Indonesia
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // 1. Cek Cache
    final cachedDate = prefs.getString('prayer_cache_date');
    final cachedCity = prefs.getString('prayer_cache_city');
    final cachedJson = prefs.getString('prayer_cache_json');

    if (cachedDate == today && cachedCity == city && cachedJson != null) {
      debugPrint('PrayerService: Menggunakan cache untuk $city pada $today');
      return _processApiResponse(json.decode(cachedJson));
    }

    // 2. Jika tidak ada cache atau kota berubah, ambil dari API
    final url = Uri.parse('$baseUrl?city=$city&country=$country&method=$method');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Simpan ke Cache
        await prefs.setString('prayer_cache_date', today);
        await prefs.setString('prayer_cache_city', city);
        await prefs.setString('prayer_cache_json', response.body);
        
        debugPrint('PrayerService: API dipanggil dan cache diperbarui untuk $city');
        return _processApiResponse(data);
      } else {
        // Fallback ke cache terakhir jika tersedia walaupun tanggal berbeda
        if (cachedJson != null) {
          debugPrint('PrayerService: API Gagal (${response.statusCode}), menggunakan fallback cache.');
          return _processApiResponse(json.decode(cachedJson));
        }
        throw Exception('Gagal mengambil jadwal sholat: ${response.statusCode}');
      }
    } catch (e) {
      if (cachedJson != null) {
        debugPrint('PrayerService: Kesalahan jaringan ($e), menggunakan fallback cache.');
        return _processApiResponse(json.decode(cachedJson));
      }
      throw Exception('Kesalahan jaringan: $e');
    }
  }

  Map<String, dynamic> _processApiResponse(Map<String, dynamic> data) {
    final timings = data['data']['timings'] as Map<String, dynamic>;
    
    // Map keys to match our app labels
    final normalizedTimings = {
      'Fajr': timings['Fajr'],
      'Dzuhur': timings['Dhuhr'],
      'Ashar': timings['Asr'],
      'Maghrib': timings['Maghrib'],
      'Isha': timings['Isha'],
    };
    
    return {
      'timings': normalizedTimings,
      'date': data['data']['date'],
    };
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('prayer_cache_date');
    await prefs.remove('prayer_cache_city');
    await prefs.remove('prayer_cache_json');
    debugPrint('PrayerService: Cache dibersihkan manual.');
  }

  Future<List<Map<String, dynamic>>> getMonthlyTimings({
    String city = 'Jakarta',
    String country = 'Indonesia',
    int method = 11,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    year ??= now.year;
    month ??= now.month;

    final url = Uri.parse('https://api.aladhan.com/v1/calendarByCity/$year/$month?city=$city&country=$country&method=$method');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> days = data['data'];
        
        return days.map((day) {
          final timings = day['timings'] as Map<String, dynamic>;
          final dateObj = day['date'] as Map<String, dynamic>;
          
          // API returns HH:mm (Timezone) or just HH:mm
          return {
            'date': dateObj['gregorian']['date'], // dd-mm-yyyy
            'timings': {
              'Fajr': timings['Fajr'].split(' ')[0],
              'Dzuhur': timings['Dhuhr'].split(' ')[0],
              'Ashar': timings['Asr'].split(' ')[0],
              'Maghrib': timings['Maghrib'].split(' ')[0],
              'Isha': timings['Isha'].split(' ')[0],
            },
          };
        }).toList();
      } else {
        throw Exception('Gagal mengambil kalender sholat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Kesalahan jaringan: $e');
    }
  }
}
