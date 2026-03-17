import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class PostsListScreen extends StatefulWidget {
  const PostsListScreen({super.key});

  @override
  State<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  final ApiService _api = ApiService();
  late Future<List<Post>> _postsFuture;
  List<Post> _allPosts = [];
  List<Post> _filtered = [];
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  int? _selectedUserId; // null = All

  @override
  void initState() {
    super.initState();
    _postsFuture = _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<List<Post>> _loadPosts() async {
    final posts = await _api.fetchPosts();
    _allPosts = posts;
    _applyFilters();
    return posts;
  }

  Future<void> _refresh() async {
    setState(() {
      _searchController.clear();
      _selectedUserId = null;
      _postsFuture = _loadPosts();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _allPosts.where((p) {
        final matchesUser =
            _selectedUserId == null || p.userId == _selectedUserId;
        final matchesQuery = query.isEmpty ||
            p.title.toLowerCase().contains(query) ||
            p.body.toLowerCase().contains(query);
        return matchesUser && matchesQuery;
      }).toList();
    });
  }

  List<int> get _availableUsers {
    return _allPosts.map((p) => p.userId).toSet().toList()..sort();
  }

  Future<void> _deletePost(Post post, int index) async {
    try {
      await _api.deletePost(post.id!);
      setState(() {
        _allPosts.removeWhere((p) => p.id == post.id);
        _filtered.removeAt(index);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post deleted'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _postsFuture = _loadPosts());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Color _userColor(int userId) {
    const colors = [
      Colors.indigo, Colors.teal, Colors.deepOrange, Colors.purple,
      Colors.green, Colors.pink, Colors.blue, Colors.amber,
      Colors.cyan, Colors.red,
    ];
    return colors[(userId - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Posts Manager',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (_allPosts.isNotEmpty)
              Text(
                '${_allPosts.length} posts · ${_availableUsers.length} users',
                style:
                    const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        // Search + filter bar baked into the AppBar bottom
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                // ── Search field ────────────────────────────────────────
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search by title or content...',
                      hintStyle:
                          const TextStyle(color: Colors.white60, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.white70, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white70, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                ),
                const SizedBox(height: 8),

                // ── User filter chips ───────────────────────────────────
                SizedBox(
                  height: 32,
                  child: _allPosts.isEmpty
                      ? const SizedBox.shrink()
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // "All" chip
                            _UserChip(
                              label: 'All',
                              color: Colors.white,
                              selected: _selectedUserId == null,
                              onTap: () {
                                setState(() => _selectedUserId = null);
                                _applyFilters();
                              },
                            ),
                            const SizedBox(width: 6),
                            // One chip per user
                            ..._availableUsers.map((uid) {
                              final color = _userColor(uid);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _UserChip(
                                  label: 'User $uid',
                                  color: color,
                                  selected: _selectedUserId == uid,
                                  onTap: () {
                                    setState(() => _selectedUserId ==
                                            uid
                                        ? _selectedUserId = null
                                        : _selectedUserId = uid);
                                    _applyFilters();
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _SkeletonLoader();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          // Active filter summary
          final hasActiveFilter = _selectedUserId != null ||
              _searchController.text.trim().isNotEmpty;

          if (_filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off,
                        size: 72, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _buildEmptyMessage(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _selectedUserId = null);
                        _searchController.clear();
                        _applyFilters();
                      },
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Results summary bar
              if (hasActiveFilter)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _buildResultSummary(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedUserId = null);
                          _searchController.clear();
                          _applyFilters();
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Post list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final post = _filtered[index];
                      final color = _userColor(post.userId);

                      return Dismissible(
                        key: ValueKey(post.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_forever,
                                  color: Colors.white, size: 28),
                              SizedBox(height: 4),
                              Text('Delete',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text(
                                  'Are you sure you want to delete this post?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) => _deletePost(post, index),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final updated = await Navigator.push<Post>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PostDetailScreen(post: post),
                                ),
                              );
                              if (updated != null) {
                                setState(() {
                                  final i = _allPosts
                                      .indexWhere((p) => p.id == updated.id);
                                  if (i != -1) _allPosts[i] = updated;
                                  final j = _filtered
                                      .indexWhere((p) => p.id == updated.id);
                                  if (j != -1) _filtered[j] = updated;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                // Colored accent bar
                                Container(
                                  width: 5,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                    alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'User ${post.userId}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: color,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '#${post.id}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme.outline,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        _highlightText(
                                          post.title,
                                          _searchController.text,
                                          baseStyle: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          post.body,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.grey),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<Post>(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (created != null) {
            setState(() {
              _allPosts.insert(0, created);
              _applyFilters();
            });
          }
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('New Post'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  String _buildEmptyMessage() {
    if (_selectedUserId != null && _searchController.text.trim().isNotEmpty) {
      return 'No posts from User $_selectedUserId matching\n"${_searchController.text.trim()}"';
    } else if (_selectedUserId != null) {
      return 'No posts found for User $_selectedUserId';
    } else {
      return 'No posts matching\n"${_searchController.text.trim()}"';
    }
  }

  String _buildResultSummary() {
    final parts = <String>[];
    if (_searchController.text.trim().isNotEmpty) {
      parts.add('"${_searchController.text.trim()}"');
    }
    if (_selectedUserId != null) {
      parts.add('User $_selectedUserId');
    }
    return '${_filtered.length} result${_filtered.length == 1 ? '' : 's'} for ${parts.join(' + ')}';
  }

  // Highlights matching text in search results
  Widget _highlightText(
    String text,
    String query, {
    TextStyle? baseStyle,
    int maxLines = 1,
  }) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: baseStyle?.copyWith(
          backgroundColor: Colors.yellow.shade300,
          color: Colors.black,
        ),
      ));
      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── User filter chip ──────────────────────────────────────────────────────────

class _UserChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _UserChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.4),
            width: selected ? 0 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────

class _SkeletonLoader extends StatefulWidget {
  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _box({double width = double.infinity, double height = 14}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: 8,
      itemBuilder: (_, _) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 70, height: 16),
                    const SizedBox(height: 8),
                    _box(height: 13),
                    const SizedBox(height: 6),
                    _box(width: 200, height: 11),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 72, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
