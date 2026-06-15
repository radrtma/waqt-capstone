import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/community_service.dart';
import '../config/api_config.dart';
import 'post_detail_screen.dart';
import 'compose_post_screen.dart';

class CommunityScreen extends StatefulWidget {
  final String currentUsername;
  final Function(int)? onTabChanged;
  final bool showOnlyOwnPosts;

  const CommunityScreen({
    super.key,
    required this.currentUsername,
    this.onTabChanged,
    this.showOnlyOwnPosts = false,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'reflection', 'mosque', 'event'

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      List<String>? types;
      if (_selectedFilter != 'all') {
        types = [_selectedFilter];
      }
      var posts = await _communityService.fetchPosts(types: types);
      
      if (widget.showOnlyOwnPosts) {
        posts = posts.where((p) => p['username'] == widget.currentUsername).toList();
      }

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter != filter) {
      setState(() {
        _selectedFilter = filter;
      });
      _loadPosts();
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
          widget.showOnlyOwnPosts ? 'Kiriman Saya' : 'Diskusi Komunitas',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: bgSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryColor),
            onPressed: _loadPosts,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ComposePostScreen(),
            ),
          );
          if (result == true) {
            _loadPosts();
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note_rounded),
        label: Text('Tulis Kiriman', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.showOnlyOwnPosts) _buildFilterBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPosts,
                color: primaryColor,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : _posts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _posts.length,
                            itemBuilder: (context, index) {
                              return _buildPostCard(_posts[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('all', 'Semua'),
          _buildFilterChip('reflection', 'Refleksi'),
          _buildFilterChip('mosque', 'Ulasan Masjid'),
          _buildFilterChip('event', 'Kegiatan / Event'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    const primaryColor = Color(0xFF1F6F5B);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _onFilterChanged(value),
        selectedColor: primaryColor,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isSelected ? primaryColor : primaryColor.withOpacity(0.12),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada kiriman.',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Jadilah yang pertama membagikan refleksi spiritual atau ulasan masjid terdekat!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final String username = post['username'] ?? 'Anonymous';
    final String content = post['content'] ?? '';
    final String postType = post['post_type'] ?? 'reflection';
    final String createdAt = post['created_at'] ?? '';
    final List<dynamic> imagePaths = post['image_paths'] ?? [];

    String dateStr = '';
    try {
      if (createdAt.isNotEmpty) {
        final parsed = DateTime.parse(createdAt).toLocal();
        dateStr = DateFormat('d MMM yyyy, HH:mm').format(parsed);
      }
    } catch (_) {}

    String typeLabel = 'Refleksi';
    IconData typeIcon = Icons.auto_awesome;
    Color typeColor = const Color(0xFF1F6F5B);

    if (postType == 'mosque') {
      typeLabel = 'Ulasan Masjid';
      typeIcon = Icons.mosque_rounded;
      typeColor = const Color(0xFF2D9CDB);
    } else if (postType == 'event') {
      typeLabel = 'Event Komunitas';
      typeIcon = Icons.event_note_rounded;
      typeColor = const Color(0xFFF2994A);
    }

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _navigateToDetail(post),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: typeColor.withOpacity(0.1),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'A',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: typeColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              username,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B)),
                            ),
                            if (widget.currentUsername == username) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Anda',
                                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                ),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 12, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Content Specifics
              if (postType == 'mosque') _buildMosqueSpec(post),
              if (postType == 'event') _buildEventSpec(post),

              // Main Post Content
              Text(
                content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.5,
                ),
              ),

              // Images Carousel / List
              if (imagePaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildImagesCarousel(imagePaths),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Footer Actions: reactions + comments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildReactionsRow(post),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${post['comment_count'] ?? 0} Komentar',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMosqueSpec(Map<String, dynamic> post) {
    final String mosqueName = post['mosque_name'] ?? '';
    final bool isWuduClean = post['is_wudu_clean'] == true || post['is_wudu_clean'] == 1;
    final bool isAcWorking = post['is_ac_working'] == true || post['is_ac_working'] == 1;
    final bool isFemaleFriendly = post['is_female_friendly'] == true || post['is_female_friendly'] == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2D9CDB)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                mosqueName,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF2D9CDB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildMosqueTag(isWuduClean, 'Tempat Wudhu Bersih'),
            _buildMosqueTag(isAcWorking, 'AC Dingin'),
            _buildMosqueTag(isFemaleFriendly, 'Ramah Perempuan'),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMosqueTag(bool active, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2D9CDB).withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? const Color(0xFF2D9CDB).withOpacity(0.2) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 11,
            color: active ? const Color(0xFF2D9CDB) : Colors.grey.shade400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: active ? const Color(0xFF2D9CDB) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSpec(Map<String, dynamic> post) {
    final String eventName = post['event_name'] ?? '';
    final String eventDate = post['event_date'] ?? '';
    final String eventLocation = post['event_location'] ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2994A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2994A).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📅 $eventName',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFE2822B)),
          ),
          const SizedBox(height: 6),
          if (eventDate.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  eventDate,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          if (eventLocation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.pin_drop_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    eventLocation,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildImagesCarousel(List<dynamic> imagePaths) {
    // If there is only 1 image
    if (imagePaths.length == 1) {
      final imgUrl = '${ApiConfig.baseUrl}/${imagePaths[0]}';
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imgUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 100,
            color: Colors.grey.shade100,
            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
          ),
        ),
      );
    }

    // Multiple images displayed horizontally
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          final imgUrl = '${ApiConfig.baseUrl}/${imagePaths[index]}';
          return Container(
            margin: const EdgeInsets.only(right: 8),
            width: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReactionsRow(Map<String, dynamic> post) {
    final int postId = post['id'];
    return Row(
      children: [
        _buildReactionItem(postId, 'inspiring', '💡', post['inspiring_count'] ?? 0),
        const SizedBox(width: 8),
        _buildReactionItem(postId, 'helpful', '🤝', post['helpful_count'] ?? 0),
        const SizedBox(width: 8),
        _buildReactionItem(postId, 'useful', '📌', post['useful_count'] ?? 0),
      ],
    );
  }

  Widget _buildReactionItem(int postId, String type, String emoji, int count) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final result = await _communityService.reactToPost(postId, type);
        if (result != null) {
          setState(() {
            // Update in local list
            final postIndex = _posts.indexWhere((p) => p['id'] == postId);
            if (postIndex != -1) {
              _posts[postIndex]['inspiring_count'] = result['inspiring_count'];
              _posts[postIndex]['helpful_count'] = result['helpful_count'];
              _posts[postIndex]['useful_count'] = result['useful_count'];
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          post: post,
          currentUsername: widget.currentUsername,
        ),
      ),
    );
    if (result == true) {
      _loadPosts();
    }
  }
}
