import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/community_service.dart';
import '../config/api_config.dart';

class ComposePostScreen extends StatefulWidget {
  final Map<String, dynamic>? post; // Pass this if editing

  const ComposePostScreen({super.key, this.post});

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  final CommunityService _communityService = CommunityService();
  final ImagePicker _picker = ImagePicker();

  late bool _isEditMode;
  String _selectedType = 'reflection'; // 'reflection', 'mosque', 'event'

  final _contentController = TextEditingController();
  
  // Mosque fields
  final _mosqueNameController = TextEditingController();
  bool _isWuduClean = false;
  bool _isAcWorking = false;
  bool _isFemaleFriendly = false;

  // Event fields
  final _eventNameController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventLocationController = TextEditingController();

  // Images state
  List<File> _selectedFiles = [];
  List<dynamic> _existingImagePaths = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.post != null;
    if (_isEditMode) {
      final post = widget.post!;
      _selectedType = post['post_type'] ?? 'reflection';
      _contentController.text = post['content'] ?? '';
      
      if (_selectedType == 'mosque') {
        _mosqueNameController.text = post['mosque_name'] ?? '';
        _isWuduClean = post['is_wudu_clean'] == true || post['is_wudu_clean'] == 1;
        _isAcWorking = post['is_ac_working'] == true || post['is_ac_working'] == 1;
        _isFemaleFriendly = post['is_female_friendly'] == true || post['is_female_friendly'] == 1;
      } else if (_selectedType == 'event') {
        _eventNameController.text = post['event_name'] ?? '';
        _eventDateController.text = post['event_date'] ?? '';
        _eventLocationController.text = post['event_location'] ?? '';
      }
      _existingImagePaths = post['image_paths'] ?? [];
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _mosqueNameController.dispose();
    _eventNameController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeExistingImagePath(int index) {
    setState(() {
      _existingImagePaths.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konten kiriman tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload new image files if any
      List<String> uploadedPaths = [];
      for (var file in _selectedFiles) {
        final path = await _communityService.uploadImage(file);
        if (path != null) {
          uploadedPaths.add(path);
        }
      }

      // 2. Combine with existing image paths if in edit mode
      final List<dynamic> finalImagePaths = [..._existingImagePaths, ...uploadedPaths];

      // 3. Assemble post data
      final Map<String, dynamic> postData = {
        'post_type': _selectedType,
        'content': content,
        'image_paths': finalImagePaths.isNotEmpty ? finalImagePaths : null,
      };

      if (_selectedType == 'mosque') {
        postData['mosque_name'] = _mosqueNameController.text.trim();
        postData['is_wudu_clean'] = _isWuduClean;
        postData['is_ac_working'] = _isAcWorking;
        postData['is_female_friendly'] = _isFemaleFriendly;
      } else if (_selectedType == 'event') {
        postData['event_name'] = _eventNameController.text.trim();
        postData['event_date'] = _eventDateController.text.trim();
        postData['event_location'] = _eventLocationController.text.trim();
      }

      bool success;
      if (_isEditMode) {
        success = await _communityService.updatePost(widget.post!['id'], postData);
      } else {
        success = await _communityService.createPost(postData);
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          Navigator.pop(context, true); // Return to feed with success signal
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengirim postingan. Coba lagi.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F6F5B);
    const bgSand = Color(0xFFF5E9DA);

    return Scaffold(
      backgroundColor: bgSand,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Kiriman' : 'Tulis Kiriman Baru',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: bgSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded, color: primaryColor, size: 28),
              onPressed: _submit,
            )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditMode) ...[
                Text(
                  'Pilih Jenis Kiriman',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                _buildTypeSelector(),
                const SizedBox(height: 24),
              ],

              // Specific fields based on type
              if (_selectedType == 'mosque') _buildMosqueFields(),
              if (_selectedType == 'event') _buildEventFields(),

              Text(
                'Tulis Refleksi/Ulasan Anda',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: 6,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tulis cerita Anda di sini...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Image attachment trigger & display
              Text(
                'Lampirkan Foto',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              _buildImageSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _buildTypeButton('reflection', '✨ Refleksi'),
        const SizedBox(width: 8),
        _buildTypeButton('mosque', '🕌 Masjid'),
        const SizedBox(width: 8),
        _buildTypeButton('event', '📅 Event'),
      ],
    );
  }

  Widget _buildTypeButton(String type, String label) {
    final isSelected = _selectedType == type;
    const primaryColor = Color(0xFF1F6F5B);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMosqueFields() {
    const primaryColor = Color(0xFF1F6F5B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Ulasan Masjid',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            controller: _mosqueNameController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Nama Masjid',
              labelStyle: GoogleFonts.inter(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.location_city_rounded, color: primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _buildMosqueToggle('Tempat Wudhu Bersih', _isWuduClean, (v) => setState(() => _isWuduClean = v)),
              _buildMosqueToggle('AC / Kipas Berfungsi', _isAcWorking, (v) => setState(() => _isAcWorking = v)),
              _buildMosqueToggle('Ramah Perempuan / Anak', _isFemaleFriendly, (v) => setState(() => _isFemaleFriendly = v)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMosqueToggle(String label, bool value, Function(bool) onChanged) {
    const primaryColor = Color(0xFF1F6F5B);
    return SwitchListTile(
      title: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildEventFields() {
    const primaryColor = Color(0xFF1F6F5B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Event / Kegiatan',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              TextField(
                controller: _eventNameController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Nama Event',
                  labelStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.event_rounded, color: primaryColor),
                  border: InputBorder.none,
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              TextField(
                controller: _eventDateController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Waktu / Tanggal',
                  labelStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.access_time_rounded, color: primaryColor),
                  border: InputBorder.none,
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              TextField(
                controller: _eventLocationController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Lokasi Event',
                  labelStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.pin_drop_rounded, color: primaryColor),
                  border: InputBorder.none,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildImageSelector() {
    const primaryColor = Color(0xFF1F6F5B);
    return Column(
      children: [
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withOpacity(0.2), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_rounded, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Tambah Foto dari Galeri',
                  style: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Display existing image paths (if editing)
        if (_existingImagePaths.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _existingImagePaths.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemBuilder: (context, index) {
              final imgUrl = '${ApiConfig.baseUrl}/${_existingImagePaths[index]}';
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(imgUrl, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeExistingImagePath(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],

        // Display new picked files
        if (_selectedFiles.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedFiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_selectedFiles[index], fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removeSelectedFile(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
