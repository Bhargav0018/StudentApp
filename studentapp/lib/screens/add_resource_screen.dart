import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/resource_service.dart';

class AddResourceScreen extends StatefulWidget {
  const AddResourceScreen({super.key});

  @override
  State<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final AuthService _auth = AuthService.instance;
  final ResourceService _resourceService = ResourceService.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _urlController = TextEditingController();

  String _selectedCategory = 'Programming';

  // ============================================================
  // RESOURCE TYPE
  // ============================================================

  String _selectedResourceType = 'link';

  Uint8List? _selectedFileBytes;

  String? _selectedFileName;

  String? _selectedMimeType;

  bool _saving = false;

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<String> _categories = [
    'Programming',
    'Web Development',
    'Mobile Development',
    'Database',
    'Java',
    'Python',
    'Flutter',
    'Data Science',
    'AI & Machine Learning',
    'Cloud',
    'Interview Preparation',
    'Study Materials',
    'Other',
  ];

  // ============================================================
  // RESOURCE TYPES
  // ============================================================

  final List<Map<String, dynamic>> _resourceTypes = [
    {
      'type': 'link',
      'title': 'Link',
      'subtitle': 'Website or online resource',
      'icon': Icons.link,
    },
    {
      'type': 'image',
      'title': 'Image',
      'subtitle': 'Photos, diagrams or screenshots',
      'icon': Icons.image_outlined,
    },
    {
      'type': 'pdf',
      'title': 'PDF',
      'subtitle': 'PDF notes, books or documents',
      'icon': Icons.picture_as_pdf_outlined,
    },
    {
      'type': 'document',
      'title': 'Document',
      'subtitle': 'Word, text or other documents',
      'icon': Icons.description_outlined,
    },
    {
      'type': 'video',
      'title': 'Video',
      'subtitle': 'Video learning material',
      'icon': Icons.video_library_outlined,
    },
    {
      'type': 'file',
      'title': 'Other File',
      'subtitle': 'Any other supported file',
      'icon': Icons.insert_drive_file_outlined,
    },
  ];

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();

