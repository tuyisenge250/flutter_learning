# Posts Manager — Flutter Lab 4

**Course:** Mobile Application Development
**Lab:** 4 — Consuming APIs in Flutter
**API:** [JSONPlaceholder](https://jsonplaceholder.typicode.com/posts)

---

## Overview

Posts Manager is a Flutter mobile application that allows staff at a small media company to view, create, edit, and delete posts through a REST API. The backend is simulated using JSONPlaceholder, a free fake API for testing and prototyping.

---

## Demo

[![Posts Manager Demo](https://img.youtube.com/vi/OoehudSKMoI/0.jpg)](https://youtube.com/shorts/OoehudSKMoI?feature=share)

> Click the thumbnail above to watch the demo video.

---

## Features

| Feature          | Description                                                    |
| ---------------- | -------------------------------------------------------------- |
| View all posts   | Fetches and lists 100 posts from the API                       |
| Search posts     | Real-time search by title or content with keyword highlighting |
| Filter by user   | Chips to filter posts by User ID                               |
| View post detail | Collapsing header with full post content                       |
| Create a post    | Form with validation, sends POST request to API                |
| Edit a post      | Pre-filled form, unsaved-changes guard, sends PUT request      |
| Delete a post    | Swipe-to-delete or button, with confirmation dialog            |
| Pull to refresh  | Drag down to reload posts from API                             |
| Skeleton loading | Animated placeholder cards while data is loading               |
| Error handling   | Network/timeout errors shown with retry button                 |

---

## Project Structure

```
lib/
├── main.dart                      # App entry point, theme setup
├── models/
│   └── post.dart                  # Post data model (fromJson, toJson, copyWith)
├── services/
│   └── api_service.dart           # All HTTP calls (GET, POST, PUT, DELETE)
└── screens/
    ├── posts_list_screen.dart     # Home screen — list, search, filter, delete
    ├── post_detail_screen.dart    # Detail view with SliverAppBar
    ├── create_post_screen.dart    # Create new post form
    └── edit_post_screen.dart      # Edit existing post form
```

---

## Dependencies

| Package         | Version  | Why                                                                                                           |
| --------------- | -------- | ------------------------------------------------------------------------------------------------------------- |
| `http`          | ^1.2.2   | Sends HTTP requests (GET, POST, PUT, DELETE). Lightweight, official Dart package — no code generation needed. |
| `flutter` (SDK) | built-in | UI framework                                                                                                  |

> No extra state management package was used. Flutter's built-in `setState` and `FutureBuilder` are sufficient for this scale of app.

---

## API Endpoints Used

| Method   | Endpoint     | Action                  |
| -------- | ------------ | ----------------------- |
| `GET`    | `/posts`     | Fetch all posts         |
| `GET`    | `/posts/:id` | Fetch a single post     |
| `POST`   | `/posts`     | Create a new post       |
| `PUT`    | `/posts/:id` | Update an existing post |
| `DELETE` | `/posts/:id` | Delete a post           |

**Base URL:** `https://jsonplaceholder.typicode.com/posts`

---

## Post Data Model

```json
{
  "id": 1,
  "userId": 1,
  "title": "sunt aut facere repellat provident",
  "body": "quia et suscipit suscipit recusandae..."
}
```

Dart model — `lib/models/post.dart`:

```dart
class Post {
  final int? id;       // null when creating (server assigns it)
  final int userId;
  final String title;
  final String body;
}
```

---

## How API Exceptions Are Handled

Every method in `ApiService` wraps its HTTP call in a `try/catch` block that handles three specific failure types:

| Exception          | Cause                       | User Message                                         |
| ------------------ | --------------------------- | ---------------------------------------------------- |
| `SocketException`  | No internet connection      | "No internet connection. Please check your network." |
| `TimeoutException` | Server too slow (> 15s)     | "Request timed out. Please try again."               |
| HTTP 4xx / 5xx     | Bad request or server error | "Failed to [action] (HTTP [code])."                  |
| Any other          | Unexpected Dart error       | "Unexpected error: ..."                              |

A custom `ApiException` class is thrown in all cases so the UI only needs to catch one type:

```dart
try {
  final posts = await _api.fetchPosts();
  // use posts
} on ApiException catch (e) {
  // show e.message to the user
}
```

**Android-specific fix:** Cloudflare (which backs JSONPlaceholder) blocks Dart's default `User-Agent` header (`Dart/3.x`) on Android with HTTP 403. All requests include an overridden User-Agent:

```dart
'User-Agent': 'Mozilla/5.0 (Linux; Android 10) Flutter/3.0'
```

---

## FutureBuilder — How It Works

`FutureBuilder` is a Flutter widget that rebuilds its UI automatically based on the state of an asynchronous operation (`Future`).

It was used in `PostsListScreen` to load and display posts:

```dart
FutureBuilder<List<Post>>(
  future: _postsFuture,        // the async operation
  builder: (context, snapshot) {

    // 1. Still loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _SkeletonLoader();
    }

    // 2. Error occurred
    if (snapshot.hasError) {
      return _ErrorState(error: snapshot.error.toString(), ...);
    }

    // 3. Data ready
    final posts = snapshot.data!;
    return ListView.builder(...);
  },
)
```

### The three states and what the UI shows:

| `ConnectionState`   | `snapshot` state | UI shown                            |
| ------------------- | ---------------- | ----------------------------------- |
| `waiting`           | No data yet      | Animated skeleton cards             |
| `done` + `hasError` | Error occurred   | Error icon + message + Retry button |
| `done` + `hasData`  | Posts loaded     | Scrollable list of post cards       |

### What part of the UI depends on the Future:

The **entire body** of `PostsListScreen` is driven by `FutureBuilder`. Nothing in the list is rendered until the Future resolves. Once resolved, the posts are stored in `_allPosts` and `_filtered`, allowing search and user-filter operations to work locally without re-fetching from the API.

---

## Report

The full lab report is available as a PDF:

[consuming_api.pdf](report/consuming_api.pdf)

---

## Android Setup

`android/app/src/main/AndroidManifest.xml` must include:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Without this, Android blocks all network calls silently.

---

## How to Run

```bash
# Install dependencies
flutter pub get

# Run on connected Android device or emulator
flutter run

# Run on Chrome (web)
flutter run -d chrome
```

**Requirements:** Flutter 3.x · Dart 3.x · Android device or emulator with internet access.

---

## Lab Discussion Questions (Paper)

### 1. Which dependencies did you use and why?

**`http: ^1.2.2`** — The official Dart HTTP client package. It was chosen because:

- It is lightweight and straightforward — no build_runner or code generation required
- It provides all necessary HTTP methods: GET, POST, PUT, DELETE
- It is maintained by the Dart team and widely used in Flutter production apps
- For a project of this size, heavier alternatives like `dio` are unnecessary

### 2. How can you handle API exceptions (network errors, invalid data)?

Three layers of handling are used:

1. **`SocketException`** — catches no-internet situations before any request completes
2. **`TimeoutException`** — catches slow/unresponsive servers using `.timeout(Duration(seconds: 15))`
3. **HTTP status codes** — `_checkStatus()` checks the response code and throws `ApiException` for 4xx/5xx
4. **`ApiException`** — a custom exception class that unifies all error types so the UI only handles one type

### 3. Explain the FutureBuilder widget and which part of the UI depends on it

`FutureBuilder` is a widget that listens to a `Future` and rebuilds its subtree each time the future's state changes. It exposes an `AsyncSnapshot` that carries the connection state, data, and error.

In this app, `FutureBuilder<List<Post>>` wraps the entire body of the home screen. The snapshot has three meaningful states:

- **`ConnectionState.waiting`** → shows `_SkeletonLoader` (animated placeholder cards)
- **`snapshot.hasError`** → shows `_ErrorState` with the error message and a retry button
- **`snapshot.hasData`** → renders `ListView.builder` with the loaded posts

Once the data is loaded, search and user-filter operations work on the local `_filtered` list without triggering the Future again, keeping the UI fast and responsive.
