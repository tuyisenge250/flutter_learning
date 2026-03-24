# Offline Posts Manager

> **University of Rwanda — College of Science and Technology**
> ICT | Computer Engineering | Mobile Application Development
> Assignment 5 — SQLite Local Storage with Flutter

---

## Demo Video

[![Offline Posts Manager Demo](https://img.youtube.com/vi/nEmGJUTQzQg/maxresdefault.jpg)](https://youtu.be/nEmGJUTQzQg)

> Click the thumbnail above to watch the full demo on YouTube.

---

## Overview

**Offline Posts Manager** is a fully offline-capable Flutter application that allows users to create, read, update, and delete posts stored locally on the device. No internet connection is required at any point — all data is persisted using SQLite via the `sqflite` package.

The app demonstrates core mobile development principles:
- Local-first data storage with SQLite
- CRUD operations using the `sqflite` package
- Reactive state management with `ChangeNotifier` / `Provider`
- Async/await database interaction without blocking the UI thread
- Dark-themed Material 3 UI with shimmer loading, staggered animations, and swipe-to-delete

---

## Features

| Feature | Description |
|---|---|
| Create Post | Add a new post with title, body, author, category, tags, image, and status |
| Read Posts | Browse all posts with a stats bar (Total / Published / Drafts / Featured) |
| Update Post | Edit any field of an existing post |
| Delete Post | Swipe-to-delete or confirm-dialog delete with SnackBar feedback |
| Search | Live full-text search across title, body, author, and tags |
| Filter | Filter by category (12 categories) and by status (Published / Draft) |
| Featured Posts | Pin important posts to the top of the list |
| Image Support | Attach a local image from the gallery or link a remote image URL |
| Offline-First | 100% functional with no internet connection |

---

## Project Structure

```
offline_posts/
├── lib/
│   ├── main.dart                    # App entry point, dark theme setup
│   ├── models/
│   │   └── post.dart                # Post data model + toMap / fromMap
│   ├── database/
│   │   └── database_helper.dart     # SQLite singleton — all CRUD operations
│   ├── providers/
│   │   └── posts_provider.dart      # State management + error handling layer
│   ├── screens/
│   │   ├── home_screen.dart         # Post list, tabs, search, filter, stats
│   │   ├── post_detail_screen.dart  # Full post view
│   │   └── add_edit_screen.dart     # Create / Edit form
│   ├── widgets/
│   │   └── post_card.dart           # Slidable card with edit/delete actions
│   └── theme/
│       └── app_theme.dart           # Dark Material 3 theme + category colours
├── assets/images/                   # Local image assets
├── pdf/
│   └── flutter_#5_merged.pdf        # Assignment discussion paper
└── pubspec.yaml
```

---

## 1. Dependencies Used and Why

The `pubspec.yaml` file declares the following key dependencies:

| Package | Version | Purpose |
|---|---|---|
| `sqflite` | ^2.3.3+1 | SQLite database engine for Flutter |
| `path` | ^1.9.0 | Safely constructs file system paths |
| `path_provider` | ^2.1.4 | Locates platform-specific storage directories |
| `uuid` | ^4.5.1 | Generates unique IDs (`UUIDv4`) for each post |
| `image_picker` | ^1.1.2 | Picks images from the device gallery or camera |
| `provider` | (via flutter) | State management — connects the DB layer to the UI |
| `flutter_slidable` | ^3.1.1 | Swipe-to-delete / swipe-to-edit gesture on post cards |
| `shimmer` | ^3.0.0 | Skeleton loading placeholder animations |
| `intl` | ^0.20.2 | Date and time formatting |
| `flutter_staggered_animations` | ^1.1.1 | Animated staggered list entry effects |

### Why SQLite is Necessary for Local Storage

The application's core design requirement is that it must work **with no internet connection**. This rules out any cloud-based or server-dependent storage solution such as Firebase Firestore or a REST API backend.

SQLite was chosen for four specific reasons:

**a) Serverless and self-contained.**
SQLite does not require a running database server process. The entire database lives in a single file (`offline_posts.db`) on the device's file system. The `DatabaseHelper._initDB()` method locates and opens this file:

```dart
final dbPath = await getDatabasesPath();
final path = join(dbPath, filePath);  // e.g. /data/user/0/.../offline_posts.db
return await openDatabase(path, version: 1, onCreate: _createDB);
```

**b) Relational structure with SQL query power.**
Unlike a simple key-value store (`SharedPreferences`), SQLite supports structured tables, typed columns, `WHERE` filters, `ORDER BY` sorting, `LIKE` full-text search, and `COUNT(*)` aggregates — all of which this app uses.