    super.dispose();
  }

  // ============================================================
  // RESOURCE TYPE
  // ============================================================

  void _changeResourceType(String type) {
    if (_saving) return;

    setState(() {
      _selectedResourceType = type;

      // Clear selected file when changing type.
      _selectedFileBytes = null;
      _selectedFileName = null;
      _selectedMimeType = null;

      // Clear URL when changing away from link.
      if (type != 'link') {
        _urlController.clear();
      }
    });
  }

  // ============================================================
  // PICK FILE
  // ============================================================

  Future<void> _pickFile() async {
    if (_saving) return;

    try {
      FileType fileType = FileType.any;

      List<String>? allowedExtensions;

      // --------------------------------------------------------
      // IMAGE
      // --------------------------------------------------------

      if (_selectedResourceType == 'image') {
        fileType = FileType.custom;

        allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
      }
      // --------------------------------------------------------
      // PDF
      // --------------------------------------------------------
      else if (_selectedResourceType == 'pdf') {
        fileType = FileType.custom;

        allowedExtensions = ['pdf'];
      }
      // --------------------------------------------------------
      // DOCUMENT
      // --------------------------------------------------------
      else if (_selectedResourceType == 'document') {
        fileType = FileType.custom;

        allowedExtensions = ['doc', 'docx', 'txt', 'rtf', 'odt'];
      }
      // --------------------------------------------------------
      // VIDEO
      // --------------------------------------------------------
      else if (_selectedResourceType == 'video') {
        fileType = FileType.custom;

        allowedExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
      }

      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;

      if (file.bytes == null || file.bytes!.isEmpty) {
        _showMessage('Unable to read the selected file.', isError: true);

        return;
      }

      // --------------------------------------------------------
      // BASIC SIZE CHECK
      // --------------------------------------------------------

      const maxFileSize = 25 * 1024 * 1024;

      if (file.bytes!.length > maxFileSize) {
        _showMessage(
          'File is too large. Maximum size is 25 MB.',
          isError: true,
        );

        return;
      }

      if (!mounted) return;

      setState(() {
        _selectedFileBytes = file.bytes;

        _selectedFileName = file.name;

        _selectedMimeType = file.extension != null
            ? _detectMimeType(file.extension!.toLowerCase())
            : 'application/octet-stream';
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('Unable to select file.', isError: true);
    }
  }

  // ============================================================
  // MIME TYPE
  // ============================================================

  String _detectMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'gif':
        return 'image/gif';

      case 'webp':
        return 'image/webp';

      case 'bmp':
        return 'image/bmp';

      case 'pdf':
        return 'application/pdf';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'txt':
        return 'text/plain';

      case 'rtf':
        return 'application/rtf';

      case 'odt':
        return 'application/vnd.oasis.opendocument.text';

      case 'mp4':
        return 'video/mp4';

      case 'mov':
        return 'video/quicktime';

      case 'avi':
        return 'video/x-msvideo';

      case 'mkv':
        return 'video/x-matroska';

      case 'webm':
        return 'video/webm';

      default:
        return 'application/octet-stream';
    }
  }

  // ============================================================
  // REMOVE FILE
  // ============================================================

  void _removeSelectedFile() {
    if (_saving) return;

    setState(() {
      _selectedFileBytes = null;
      _selectedFileName = null;
      _selectedMimeType = null;
    });
  }

  // ============================================================
  // VALIDATE RESOURCE
  // ============================================================

  bool _validateResourceSource() {
    // ----------------------------------------------------------
    // LINK
    // ----------------------------------------------------------

    if (_selectedResourceType == 'link') {
      final url = _urlController.text.trim();

      if (url.isEmpty) {
        _showMessage('Please enter resource URL.', isError: true);

        return false;
      }

      final uri = Uri.tryParse(url);

      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        _showMessage('Please enter a valid URL.', isError: true);

        return false;
      }

      return true;
    }

    // ----------------------------------------------------------
    // FILE
    // ----------------------------------------------------------

    if (_selectedFileBytes == null || _selectedFileBytes!.isEmpty) {
      _showMessage('Please select a file.', isError: true);

      return false;
    }

    return true;
  }

  // ============================================================
  // ADD RESOURCE
  // ============================================================

  Future<void> _addResource() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_validateResourceSource()) {
      return;
    }

    final userId = _auth.currentUserId;

    if (userId == null) {
      _showMessage('Please login to add a resource.', isError: true);

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _resourceService.addResource(
        userId: userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        url: _selectedResourceType == 'link' ? _urlController.text.trim() : '',
        category: _selectedCategory,
        resourceType: _selectedResourceType,
        fileName: _selectedFileName,
        mimeType: _selectedMimeType,
        fileBytes: _selectedFileBytes,
      );

      if (!mounted) return;

      _showMessage('Resource added successfully.');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage('Unable to add resource.', isError: true);
    }
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Resource',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),

              child: Form(
                key: _formKey,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =================================================
                    // HEADER
                    // =================================================

                    _buildHeader(),

                    const SizedBox(height: 25),

                    // =================================================
                    // TITLE
                    // =================================================
                    const Text(
                      'Resource Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,

                      decoration: InputDecoration(
                        hintText: 'Example: Flutter Complete Course',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter resource title.';
                        }

                        if (value.trim().length < 3) {
                          return 'Title must contain at least 3 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // DESCRIPTION
                    // =================================================
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _descriptionController,

                      minLines: 4,
                      maxLines: 6,

                      decoration: InputDecoration(
                        hintText: 'Explain what this resource is useful for...',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 75),
                          child: Icon(Icons.description_outlined),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description.';
                        }

                        if (value.trim().length < 10) {
                          return 'Description must contain at least 10 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // RESOURCE TYPE
                    // =================================================
                    const Text(
                      'Resource Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    _buildResourceTypeSelector(isDark),

                    const SizedBox(height: 20),

                    // =================================================
                    // LINK OR FILE
                    // =================================================
                    if (_selectedResourceType == 'link')
                      _buildUrlField()
                    else
                      _buildFilePicker(isDark),

                    const SizedBox(height: 20),

                    // =================================================
                    // CATEGORY
                    // =================================================
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,

                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),

                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // INFORMATION CARD
                    // =================================================
                    _buildInformationCard(isDark),

                    const SizedBox(height: 25),

                    // =================================================
                    // ADD BUTTON
                    // =================================================
                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _addResource,

                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),

                        label: Text(
                          _saving ? 'Adding Resource...' : 'Add Resource',

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.20),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: const Row(
        children: [
          Icon(Icons.library_add, color: Colors.white, size: 38),

          SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Share a Resource',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Share links, images, PDFs, documents, videos and useful files with other students.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESOURCE TYPE SELECTOR
  // ============================================================

  Widget _buildResourceTypeSelector(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      itemCount: _resourceTypes.length,

      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 95,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),

      itemBuilder: (context, index) {
        final item = _resourceTypes[index];

        final type = item['type'] as String;

        final selected = _selectedResourceType == type;

        return InkWell(
          borderRadius: BorderRadius.circular(16),

          onTap: () => _changeResourceType(type),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFDFF7F3)
                  : isDark
                  ? const Color(0xFF20243A)
                  : const Color(0xFFF7F8FC),

              borderRadius: BorderRadius.circular(16),

              border: Border.all(
                color: selected
                    ? const Color(0xFF4F46E5)
                    : isDark
                    ? const Color(0xFF34395A)
                    : const Color(0xFFE5E7EF),

                width: selected ? 2 : 1,
              ),
            ),

            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF4F46E5)
                        : isDark
                        ? const Color(0xFF303550)
                        : const Color(0xFFE9EBF5),

                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Icon(
                    item['icon'] as IconData,

                    color: selected ? Colors.white : const Color(0xFF4F46E5),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        item['title'] as String,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        item['subtitle'] as String,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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
  // URL FIELD
  // ============================================================

  Widget _buildUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Resource URL',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _urlController,

          keyboardType: TextInputType.url,

          textInputAction: TextInputAction.done,

          decoration: InputDecoration(
            hintText: 'https://example.com/resource',

            prefixIcon: const Icon(Icons.link),

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),

          validator: (value) {
            if (_selectedResourceType != 'link') {
              return null;
            }

            if (value == null || value.trim().isEmpty) {
              return 'Please enter resource URL.';
            }

            final uri = Uri.tryParse(value.trim());

            if (uri == null ||
                !uri.hasScheme ||
                (uri.scheme != 'http' && uri.scheme != 'https')) {
              return 'Please enter a valid URL.';
            }

            return null;
          },
        ),
      ],
    );
  }

  // ============================================================
  // FILE PICKER
  // ============================================================

  Widget _buildFilePicker(bool isDark) {
    final hasFile = _selectedFileBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          'Select File',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        if (!hasFile)
          InkWell(
            borderRadius: BorderRadius.circular(18),

            onTap: _pickFile,

            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),

              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF20243A)
                    : const Color(0xFFF7F8FC),

                borderRadius: BorderRadius.circular(18),

                border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
              ),

              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,

                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF7F3),
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Color(0xFF4F46E5),
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Choose a File',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Tap here to select a file',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Maximum file size: 25 MB',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          _buildSelectedFileCard(isDark),
      ],
    );
  }

  // ============================================================
  // SELECTED FILE CARD
  // ============================================================

  Widget _buildSelectedFileCard(bool isDark) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20243A) : const Color(0xFFF7F8FC),

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFF4F46E5)),
      ),

      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,

            decoration: BoxDecoration(
              color: const Color(0xFFDFF7F3),

              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              _getFileIcon(),
              color: const Color(0xFF4F46E5),
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  _selectedFileName ?? 'Selected file',

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _getFileSizeText(),

                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Remove file',

            onPressed: _removeSelectedFile,

            icon: const Icon(Icons.close, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILE ICON
  // ============================================================

  IconData _getFileIcon() {
    switch (_selectedResourceType) {
      case 'image':
        return Icons.image_outlined;

      case 'pdf':
        return Icons.picture_as_pdf_outlined;

      case 'document':
        return Icons.description_outlined;

      case 'video':
        return Icons.video_library_outlined;

      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // ============================================================
  // FILE SIZE
  // ============================================================

  String _getFileSizeText() {
    final bytes = _selectedFileBytes?.length ?? 0;

    if (bytes < 1024) {
      return '$bytes bytes';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // ============================================================
  // INFORMATION CARD
  // ============================================================

  Widget _buildInformationCard(bool isDark) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF20243A) : const Color(0xFFEFF4FF),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark ? const Color(0xFF34395A) : const Color(0xFFDDE5FF),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(Icons.info_outline, color: Color(0xFF4F46E5)),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              _selectedResourceType == 'link'
                  ? 'Share only useful and reliable learning links. Other students will be able to view and save your resource.'
                  : 'Your selected file will be stored inside the local SQLite database. Maximum file size is 25 MB.',
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
