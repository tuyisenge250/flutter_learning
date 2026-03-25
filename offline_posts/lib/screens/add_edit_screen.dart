import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../providers/posts_provider.dart';
import '../theme/app_theme.dart';

class AddEditScreen extends StatefulWidget {
  final Post? post;
  final PostsProvider provider;

  const AddEditScreen({super.key, this.post, required this.provider});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _tagsCtrl;

  String _category = 'General';
  String _status = 'published';
  bool _isFeatured = false;
  String? _localImagePath;
  bool _saving = false;

  bool get _isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _bodyCtrl = TextEditingController(text: p?.body ?? '');
    _authorCtrl = TextEditingController(text: p?.author ?? '');
    _imageUrlCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _tagsCtrl = TextEditingController(text: p?.tags.join(', ') ?? '');
    _category = p?.category ?? 'General';
    _status = p?.status ?? 'published';
    _isFeatured = p?.isFeatured ?? false;
    _localImagePath = p?.imagePath;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _authorCtrl.dispose();
    _imageUrlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _localImagePath = picked.path;
        _imageUrlCtrl.clear(); // local takes priority
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.accent, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Add Image', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppTheme.highlight),
              title: const Text('Pick from Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.highlight),
              title: const Text('Take a Photo', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            const Divider(color: AppTheme.accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Or paste an image URL:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _imageUrlCtrl,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'https://example.com/image.jpg',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_rounded, color: AppTheme.highlight),
                        onPressed: () {
                          setState(() => _localImagePath = null);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    onSubmitted: (_) {
                      setState(() => _localImagePath = null);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            if (_localImagePath != null || _imageUrlCtrl.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.highlight),
                title: const Text('Remove Image', style: TextStyle(color: AppTheme.highlight)),
                onTap: () {
                  setState(() { _localImagePath = null; _imageUrlCtrl.clear(); });
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final imageUrl = _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim();

    bool success;
    if (_isEditing) {
      final updated = widget.post!.copyWith(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        category: _category,
        imagePath: _localImagePath,
        imageUrl: _localImagePath != null ? null : imageUrl,
        isFeatured: _isFeatured,
        status: _status,
        tags: tags,
      );
      success = await widget.provider.updatePost(updated);
    } else {
      final post = Post(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        category: _category,
        imagePath: _localImagePath,
        imageUrl: _localImagePath != null ? null : imageUrl,
        isFeatured: _isFeatured,
        status: _status,
        tags: tags,
      );
      success = await widget.provider.addPost(post);
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save post'), backgroundColor: AppTheme.highlight),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 700;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.secondary,
        title: Text(_isEditing ? 'Edit Post' : 'New Post'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.highlight)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded, color: AppTheme.highlight),
              label: Text(
                _isEditing ? 'Update' : 'Publish',
                style: const TextStyle(color: AppTheme.highlight, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 900 : double.infinity),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(isWide ? 32 : 16),
              children: [
                _buildImagePicker(),
                const SizedBox(height: 20),
                _buildField(
                  controller: _titleCtrl,
                  label: 'Title',
                  hint: 'Enter post title...',
                  icon: Icons.title_rounded,
                  maxLines: 2,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _authorCtrl,
                  label: 'Author',
                  hint: 'Enter author name...',
                  icon: Icons.person_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Author is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _bodyCtrl,
                  label: 'Content',
                  hint: 'Write your post content here...',
                  icon: Icons.article_rounded,
                  maxLines: isWide ? 16 : 10,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _tagsCtrl,
                  label: 'Tags',
                  hint: 'flutter, mobile, news (comma separated)',
                  icon: Icons.tag_rounded,
                ),
                const SizedBox(height: 20),
                _buildFeaturedToggle(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: Icon(_isEditing ? Icons.save_rounded : Icons.publish_rounded),
                    label: Text(_isEditing ? 'Update Post' : 'Publish Post',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _localImagePath != null || _imageUrlCtrl.text.isNotEmpty;
    return GestureDetector(
      onTap: _showImageOptions,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppTheme.highlight.withAlpha(128) : AppTheme.accent,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _buildImagePreview(hasImage),
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool hasImage) {
    if (_localImagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(_localImagePath!), fit: BoxFit.cover),
          Positioned(
            bottom: 8,
            right: 8,
            child: _editImageBtn(),
          ),
        ],
      );
    }
    if (_imageUrlCtrl.text.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrlCtrl.text,
            fit: BoxFit.cover,
            errorBuilder: (_, e, st) => _imagePlaceholder(),
          ),
          Positioned(bottom: 8, right: 8, child: _editImageBtn()),
        ],
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, size: 56, color: AppTheme.highlight.withAlpha(179)),
        const SizedBox(height: 12),
        const Text('Tap to add image', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Gallery · Camera · URL', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _editImageBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(153),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_category),
      initialValue: _category,
      dropdownColor: AppTheme.cardBg,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: CircleAvatar(
          radius: 8,
          backgroundColor: AppTheme.categoryColor(_category),
        ).withPadding(const EdgeInsets.all(12)),
      ),
      items: kCategories
          .map((c) => DropdownMenuItem(
                value: c,
                child: Row(children: [
                  CircleAvatar(radius: 6, backgroundColor: AppTheme.categoryColor(c)),
                  const SizedBox(width: 8),
                  Text(c),
                ]),
              ))
          .toList(),
      onChanged: (v) => setState(() => _category = v ?? _category),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_status),
      initialValue: _status,
      dropdownColor: AppTheme.cardBg,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: const InputDecoration(
        labelText: 'Status',
        prefixIcon: Icon(Icons.flag_rounded, color: AppTheme.textSecondary, size: 20),
      ),
      items: const [
        DropdownMenuItem(value: 'published', child: Text('Published')),
        DropdownMenuItem(value: 'draft', child: Text('Draft')),
      ],
      onChanged: (v) => setState(() => _status = v ?? _status),
    );
  }

  Widget _buildFeaturedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFeatured ? AppTheme.highlight.withAlpha(128) : AppTheme.accent,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.star_rounded,
              color: _isFeatured ? AppTheme.highlight : AppTheme.textSecondary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feature this post',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text('Featured posts appear at the top of the list',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeThumbColor: AppTheme.highlight,
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget withPadding(EdgeInsets padding) => Padding(padding: padding, child: this);
}
