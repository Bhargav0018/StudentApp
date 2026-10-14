import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/resource_service.dart';

class SavedResourcesScreen extends StatefulWidget {
  const SavedResourcesScreen({super.key});

  @override
  State<SavedResourcesScreen> createState() => _SavedResourcesScreenState();
}

class _SavedResourcesScreenState extends State<SavedResourcesScreen> {
  final ResourceService _resourceService = ResourceService.instance;

  final AuthService _authService = AuthService.instance;

  List<Map<String, dynamic>> _resources = [];

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedResources();
  }

  // ============================================================
  // LOAD SAVED RESOURCES
  // ============================================================

  Future<void> _loadSavedResources() async {
    final userId = _authService.currentUserId;

    if (userId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final resources = await _resourceService.getSavedResources(userId);

      if (!mounted) return;

      setState(() {
        _resources = resources;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load saved resources.', isError: true);
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>> get _filteredResources {
    if (_searchQuery.trim().isEmpty) {
      return _resources;
    }

    final query = _searchQuery.toLowerCase().trim();

    return _resources.where((resource) {
      final title = (resource['title'] ?? '').toString().toLowerCase();

      final description = (resource['description'] ?? '')
          .toString()
          .toLowerCase();

      final category = (resource['category'] ?? '').toString().toLowerCase();

      final type = (resource['resource_type'] ?? '').toString().toLowerCase();

      final fileName = (resource['file_name'] ?? '').toString().toLowerCase();

      return title.contains(query) ||
          description.contains(query) ||
          category.contains(query) ||
          type.contains(query) ||
          fileName.contains(query);
    }).toList();
  }

  // ============================================================
  // REMOVE SAVED RESOURCE
  // ============================================================

  Future<void> _removeSavedResource(Map<String, dynamic> resource) async {
    final userId = _authService.currentUserId;
    final resourceId = _toInt(resource['id']);

    if (userId == null || resourceId == null) {
      return;
    }

    try {
      await _resourceService.unsaveResource(
        userId: userId,
        resourceId: resourceId,
      );

      if (!mounted) return;

      setState(() {
        _resources.removeWhere((item) => _toInt(item['id']) == resourceId);
      });

      _showMessage('Resource removed from saved resources.');
    } catch (e) {
      _showMessage('Failed to remove resource.', isError: true);
    }
  }

  // ============================================================
  // OPEN LINK
  // ============================================================

  Future<void> _openLink(String url) async {
    final value = url.trim();

    if (value.isEmpty) {
      _showMessage('No URL available for this resource.', isError: true);
      return;
    }

    try {
      final uri = Uri.parse(value);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open this link.', isError: true);
      }
    } catch (e) {
      _showMessage('Invalid or unavailable URL.', isError: true);
    }
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  void _showImagePreview(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // FILE INFORMATION
  // ============================================================

  void _showFileInfo(Map<String, dynamic> resource) {
    final type = _getResourceType(resource);

    final fileName = (resource['file_name'] ?? 'Unnamed file').toString();

    final mimeType = (resource['mime_type'] ?? 'Unknown').toString();

    final bytes = _getBytes(resource);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('Resource Information'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Type', type.toUpperCase()),
              const SizedBox(height: 10),
              _infoRow('File', fileName),
              const SizedBox(height: 10),
              _infoRow('Format', mimeType),
              if (bytes != null) ...[
                const SizedBox(height: 10),
                _infoRow('Size', _formatFileSize(bytes.length)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 65,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  // ============================================================
  // RESOURCE ACTION
  // ============================================================

  Widget _buildResourceAction(Map<String, dynamic> resource) {
    final type = _getResourceType(resource);

    // LINK
    if (type == 'link') {
      final url = (resource['resource_url'] ?? '').toString();

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: url.trim().isEmpty ? null : () => _openLink(url),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open Resource'),
        ),
      );
    }

    // IMAGE
    final bytes = _getBytes(resource);

    if (type == 'image' && bytes != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            _showImagePreview(bytes);
          },
          icon: const Icon(Icons.image),
          label: const Text('View Image'),
        ),
      );
    }

    // OTHER FILES
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _showFileInfo(resource);
        },
        icon: Icon(_getResourceIcon(type)),
        label: const Text('View File Details'),
      ),
    );
  }

  // ============================================================
  // IMAGE / TYPE PREVIEW
  // ============================================================

  Widget _buildPreview(Map<String, dynamic> resource) {
    final type = _getResourceType(resource);

    if (type != 'image') {
      return _buildTypePreview(type);
    }

    final bytes = _getBytes(resource);

    if (bytes == null || bytes.isEmpty) {
      return _buildTypePreview(type);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: double.infinity,
        height: 190,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildTypePreview(type);
          },
        ),
      ),
    );
  }

  // ============================================================
  // TYPE PREVIEW
  // ============================================================

  Widget _buildTypePreview(String type) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getResourceIcon(type), size: 50),
            const SizedBox(height: 8),
            Text(
              _getTypeLabel(type),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYPE BADGE
  // ============================================================

  Widget _buildTypeBadge(String type) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.primaryContainer,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getResourceIcon(type), size: 15),
          const SizedBox(width: 5),
          Text(
            _getTypeLabel(type),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESOURCE CARD
  // ============================================================

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final title = (resource['title'] ?? 'Untitled Resource').toString();

    final description = (resource['description'] ?? '').toString();

    final category = (resource['category'] ?? 'Other').toString();

    final userName = (resource['user_name'] ?? 'Unknown User').toString();

    final type = _getResourceType(resource);

    final fileName = (resource['file_name'] ?? '').toString();

    final bytes = _getBytes(resource);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(resource),

            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Remove from saved',
                  onPressed: () {
                    _removeSavedResource(resource);
                  },
                  icon: const Icon(Icons.bookmark_remove),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeBadge(type),
                Chip(
                  avatar: const Icon(Icons.category_outlined, size: 17),
                  label: Text(category),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Shared by $userName',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],

            if (fileName.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(_getResourceIcon(type), size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(fileName, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],

            if (bytes != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatFileSize(bytes.length),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 14),

            _buildResourceAction(resource),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESOURCE TYPE
  // ============================================================

  String _getResourceType(Map<String, dynamic> resource) {
    final value = (resource['resource_type'] ?? 'link')
        .toString()
        .toLowerCase()
        .trim();

    if (value.isEmpty) {
      return 'link';
    }

    return value;
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _getResourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
      case 'photo':
        return Icons.image_outlined;

      case 'pdf':
        return Icons.picture_as_pdf_outlined;

      case 'document':
      case 'doc':
      case 'docx':
        return Icons.description_outlined;

      case 'video':
        return Icons.video_library_outlined;

      case 'audio':
        return Icons.audio_file_outlined;

      case 'link':
      case 'url':
        return Icons.link_outlined;

      case 'file':
      case 'other':
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // ============================================================
  // TYPE LABEL
  // ============================================================

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'image':
      case 'photo':
        return 'IMAGE';

      case 'pdf':
        return 'PDF';

      case 'document':
      case 'doc':
      case 'docx':
        return 'DOCUMENT';

      case 'video':
        return 'VIDEO';

      case 'audio':
        return 'AUDIO';

      case 'link':
      case 'url':
        return 'LINK';

      case 'file':
        return 'FILE';

      case 'other':
      default:
        return 'FILE';
    }
  }

  // ============================================================
  // GET FILE BYTES
  // ============================================================

  Uint8List? _getBytes(Map<String, dynamic> resource) {
    final data = resource['file_data'];

    if (data == null) {
      return null;
    }

    if (data is Uint8List) {
      return data;
    }

    if (data is List<int>) {
      return Uint8List.fromList(data);
    }

    if (data is List) {
      try {
        return Uint8List.fromList(data.map((e) => (e as num).toInt()).toList());
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
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ============================================================
  // SAFE INTEGER
  // ============================================================

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredResources = _filteredResources;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Resources'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadSavedResources,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSavedResources,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search saved resources...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.bookmark),
                          const SizedBox(width: 8),
                          Text(
                            '${filteredResources.length} saved resource${filteredResources.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (filteredResources.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_border,
                                size: 80,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _resources.isEmpty
                                    ? 'No saved resources yet'
                                    : 'No matching resources',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resources.isEmpty
                                    ? 'Save useful resources from the Resources section and they will appear here.'
                                    : 'Try searching with a different keyword.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildResourceCard(filteredResources[index]);
                        }, childCount: filteredResources.length),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
