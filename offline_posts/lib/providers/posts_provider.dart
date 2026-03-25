import 'package:flutter/material.dart';
import '../models/post.dart';
import '../database/database_helper.dart';

enum LoadState { idle, loading, loaded, error }

class PostsProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<Post> _posts = [];
  List<Post> _searchResults = [];
  Map<String, int> _stats = {'total': 0, 'featured': 0, 'drafts': 0};
  LoadState _state = LoadState.idle;
  String _error = '';
  String _searchQuery = '';
  String? _filterCategory;
  String? _filterStatus;
  bool _isSearching = false;

  List<Post> get posts => _isSearching ? _searchResults : _posts;
  Map<String, int> get stats => _stats;
  LoadState get state => _state;
  String get error => _error;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get filterCategory => _filterCategory;
  String? get filterStatus => _filterStatus;

  Future<void> loadPosts() async {
    _state = LoadState.loading;
    notifyListeners();
    try {
      _posts = await _db.getAllPosts(
          category: _filterCategory, status: _filterStatus);
      _stats = await _db.getStats();
      _state = LoadState.loaded;
    } catch (e) {
      _error = e.toString();
      _state = LoadState.error;
    }
    notifyListeners();
  }

  Future<Post?> getPost(String id) => _db.getPost(id);

  Future<bool> addPost(Post post) async {
    try {
      await _db.insertPost(post);
      await loadPosts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePost(Post post) async {
    try {
      await _db.updatePost(post);
      await loadPosts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String id) async {
    try {
      await _db.deletePost(id);
      await loadPosts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    _searchResults = await _db.searchPosts(query);
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  void setFilter({String? category, String? status}) {
    _filterCategory = category;
    _filterStatus = status;
    loadPosts();
  }

  void clearFilters() {
    _filterCategory = null;
    _filterStatus = null;
    loadPosts();
  }
}
