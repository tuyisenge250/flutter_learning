import 'package:uuid/uuid.dart';

class Post {
  final String id;
  final String title;
  final String body;
  final String author;
  final String category;
  final String? imagePath; // local file path
  final String? imageUrl;  // remote URL fallback
  final bool isFeatured;
  final String status; // 'draft' | 'published'
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  Post({
    String? id,
    required this.title,
    required this.body,
    required this.author,
    this.category = 'General',
    this.imagePath,
    this.imageUrl,
    this.isFeatured = false,
    this.status = 'published',
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  Post copyWith({
    String? title,
    String? body,
    String? author,
    String? category,
    String? imagePath,
    String? imageUrl,
    bool? isFeatured,
    String? status,
    List<String>? tags,
  }) {
    return Post(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      author: author ?? this.author,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'author': author,
      'category': category,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured ? 1 : 0,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags.join(','),
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      author: map['author'],
      category: map['category'] ?? 'General',
      imagePath: map['imagePath'],
      imageUrl: map['imageUrl'],
      isFeatured: (map['isFeatured'] ?? 0) == 1,
      status: map['status'] ?? 'published',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
    );
  }

  String get displayImage => imagePath ?? imageUrl ?? '';
  bool get hasImage => imagePath != null || imageUrl != null;

  @override
  String toString() => 'Post(id: $id, title: $title, author: $author)';
}

const List<String> kCategories = [
  'General',
  'Technology',
  'Business',
  'Sports',
  'Entertainment',
  'Health',
  'Science',
  'Politics',
  'Education',
  'Travel',
  'Food',
  'Lifestyle',
];
