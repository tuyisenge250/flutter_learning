import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isWide;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(post.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.45,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: const Color(0xFF7B61FF),
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppTheme.highlight,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: isWide ? _buildWideCard(context) : _buildNarrowCard(context),
      ),
    );
  }

  Widget _buildWideCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(77),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(width: 220, height: 180, borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))),
          Expanded(child: _buildContent(context, wide: true)),
        ],
      ),
    );
  }

  Widget _buildNarrowCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(77),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.hasImage)
            _buildImageSection(height: 200, borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20))),
          _buildContent(context, wide: false),
        ],
      ),
    );
  }

  Widget _buildImageSection({double? width, double height = 200, BorderRadius? borderRadius}) {
    Widget image;
    if (post.imagePath != null) {
      image = Image.file(File(post.imagePath!),
          fit: BoxFit.cover, width: width, height: height);
    } else if (post.imageUrl != null) {
      image = Image.network(
        post.imageUrl!,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (_, e, st) => _imageFallback(width: width, height: height),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _imageFallback(width: width, height: height, loading: true);
        },
      );
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: Stack(
        children: [
          image,
          if (post.isFeatured)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.highlight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Featured', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imageFallback({double? width, double? height, bool loading = false}) {
    return Container(
      width: width,
      height: height,
      color: AppTheme.accent,
      child: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.image_rounded, color: AppTheme.textSecondary, size: 40),
    );
  }

  Widget _buildContent(BuildContext context, {required bool wide}) {
    final catColor = AppTheme.categoryColor(post.category);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withAlpha(51),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: catColor.withAlpha(128), width: 1),
                ),
                child: Text(post.category,
                    style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: post.status == 'published'
                      ? AppTheme.success.withAlpha(38)
                      : AppTheme.draft.withAlpha(38),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  post.status == 'published' ? 'Published' : 'Draft',
                  style: TextStyle(
                    color: post.status == 'published' ? AppTheme.success : AppTheme.draft,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!post.hasImage && post.isFeatured) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded, color: AppTheme.highlight, size: 16),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
            maxLines: wide ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            post.body,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            maxLines: wide ? 4 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.tags
                  .take(4)
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withAlpha(128),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('#$tag',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(post.author,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM d, yyyy').format(post.updatedAt),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
