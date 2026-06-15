import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class CommunityService {
  static const String baseUrl = ApiConfig.apiBaseUrl;
  final AuthService _auth = AuthService();

  // Helper to get headers with session token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _auth.getSavedToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch all posts with optional post types
  Future<List<Map<String, dynamic>>> fetchPosts({List<String>? types}) async {
    try {
      String url = '$baseUrl/posts?limit=50';
      if (types != null && types.isNotEmpty) {
        url += '&types=${types.join(',')}';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint("CommunityService fetchPosts Error: $e");
    }
    return [];
  }

  // Fetch single post details
  Future<Map<String, dynamic>?> fetchPostDetail(int postId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/$postId'));
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("CommunityService fetchPostDetail Error: $e");
    }
    return null;
  }

  // Create new post
  Future<bool> createPost(Map<String, dynamic> postData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: headers,
        body: jsonEncode(postData),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("CommunityService createPost Error: $e");
    }
    return false;
  }

  // Update existing post
  Future<bool> updatePost(int postId, Map<String, dynamic> postData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: headers,
        body: jsonEncode(postData),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("CommunityService updatePost Error: $e");
    }
    return false;
  }

  // Delete post
  Future<bool> deletePost(int postId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("CommunityService deletePost Error: $e");
    }
    return false;
  }

  // Add reaction
  Future<Map<String, dynamic>?> reactToPost(int postId, String reactionType) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/react'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reaction_type': reactionType}),
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("CommunityService reactToPost Error: $e");
    }
    return null;
  }

  // Fetch comments
  Future<List<Map<String, dynamic>>> fetchComments(int postId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/$postId/comments'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint("CommunityService fetchComments Error: $e");
    }
    return [];
  }

  // Add comment
  Future<bool> addComment(int postId, String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("CommunityService addComment Error: $e");
    }
    return false;
  }

  // Delete comment
  Future<bool> deleteComment(int commentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("CommunityService deleteComment Error: $e");
    }
    return false;
  }

  // Add reply to comment
  Future<bool> addReply(int commentId, String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/comments/$commentId/replies'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("CommunityService addReply Error: $e");
    }
    return false;
  }

  // Delete reply
  Future<bool> deleteReply(int replyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/replies/$replyId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("CommunityService deleteReply Error: $e");
    }
    return false;
  }

  // Upload an image file to the backend
  Future<String?> uploadImage(File imageFile) async {
    try {
      final token = await _auth.getSavedToken();
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['path']; // Returns "uploads/posts/..."
        }
      }
    } catch (e) {
      debugPrint("CommunityService uploadImage Error: $e");
    }
    return null;
  }
}
