import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('offline_posts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        author TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        imagePath TEXT,
        imageUrl TEXT,
        isFeatured INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'published',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Seed sample data
    final now = DateTime.now();
    final samples = [
      Post(
        title: 'Welcome to Offline Posts Manager',
        body:
            'This app lets your team manage posts entirely offline using SQLite. All data is stored locally on your device — no internet required.\n\nYou can create, read, update, and delete posts at any time, even in areas with no connectivity.',
        author: 'Admin',
        category: 'General',
        isFeatured: true,
        tags: ['welcome', 'offline', 'intro'],
        imageUrl:
            'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Post(
        title: 'How SQLite Powers Local Storage',
        body:
            'SQLite is a lightweight, serverless relational database engine. It stores data in a single file on disk, making it perfect for mobile and desktop applications that need local persistence.\n\nFlutter\'s sqflite package provides a clean API to interact with SQLite, supporting all standard SQL operations.',
        author: 'Tech Team',
        category: 'Technology',
        tags: ['sqlite', 'flutter', 'database'],
        imageUrl:
            'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Post(
        title: 'Best Practices for Offline-First Apps',
        body:
            'Building offline-first means your app works fully without a connection. Key principles include local-first storage, sync when connectivity returns, conflict resolution strategies, and clear UI feedback about sync status.\n\nThis approach ensures a seamless user experience regardless of network conditions.',
        author: 'Product Team',
        category: 'Technology',
        status: 'draft',
        tags: ['offline-first', 'mobile', 'ux'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];

    for (final post in samples) {
      await db.insert('posts', post.toMap());
    }
  }

  // CREATE
  Future<Post> insertPost(Post post) async {
    final db = await database;
    await db.insert('posts', post.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return post;
  }

  // READ ALL
  Future<List<Post>> getAllPosts({String? category, String? status}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (category != null && status != null) {
      where = 'category = ? AND status = ?';
      whereArgs = [category, status];
    } else if (category != null) {
      where = 'category = ?';
      whereArgs = [category];
    } else if (status != null) {
      where = 'status = ?';
      whereArgs = [status];
    }

    final maps = await db.query('posts',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'isFeatured DESC, updatedAt DESC');
    return maps.map(Post.fromMap).toList();
  }

  // READ ONE
  Future<Post?> getPost(String id) async {
    final db = await database;
    final maps =
        await db.query('posts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Post.fromMap(maps.first);
  }

  // UPDATE
  Future<int> updatePost(Post post) async {
    final db = await database;
    return await db.update('posts', post.toMap(),
        where: 'id = ?', whereArgs: [post.id]);
  }

  // DELETE
  Future<int> deletePost(String id) async {
    final db = await database;
    return await db.delete('posts', where: 'id = ?', whereArgs: [id]);
  }

  // SEARCH
  Future<List<Post>> searchPosts(String query) async {
    final db = await database;
    final q = '%$query%';
    final maps = await db.query(
      'posts',
      where: 'title LIKE ? OR body LIKE ? OR author LIKE ? OR tags LIKE ?',
      whereArgs: [q, q, q, q],
      orderBy: 'updatedAt DESC',
    );
    return maps.map(Post.fromMap).toList();
  }

  // STATS
  Future<Map<String, int>> getStats() async {
    final db = await database;
    final total =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM posts')) ??
            0;
    final featured = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM posts WHERE isFeatured = 1')) ??
        0;
    final drafts = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM posts WHERE status = "draft"')) ??
        0;
    return {'total': total, 'featured': featured, 'drafts': drafts};
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