**c) Persistence across app restarts.**
Data written to SQLite survives the app being closed or the device being rebooted — essential for a posts manager where user content must never be lost.

**d) No network dependency.**
`sqflite` never makes a network call. Full CRUD functionality works in airplane mode.

The `path` and `path_provider` packages are companions to `sqflite`: `path_provider` locates the correct OS-level storage directory and `path` uses `join()` to build a safe, cross-platform file path to the database file.

---

## 2. How Database Exceptions Are Handled

### Handle: Database Not Initialized

`DatabaseHelper` uses the **Singleton pattern** with lazy initialization to guarantee the database is opened exactly once before any operation runs:

```dart
static final DatabaseHelper instance = DatabaseHelper._init();
static Database? _database;

Future<Database> get database async {
  if (_database != null) return _database!;       // already open — reuse
  _database = await _initDB('offline_posts.db');  // first call — open it
  return _database!;
}
```

Every public method (`insertPost`, `getAllPosts`, `updatePost`, `deletePost`) begins with `final db = await database;`. This guarantees the database is always initialized before any operation is attempted — it is impossible to run a query against a null or uninitialized database object.

### Handle: Insert / Update / Delete Errors

Error handling for write operations is delegated to `PostsProvider`, which wraps every database call in a `try/catch` block. Each method returns a `bool` to signal success or failure to the UI layer:

```dart
Future<bool> addPost(Post post) async {
  try {
    await _db.insertPost(post);
    await loadPosts();
    return true;
  } catch (e) {
    _error = e.toString();   // store the error message
    notifyListeners();       // notify the UI to re-render
    return false;            // signal failure to the caller
  }
}
```

The same pattern applies to `updatePost()` and `deletePost()`. The error is stored in `_error`, the `LoadState` is not changed to a crash state, and `notifyListeners()` causes the UI to show an error banner or `SnackBar`.

For inserts specifically, `ConflictAlgorithm.replace` prevents unique-constraint violations:

```dart
await db.insert('posts', post.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace);
```

If a post with the same primary key already exists, SQLite replaces it instead of throwing an error.

### Handle: Invalid or Corrupted Data

The `Post.fromMap()` factory is where raw SQLite row data is deserialized back into a Dart object. Two corruption-prone fields are handled defensively:

**DateTime parsing** — `createdAt` and `updatedAt` are stored as ISO 8601 strings. If the stored value is malformed, `DateTime.parse()` throws a `FormatException`, which propagates up through `loadPosts()` and is caught by `PostsProvider`, setting `LoadState.error` and displaying a Retry button.

**Tags deserialization** — tags are stored as a comma-separated string. The factory guards against null and empty values:

```dart
tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
    ? (map['tags'] as String).split(',')
    : [],
```

**Nullable optional fields** — `imagePath` and `imageUrl` are declared `String?` (nullable) in both the Dart model and the SQL schema (`TEXT` with no `NOT NULL`), so rows without images deserialize without error.

---

## 3. SQLite in Flutter

### Database vs. Table

| Concept | Analogy | In this app |
|---|---|---|
| **Database** | A filing cabinet | `offline_posts.db` — one file on the device |
| **Table** | A drawer inside the cabinet | `posts` — rows and columns of post data |

The `posts` table is defined in `_createDB`:

```dart
await db.execute('''
  CREATE TABLE posts (
    id         TEXT    PRIMARY KEY,
    title      TEXT    NOT NULL,
    body       TEXT    NOT NULL,
    author     TEXT    NOT NULL,
    category   TEXT    NOT NULL DEFAULT 'General',
    imagePath  TEXT,
    imageUrl   TEXT,
    isFeatured INTEGER NOT NULL DEFAULT 0,
    status     TEXT    NOT NULL DEFAULT 'published',
    createdAt  TEXT    NOT NULL,
    updatedAt  TEXT    NOT NULL,
    tags       TEXT    NOT NULL DEFAULT ''
  )
''');
```

