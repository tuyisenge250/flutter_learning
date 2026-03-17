import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com/posts';
  static const Duration _timeout = Duration(seconds: 15);

  // Cloudflare blocks Dart's default User-Agent on Android — override it.
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) Flutter/3.0',
  };

  // GET /posts
  Future<List<Post>> fetchPosts() async {
    try {
      final response =
          await http.get(Uri.parse(_baseUrl), headers: _headers).timeout(_timeout);
      _checkStatus(response.statusCode, 'fetch posts');
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Post.fromJson(e)).toList();
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // GET /posts/:id
  Future<Post> fetchPost(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$id'), headers: _headers)
          .timeout(_timeout);
      _checkStatus(response.statusCode, 'fetch post');
      return Post.fromJson(jsonDecode(response.body));
    } on SocketException {
      throw ApiException('No internet connection.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // POST /posts
  Future<Post> createPost(Post post) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers,
            body: jsonEncode(post.toJson()),
          )
          .timeout(_timeout);
      _checkStatus(response.statusCode, 'create post');
      return Post.fromJson(jsonDecode(response.body));
    } on SocketException {
      throw ApiException('No internet connection.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // PUT /posts/:id
  Future<Post> updatePost(int id, Post post) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/$id'),
            headers: _headers,
            body: jsonEncode({...post.toJson(), 'id': id}),
          )
          .timeout(_timeout);
      _checkStatus(response.statusCode, 'update post');
      return Post.fromJson(jsonDecode(response.body));
    } on SocketException {
      throw ApiException('No internet connection.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // DELETE /posts/:id
  Future<void> deletePost(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/$id'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException('Failed to delete post (${response.statusCode})');
      }
    } on SocketException {
      throw ApiException('No internet connection.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  void _checkStatus(int statusCode, String action) {
    if (statusCode == 404) throw ApiException('Not found.');
    if (statusCode >= 400) {
      throw ApiException('Failed to $action (HTTP $statusCode).');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
