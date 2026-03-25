import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/post.dart';
import '../providers/posts_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import 'add_edit_screen.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _provider = PostsProvider();
  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
    _provider.loadPosts();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        _provider.setFilter();
        break;
      case 1:
        _provider.setFilter(status: 'published');
        break;
      case 2:
        _provider.setFilter(status: 'draft');
        break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${post.title}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.highlight),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _provider.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${post.title}" deleted'),
            backgroundColor: AppTheme.highlight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _goToDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id, provider: _provider)),
    );
  }

  void _goToEdit(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(post: post, provider: _provider)),
    );
  }

  void _goToAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(provider: _provider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: _buildAppBar(isWide),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) => _buildBody(isWide),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Post', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  AppBar _buildAppBar(bool isWide) {
    return AppBar(
      backgroundColor: AppTheme.secondary,
      title: _showSearch
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search posts...',
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: _provider.search,
            )
          : const Text('Offline Posts Manager'),
      actions: [
        IconButton(
          icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () {
            setState(() => _showSearch = !_showSearch);
            if (!_showSearch) {
              _searchController.clear();
              _provider.clearSearch();
            }
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list_rounded),
          color: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (cat) => _provider.setFilter(category: cat == 'All' ? null : cat),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'All', child: Text('All Categories')),
            ...kCategories.map((c) => PopupMenuItem(
                  value: c,
                  child: Row(children: [
                    CircleAvatar(backgroundColor: AppTheme.categoryColor(c), radius: 6),
                    const SizedBox(width: 8),
                    Text(c),
                  ]),
                )),
          ],
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.highlight,
        labelColor: AppTheme.highlight,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Published'),
          Tab(text: 'Drafts'),
        ],
      ),
    );
  }

  Widget _buildBody(bool isWide) {
    if (_provider.state == LoadState.loading) return _buildShimmer(isWide);
    if (_provider.state == LoadState.error) return _buildError();

    return Column(
      children: [
        _buildStatsBar(),
        if (_provider.filterCategory != null) _buildFilterChip(),
        Expanded(child: _buildPostList(isWide)),
      ],
    );
  }

  Widget _buildStatsBar() {
    final s = _provider.stats;
    return Container(
      color: AppTheme.secondary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.article_rounded, '${s['total']}', 'Total'),
          _statDivider(),
          _statItem(Icons.check_circle_outline_rounded, '${s['total']! - s['drafts']!}', 'Published'),
          _statDivider(),
          _statItem(Icons.edit_note_rounded, '${s['drafts']}', 'Drafts'),
          _statDivider(),
          _statItem(Icons.star_rounded, '${s['featured']}', 'Featured'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Icon(icon, color: AppTheme.highlight, size: 16),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _statDivider() =>
      Container(height: 30, width: 1, color: AppTheme.accent);

  Widget _buildFilterChip() {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filter:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 8),
          Chip(
            label: Text(_provider.filterCategory!),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: _provider.clearFilters,
            backgroundColor: AppTheme.categoryColor(_provider.filterCategory!).withAlpha(51),
            labelStyle: TextStyle(
                color: AppTheme.categoryColor(_provider.filterCategory!), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList(bool isWide) {
    final posts = _provider.posts;
    if (posts.isEmpty) return _buildEmpty();

    if (isWide) {
      return AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: posts.length,
          itemBuilder: (ctx, i) => AnimationConfiguration.staggeredList(
            position: i,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50,
              child: FadeInAnimation(
                child: PostCard(
                  post: posts[i],
                  isWide: true,
                  onTap: () => _goToDetail(posts[i]),
                  onEdit: () => _goToEdit(posts[i]),
                  onDelete: () => _confirmDelete(posts[i]),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: posts.length,
        itemBuilder: (ctx, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50,
            child: FadeInAnimation(
              child: PostCard(
                post: posts[i],
                onTap: () => _goToDetail(posts[i]),
                onEdit: () => _goToEdit(posts[i]),
                onDelete: () => _confirmDelete(posts[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: AppTheme.accent),
          const SizedBox(height: 16),
          Text(
            _provider.isSearching ? 'No results for "${_provider.searchQuery}"' : 'No posts yet',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (!_provider.isSearching)
            ElevatedButton.icon(
              onPressed: _goToAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Post'),
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 60, color: AppTheme.highlight),
          const SizedBox(height: 12),
          Text(_provider.error, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _provider.loadPosts, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isWide) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 5,
      itemBuilder: (_, i) => _ShimmerCard(isWide: isWide),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final bool isWide;
  const _ShimmerCard({this.isWide = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: isWide ? 180 : 220,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const _ShimmerEffect(),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment(_animation.value - 1, 0),
            end: Alignment(_animation.value, 0),
            colors: [AppTheme.cardBg, AppTheme.surface, AppTheme.cardBg],
          ),
        ),
      ),
    );
  }
}