> **Note:** SQLite has no `BOOLEAN` type. `isFeatured` is stored as `INTEGER` (0 or 1). The `Post` model converts it with `isFeatured ? 1 : 0` in `toMap()` and `(map['isFeatured'] ?? 0) == 1` in `fromMap()`.

### CRUD Operations

**Create — `insertPost()`**
```dart
await db.insert('posts', post.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace);
// → INSERT OR REPLACE INTO posts (id, title, ...) VALUES (?, ?, ...)
```

**Read All — `getAllPosts()`**
```dart
final maps = await db.query('posts',
    where: where,
    whereArgs: whereArgs,
    orderBy: 'isFeatured DESC, updatedAt DESC');
return maps.map(Post.fromMap).toList();
// → SELECT * FROM posts WHERE ... ORDER BY isFeatured DESC, updatedAt DESC
```

**Read One — `getPost()`**
```dart
final maps = await db.query('posts',
    where: 'id = ?', whereArgs: [id], limit: 1);
// → SELECT * FROM posts WHERE id = ? LIMIT 1
```

**Update — `updatePost()`**
```dart
return await db.update('posts', post.toMap(),
    where: 'id = ?', whereArgs: [post.id]);
// → UPDATE posts SET title=?, body=?, ... WHERE id=?
```

**Delete — `deletePost()`**
```dart
return await db.delete('posts', where: 'id = ?', whereArgs: [id]);
// → DELETE FROM posts WHERE id=?
```

> All queries use `?` placeholders — this keeps user input separate from the SQL structure and **prevents SQL injection**.

### How Flutter Interacts with the Database Asynchronously

SQLite disk I/O is a blocking operation. If run on the main UI thread it would freeze animations and gestures. Flutter handles this through Dart's `async/await` concurrency model.

**Every database method is `async` and returns a `Future`:**

```dart
Future<List<Post>> getAllPosts(...) async {
  final db = await database;          // suspend — wait for DB to open
  final maps = await db.query(...);   // suspend — wait for disk read
  return maps.map(Post.fromMap).toList();
}
```

The `await` keyword suspends the current function and yields control back to the Flutter event loop, keeping the UI smooth at 60 fps. When the I/O completes, execution resumes from the suspension point.

**`sqflite` runs SQLite on a dedicated background isolate**, so even heavy queries do not block the Dart main isolate.

**`PostsProvider` bridges the database layer to the UI using `ChangeNotifier`:**

```dart
Future<void> loadPosts() async {
  _state = LoadState.loading;
  notifyListeners();           // UI shows shimmer skeleton
  try {
    _posts = await _db.getAllPosts(...);  // async DB call
    _stats = await _db.getStats();
    _state = LoadState.loaded;
  } catch (e) {
    _error = e.toString();
    _state = LoadState.error;
  }
  notifyListeners();           // UI rebuilds with data or error state
}
```

The resulting data flow is fully reactive:

```
User Action
    ↓
PostsProvider method (async)
    ↓
DatabaseHelper → sqflite background isolate → SQLite file
    ↓
Future resolves → _state updated
    ↓
notifyListeners() → UI rebuilds
```

No UI frame is ever blocked.

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.10.8`
- Android / iOS device or emulator

### Run

```bash
cd offline_posts
flutter pub get
flutter run
```

The database is created automatically on first launch with three sample posts pre-seeded.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3 (Material 3, dark theme) |
| Language | Dart |
| Local Database | SQLite via `sqflite` ^2.3.3+1 |
| State Management | `ChangeNotifier` + `ListenableBuilder` |
| Navigation | `Navigator.push` (named routes) |
| Image Handling | `image_picker` + local file path |
| Animations | `flutter_staggered_animations` + custom shimmer |

---

*University of Rwanda · College of Science and Technology · ICT · Computer Engineering · Mobile Application · 2025*
