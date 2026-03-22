import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../providers/posts_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final PostsProvider provider;

  const PostDetailScreen({super.key, required this.postId, required this.provider});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final post = await widget.provider.getPost(widget.postId);
    if (mounted) setState(() { _post = post; _loading = false; });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Delete this post? This cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary)),
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
    if (confirmed == true && mounted) {
      await widget.provider.deletePost(widget.postId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(child: CircularProgressIndicator(color: AppTheme.highlight)),
      );
    }
    if (_post == null) {
      return Scaffold(
        backgroundColor: AppTheme.primary,
        appBar: AppBar(backgroundColor: AppTheme.secondary),
        body: const Center(
            child: Text('Post not found', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    final post = _post!;
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(post, isWide),
          SliverToBoxAdapter(child: _buildContent(post, isWide, width)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddEditScreen(post: post, provider: widget.provider)),
          );
          _load();
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Edit Post'),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(Post post, bool isWide) {
    return SliverAppBar(
      expandedHeight: post.hasImage ? (isWide ? 400 : 280) : 0,
      pinned: true,
      backgroundColor: AppTheme.secondary,
      foregroundColor: AppTheme.textPrimary,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          color: AppTheme.highlight,
          onPressed: _delete,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: post.hasImage
          ? FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroImage(post),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppTheme.primary.withAlpha(230)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeroImage(Post post) {
    if (post.imagePath != null) {
      return Image.file(File(post.imagePath!), fit: BoxFit.cover);
    }
    return Image.network(
      post.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, e, st) => Container(
        color: AppTheme.accent,
        child: const Icon(Icons.broken_image_rounded, size: 60, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildContent(Post post, bool isWide, double screenWidth) {
    final content = Padding(
      padding: EdgeInsets.all(isWide ? 32 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + Status row
          Row(
            children: [
              _categoryBadge(post),
              const SizedBox(width: 8),
              _statusBadge(post),
              if (post.isFeatured) ...[
                const SizedBox(width: 8),
                _featuredBadge(),
              ],
            ],
          ),
          const SizedBox(height: 16),
          // Title
          Text(post.title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: isWide ? 32 : 24,
                fontWeight: FontWeight.w800,
                height: 1.3,
              )),
          const SizedBox(height: 16),
          // Meta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accent),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, size: 18, color: AppTheme.highlight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(post.author,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(DateFormat('MMM d, yyyy • h:mm a').format(post.createdAt),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (post.updatedAt.difference(post.createdAt).inMinutes > 1) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.update_rounded, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Updated ${DateFormat('MMM d, yyyy • h:mm a').format(post.updatedAt)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Divider(color: AppTheme.accent),
          const SizedBox(height: 24),
          // Body
          SelectableText(
            post.body,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: isWide ? 18 : 16,
              height: 1.8,
              letterSpacing: 0.2,
            ),
          ),
          // Tags
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(color: AppTheme.accent),
            const SizedBox(height: 16),
            const Text('Tags', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.highlight.withAlpha(77)),
                        ),
                        child: Text('#$tag',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );

    if (isWide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _categoryBadge(Post post) {
    final color = AppTheme.categoryColor(post.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Text(post.category,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusBadge(Post post) {
    final isPublished = post.status == 'published';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPublished ? AppTheme.success : AppTheme.draft).withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPublished ? Icons.check_circle_rounded : Icons.edit_rounded,
              size: 14, color: isPublished ? AppTheme.success : AppTheme.draft),
          const SizedBox(width: 4),
          Text(isPublished ? 'Published' : 'Draft',
              style: TextStyle(
                  color: isPublished ? AppTheme.success : AppTheme.draft,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _featuredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.highlight.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: AppTheme.highlight),
          SizedBox(width: 4),
          Text('Featured', style: TextStyle(color: AppTheme.highlight, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
