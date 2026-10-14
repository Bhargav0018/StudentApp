import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/resource_service.dart';

import 'add_resource_screen.dart';
import '../widgets/premium_ui.dart';
import '../widgets/student_navigation.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final AuthService _auth = AuthService.instance;

  final ResourceService _resourceService = ResourceService.instance;

  List<Map<String, dynamic>> _resources = [];

  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD RESOURCES
  // ============================================================

  Future<void> _loadResources() async {
    try {
      final data = await _resourceService.getResources();

      if (!mounted) return;

      setState(() {
        _resources = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage('Unable to load resources.', isError: true);
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<void> _searchResources(String value) async {
    if (value.trim().isEmpty) {
      await _loadResources();
      return;
    }

    try {
      final data = await _resourceService.searchResources(value.trim());

      if (!mounted) return;

      setState(() {
        _resources = data;
      });
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to search resources.', isError: true);
    }
  }

  // ============================================================
  // SAVE / UNSAVE
  // ============================================================

  Future<void> _toggleSave(Map<String, dynamic> resource) async {
    final userId = _auth.currentUserId;

    if (userId == null) {
      _showMessage('Please login to save resources.', isError: true);
      return;
    }

    final resourceId = _safeInt(resource['id']);

    if (resourceId <= 0) {
      return;
    }

    try {
      final alreadySaved = await _resourceService.isResourceSaved(
        userId: userId,
        resourceId: resourceId,
      );

      if (alreadySaved) {
        await _resourceService.unsaveResource(
          userId: userId,
          resourceId: resourceId,
        );

        if (!mounted) return;

        _showMessage('Removed from saved resources.');
      } else {
        await _resourceService.saveResource(
          userId: userId,
          resourceId: resourceId,
        );

        if (!mounted) return;

        _showMessage('Resource saved successfully.');
      }

      if (!mounted) return;

      setState(() {});
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to update saved resource.', isError: true);
    }
  }

  // ============================================================
  // OPEN URL
  // ============================================================

  Future<void> _openUrl(String url) async {
    final cleanUrl = url.trim();

    if (cleanUrl.isEmpty) {
      _showMessage('No resource link available.', isError: true);
      return;
    }

    final uri = Uri.tryParse(cleanUrl);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showMessage('Invalid resource URL.', isError: true);
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        _showMessage('Unable to open resource.', isError: true);
      }
    } catch (_) {
      if (!mounted) return;

      _showMessage('Unable to open resource.', isError: true);
    }
  }

  // ============================================================
  // ADD RESOURCE
  // ============================================================

  Future<void> _openAddResource() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddResourceScreen()),
    );

    if (result == true) {
      await _loadResources();
    }
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  void _showImagePreview(Uint8List bytes, String fileName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(15),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName.isEmpty ? 'Image Preview' : fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // ------------------------------------------------
                // IMAGE
                // ------------------------------------------------
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  void _navigateFromShell(int index) {
    if (index == 3) return;
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    Navigator.pushNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resources',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ========================================================
      // ADD RESOURCE BUTTON
      // ========================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddResource,

        backgroundColor: const Color(0xFF4F46E5),

        foregroundColor: Colors.white,

        icon: const Icon(Icons.add),

        label: const Text(
          'Add Resource',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          // ======================================================
          // SEARCH
          // ======================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),

            child: TextField(
              controller: _searchController,

              onChanged: _searchResources,

              decoration: InputDecoration(
                hintText: 'Search resources...',

                prefixIcon: const Icon(Icons.search),

                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          _loadResources();

                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,

                filled: true,

                fillColor: isDark
                    ? const Color(0xFF20243A)
                    : const Color(0xFFF5F7FB),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ======================================================
          // RESOURCE COUNT
          // ======================================================
          if (!_loading && _resources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_resources.length} resource${_resources.length == 1 ? '' : 's'} found',

                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ======================================================
          // RESOURCE LIST
          // ======================================================
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadResources,

                    child: _resources.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),

                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),

                            itemCount: _resources.length,

                            itemBuilder: (context, index) {
                              return AnimatedReveal(
                                delay: Duration(milliseconds: index * 45),
                                child: _buildResourceCard(
                                  _resources[index],
                                  isDark,
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? StudentBottomNavigation(selectedIndex: 3, onSelected: _navigateFromShell)
          : null,
    );
  }

  // ============================================================
  // RESOURCE CARD
  // ============================================================

  Widget _buildResourceCard(Map<String, dynamic> resource, bool isDark) {
    final title = resource['title']?.toString() ?? 'Untitled Resource';

    final description = resource['description']?.toString() ?? '';

    final category = resource['category']?.toString() ?? 'General';

    final url = resource['resource_url']?.toString() ?? '';

    final userName = resource['user_name']?.toString() ?? 'Student';

    final resourceType =
        resource['resource_type']?.toString().toLowerCase() ?? 'link';

    final fileName = resource['file_name']?.toString() ?? '';

    final mimeType = resource['mime_type']?.toString() ?? '';

    final resourceId = _safeInt(resource['id']);

    final fileData = _getBytes(resource['file_data']);

    return FutureBuilder<bool>(
      future: _getSavedStatus(resourceId),

      builder: (context, snapshot) {
        final isSaved = snapshot.data ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),

            side: BorderSide(
              color: isDark ? const Color(0xFF34395A) : const Color(0xFFE8EAF0),
            ),
          ),

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================================
                // TITLE + SAVE
                // =================================================

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _buildResourceIcon(resourceType),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            'Shared by $userName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: isSaved ? 'Remove from saved' : 'Save resource',

                      onPressed: () => _toggleSave(resource),

                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,

                        color: isSaved ? const Color(0xFF4F46E5) : Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // =================================================
                // IMAGE PREVIEW
                // =================================================
                if (resourceType == 'image' && fileData != null)
                  _buildImagePreview(fileData, fileName),

                // =================================================
                // DESCRIPTION
                // =================================================
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),

                const SizedBox(height: 12),

                // =================================================
                // RESOURCE TYPE + CATEGORY
                // =================================================
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTypeBadge(resourceType, isDark),

                    _buildCategoryBadge(category, isDark),

                    if (isSaved) _buildSavedBadge(),
                  ],
                ),

                // =================================================
                // FILE INFORMATION
                // =================================================
                if (resourceType != 'link' && fileName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildFileInformation(
                      fileName,
                      mimeType,
                      fileData?.length ?? 0,
                      isDark,
                    ),
                  ),

                const SizedBox(height: 12),

                // =================================================
                // ACTION BUTTON
                // =================================================
                _buildResourceAction(resourceType, url, fileData, fileName),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // RESOURCE ICON
  // ============================================================

  Widget _buildResourceIcon(String resourceType) {
    IconData icon;

    switch (resourceType) {
      case 'image':
        icon = Icons.image_outlined;
        break;

      case 'pdf':
        icon = Icons.picture_as_pdf_outlined;
        break;

      case 'document':
        icon = Icons.description_outlined;
        break;

      case 'video':
        icon = Icons.video_library_outlined;
        break;

      case 'file':
        icon = Icons.insert_drive_file_outlined;
        break;

      default:
        icon = Icons.link_outlined;
    }

    return Container(
      width: 50,
      height: 50,

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        ),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Icon(icon, color: Colors.white, size: 26),
    );
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildImagePreview(Uint8List bytes, String fileName) {
    return GestureDetector(
      onTap: () => _showImagePreview(bytes, fileName),

      child: Container(
        width: double.infinity,
        height: 230,

        margin: const EdgeInsets.only(bottom: 14),

        clipBehavior: Clip.antiAlias,

        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F8),

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: const Color(0xFFE4E6EF)),
        ),

        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover),

            // ----------------------------------------------------
            // VIEW IMAGE OVERLAY
            // ----------------------------------------------------
            Positioned(
              right: 12,
              bottom: 12,

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 17),
                    SizedBox(width: 5),
                    Text(
                      'View Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget _buildTypeBadge(String resourceType, bool isDark) {
    String label;

    switch (resourceType) {
      case 'image':
        label = 'IMAGE';
        break;

      case 'pdf':
        label = 'PDF';
        break;

      case 'document':
        label = 'DOCUMENT';
        break;

      case 'video':
        label = 'VIDEO';
        break;

      case 'file':
        label = 'FILE';
        break;

      default:
        label = 'LINK';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF123E3A) : const Color(0xFFDFF7F3),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        label,

        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4F46E5),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY BADGE
  // ============================================================

  Widget _buildCategoryBadge(String category, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF253A35) : const Color(0xFFEAF8F1),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        category,

        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        ),
      ),
    );
  }

  // ============================================================
  // SAVED BADGE
  // ============================================================

  Widget _buildSavedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F1),

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.green),
          SizedBox(width: 4),
          Text(
            'Saved',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILE INFORMATION
  // ============================================================

  Widget _buildFileInformation(
    String fileName,
    String mimeType,
    int bytes,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20243A) : const Color(0xFFF7F8FC),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: isDark ? const Color(0xFF34395A) : const Color(0xFFE7E9F0),
        ),
      ),

      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 20, color: Color(0xFF4F46E5)),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${_formatFileSize(bytes)}${mimeType.isNotEmpty ? ' • $mimeType' : ''}',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESOURCE ACTION
  // ============================================================

  Widget _buildResourceAction(
    String resourceType,
    String url,
    Uint8List? fileData,
    String fileName,
  ) {
    // ----------------------------------------------------------
    // LINK
    // ----------------------------------------------------------

    if (resourceType == 'link') {
      if (url.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        width: double.infinity,

        child: OutlinedButton.icon(
          onPressed: () => _openUrl(url),

          icon: const Icon(Icons.open_in_new),

          label: const Text('Open Resource'),
        ),
      );
    }

    // ----------------------------------------------------------
    // IMAGE
    // ----------------------------------------------------------

    if (resourceType == 'image') {
      if (fileData == null) {
        return _buildUnavailableButton();
      }

      return SizedBox(
        width: double.infinity,

        child: OutlinedButton.icon(
          onPressed: () => _showImagePreview(fileData, fileName),

          icon: const Icon(Icons.visibility_outlined),

          label: const Text('View Image'),
        ),
      );
    }

    // ----------------------------------------------------------
    // PDF
    // ----------------------------------------------------------

    if (resourceType == 'pdf') {
      return _buildFileStoredButton(
        Icons.picture_as_pdf_outlined,
        'PDF Resource',
      );
    }

    // ----------------------------------------------------------
    // DOCUMENT
    // ----------------------------------------------------------

    if (resourceType == 'document') {
      return _buildFileStoredButton(
        Icons.description_outlined,
        'Document Resource',
      );
    }

    // ----------------------------------------------------------
    // VIDEO
    // ----------------------------------------------------------

    if (resourceType == 'video') {
      return _buildFileStoredButton(
        Icons.video_library_outlined,
        'Video Resource',
      );
    }

    // ----------------------------------------------------------
    // OTHER FILE
    // ----------------------------------------------------------

    return _buildFileStoredButton(
      Icons.insert_drive_file_outlined,
      'File Resource',
    );
  }

  // ============================================================
  // FILE STORED BUTTON
  // ============================================================

  Widget _buildFileStoredButton(IconData icon, String text) {
    return SizedBox(
      width: double.infinity,

      child: OutlinedButton.icon(
        onPressed: () {
          _showMessage('$text is stored in SQLite.');
        },

        icon: Icon(icon),

        label: Text(text),
      ),
    );
  }

  // ============================================================
  // UNAVAILABLE BUTTON
  // ============================================================

  Widget _buildUnavailableButton() {
    return SizedBox(
      width: double.infinity,

      child: OutlinedButton.icon(
        onPressed: null,

        icon: const Icon(Icons.error_outline),

        label: const Text('File Unavailable'),
      ),
    );
  }

  // ============================================================
  // SAVED STATUS
  // ============================================================

  Future<bool> _getSavedStatus(int resourceId) async {
    final userId = _auth.currentUserId;

    if (userId == null || resourceId <= 0) {
      return false;
    }

    return await _resourceService.isResourceSaved(
      userId: userId,
      resourceId: resourceId,
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      children: const [
        SizedBox(height: 130),

        Icon(Icons.library_books_outlined, size: 75, color: Colors.grey),

        SizedBox(height: 18),

        Center(
          child: Text(
            'No resources found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        SizedBox(height: 8),

        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),

            child: Text(
              'Be the first student to share a useful learning resource.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF4F46E5),
      ),
    );
  }

  // ============================================================
  // SAFE INT
  // ============================================================

  int _safeInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // GET BYTES
  // ============================================================

  Uint8List? _getBytes(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Uint8List) {
      return value;
    }

    if (value is List<int>) {
      return Uint8List.fromList(value);
    }

    if (value is List) {
      try {
        return Uint8List.fromList(value.map((item) => _safeInt(item)).toList());
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // ============================================================
  // FILE SIZE
  // ============================================================

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return 'Unknown size';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
