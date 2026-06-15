import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/community_service.dart';
import '../config/api_config.dart';
import 'compose_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final String currentUsername;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUsername,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  late Map<String, dynamic> _post;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  bool _isReacting = false;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  int? _replyCommentId;
  String? _replyUsername;

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    _loadPostDetails();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetails() async {
    try {
      final detail = await _communityService.fetchPostDetail(_post['id']);
      if (detail != null && mounted) {
        setState(() {
          _post = detail;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _communityService.fetchComments(_post['id']);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _react(String reactionType) async {
    if (_isReacting) return;
    setState(() => _isReacting = true);
    try {
      final result = await _communityService.reactToPost(_post['id'], reactionType);
      if (result != null && mounted) {
        setState(() {
          _post['inspiring_count'] = result['inspiring_count'];
          _post['helpful_count'] = result['helpful_count'];
          _post['useful_count'] = result['useful_count'];
        });
      }
    } finally {
      if (mounted) setState(() => _isReacting = false);
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E9DA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Kiriman', style: GoogleFonts.dmSerifDisplay(color: const Color(0xFF1F6F5B))),
        content: Text('Apakah Anda yakin ingin menghapus kiriman ini selamanya?', style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _communityService.deletePost(_post['id']);
      if (success && mounted) {
        Navigator.pop(context, true); // Go back with refresh signal
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // Reset keyboard and text
    _commentController.clear();
    _commentFocusNode.unfocus();

    bool success;
    if (_replyCommentId != null) {
      success = await _communityService.addReply(_replyCommentId!, text);
    } else {
      success = await _communityService.addComment(_post['id'], text);
    }

    if (success) {
      setState(() {
        _replyCommentId = null;
        _replyUsername = null;
      });
      _loadComments();
      _loadPostDetails(); // update comment_count
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final success = await _communityService.deleteComment(commentId);
    if (success) {
      _loadComments();
      _loadPostDetails();
    }
  }

  Future<void> _deleteReply(int replyId) async {
    final success = await _communityService.deleteReply(replyId);
    if (success) {
      _loadComments();
      _loadPostDetails();
    }
  }

  void _startReply(int commentId, String username) {
    setState(() {
      _replyCommentId = commentId;
      _replyUsername = username;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyCommentId = null;
      _replyUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1F6F5B);
    const bgSand = Color(0xFFF5E9DA);
    final isOwnPost = _post['username'] == widget.currentUsername;

    return Scaffold(
      backgroundColor: bgSand,
      appBar: AppBar(
        title: Text(
          'Detail Kiriman',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: bgSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: isOwnPost
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: primaryColor),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComposePostScreen(post: _post),
                      ),
                    );
                    if (result == true) {
                      _loadPostDetails();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  onPressed: _deletePost,
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainPostCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Komentar (${_post['comment_count'] ?? 0})',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoadingComments
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: primaryColor)))
                        : _buildCommentsSection(),
                  ],
                ),
              ),
            ),
            _buildCommentInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainPostCard() {
    final String username = _post['username'] ?? 'Anonymous';
    final String content = _post['content'] ?? '';
    final String postType = _post['post_type'] ?? 'reflection';
    final String createdAt = _post['created_at'] ?? '';
    final List<dynamic> imagePaths = _post['image_paths'] ?? [];

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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Text(
                      username,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF1E293B)),
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
          const SizedBox(height: 16),

          // Details for Mosque Review and Event
          if (postType == 'mosque') _buildMosqueSpec(_post),
          if (postType == 'event') _buildEventSpec(_post),

          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.6,
            ),
          ),

          // Attached Images
          if (imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: imagePaths.map((path) {
                final imgUrl = '${ApiConfig.baseUrl}/$path';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        color: Colors.grey.shade100,
                        child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Reactions
          Row(
            children: [
              _buildReactionButton('inspiring', '💡', _post['inspiring_count'] ?? 0),
              const SizedBox(width: 10),
              _buildReactionButton('helpful', '🤝', _post['helpful_count'] ?? 0),
              const SizedBox(width: 10),
              _buildReactionButton('useful', '📌', _post['useful_count'] ?? 0),
            ],
          ),
        ],
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
        const SizedBox(height: 14),
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
      margin: const EdgeInsets.only(bottom: 14),
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

  Widget _buildReactionButton(String type, String emoji, int count) {
    return InkWell(
      onTap: () => _react(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            'Belum ada komentar. Tulis yang pertama!',
            style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _comments.length,
        itemBuilder: (context, index) {
          final comment = _comments[index];
          final List<dynamic> replies = comment['replies'] ?? [];
          final isPostAuthor = comment['username'] == _post['username'];
          final isOwnComment = comment['username'] == widget.currentUsername;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCommentTile(
                id: comment['id'],
                username: comment['username'] ?? '',
                content: comment['content'] ?? '',
                createdAt: comment['created_at'] ?? '',
                isPostAuthor: isPostAuthor,
                isOwn: isOwnComment,
                isReply: false,
              ),
              if (replies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 36.0),
                  child: Column(
                    children: replies.map((reply) {
                      final isReplyAuthor = reply['username'] == _post['username'];
                      final isOwnReply = reply['username'] == widget.currentUsername;
                      return _buildCommentTile(
                        id: reply['id'],
                        username: reply['username'] ?? '',
                        content: reply['content'] ?? '',
                        createdAt: reply['created_at'] ?? '',
                        isPostAuthor: isReplyAuthor,
                        isOwn: isOwnReply,
                        isReply: true,
                      );
                    }).toList(),
                  ),
                ),
              if (index < _comments.length - 1)
                const Divider(color: Color(0xFFF1F5F9), height: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentTile({
    required int id,
    required String username,
    required String content,
    required String createdAt,
    required bool isPostAuthor,
    required bool isOwn,
    required bool isReply,
  }) {
    String dateStr = '';
    try {
      if (createdAt.isNotEmpty) {
        final parsed = DateTime.parse(createdAt).toLocal();
        dateStr = DateFormat('d MMM, HH:mm').format(parsed);
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: isPostAuthor ? const Color(0xFF1F6F5B).withOpacity(0.1) : Colors.grey.shade200,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'A',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPostAuthor ? const Color(0xFF1F6F5B) : Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF1E293B)),
                    ),
                    if (isPostAuthor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F6F5B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Author',
                          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (!isReply) ...[
                      GestureDetector(
                        onTap: () => _startReply(id, username),
                        child: Text(
                          'Balas',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1F6F5B), fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isOwn) const SizedBox(width: 12),
                    ],
                    if (isOwn)
                      GestureDetector(
                        onTap: () => isReply ? _deleteReply(id) : _deleteComment(id),
                        child: Text(
                          'Hapus',
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade600, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInputArea() {
    const primaryColor = Color(0xFF1F6F5B);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyCommentId != null)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Membalas ke @$_replyUsername',
                    style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _replyCommentId != null ? 'Tulis balasan...' : 'Tulis komentar...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  onPressed: _submitComment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
