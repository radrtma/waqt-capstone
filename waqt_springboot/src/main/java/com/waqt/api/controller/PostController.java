package com.waqt.api.controller;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.waqt.api.entity.CommunityComment;
import com.waqt.api.entity.CommunityPost;
import com.waqt.api.entity.CommunityReply;
import com.waqt.api.repository.CommunityCommentRepository;
import com.waqt.api.repository.CommunityPostRepository;
import com.waqt.api.repository.CommunityReplyRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
public class PostController {

    @Autowired
    private CommunityPostRepository postRepository;

    @Autowired
    private CommunityCommentRepository commentRepository;

    @Autowired
    private CommunityReplyRepository replyRepository;

    @Value("${upload.path:uploads/posts}")
    private String uploadPath;

    private final ObjectMapper objectMapper = new ObjectMapper();

    // Helper to format post JSON response
    private Map<String, Object> formatPost(CommunityPost post) {
        Map<String, Object> formatted = new HashMap<>();
        formatted.put("id", post.getId());
        formatted.put("post_type", post.getPostType());
        formatted.put("username", post.getUsername());
        formatted.put("content", post.getContent());
        formatted.put("mosque_name", post.getMosqueName());
        formatted.put("is_wudu_clean", post.isWuduClean());
        formatted.put("is_ac_working", post.isAcWorking());
        formatted.put("is_female_friendly", post.isFemaleFriendly());
        formatted.put("helpful_count", post.getHelpfulCount());
        formatted.put("inspiring_count", post.getInspiringCount());
        formatted.put("useful_count", post.getUsefulCount());
        formatted.put("event_name", post.getEventName());
        formatted.put("event_date", post.getEventDate());
        formatted.put("event_location", post.getEventLocation());
        formatted.put("comment_count", post.getCommentCount());
        formatted.put("created_at", post.getCreatedAt() != null ? post.getCreatedAt().toString() : null);

        List<String> imageList = new ArrayList<>();
        String rawImagePaths = post.getImagePaths();
        if (rawImagePaths != null && !rawImagePaths.isEmpty()) {
            try {
                if (rawImagePaths.trim().startsWith("[")) {
                    imageList = objectMapper.readValue(rawImagePaths, new TypeReference<List<String>>() {});
                } else {
                    // Fallback to comma separation
                    imageList = Arrays.stream(rawImagePaths.split(","))
                            .map(String::trim)
                            .filter(s -> !s.isEmpty())
                            .collect(Collectors.toList());
                }
            } catch (Exception e) {
                // Return empty list on parse failure
            }
        }
        formatted.put("image_paths", imageList);

        return formatted;
    }

    @GetMapping("/posts")
    public ResponseEntity<List<Map<String, Object>>> index(
            @RequestParam(value = "limit", defaultValue = "50") int limit,
            @RequestParam(value = "types", defaultValue = "") String typesStr) {

        List<CommunityPost> posts;
        PageRequest pageRequest = PageRequest.of(0, limit, Sort.by("createdAt").descending());

        if (typesStr != null && !typesStr.trim().isEmpty()) {
            List<String> types = Arrays.stream(typesStr.split(","))
                    .map(String::trim)
                    .collect(Collectors.toList());
            posts = postRepository.findByPostTypeIn(types, pageRequest);
        } else {
            posts = postRepository.findAll(pageRequest).getContent();
        }

        List<Map<String, Object>> formattedPosts = posts.stream()
                .map(this::formatPost)
                .collect(Collectors.toList());

        return ResponseEntity.ok(formattedPosts);
    }

    @GetMapping("/posts/{id}")
    public ResponseEntity<Map<String, Object>> show(@PathVariable Long id) {
        Optional<CommunityPost> postOpt = postRepository.findById(id);
        if (postOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Post not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        return ResponseEntity.ok(formatPost(postOpt.get()));
    }

    @PostMapping("/posts")
    public ResponseEntity<Map<String, Object>> create(
            @RequestHeader(value = "X-User-Username", required = false) String username,
            @RequestBody Map<String, Object> requestBody) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        String postType = (String) requestBody.get("post_type");
        String content = (String) requestBody.get("content");

        if (postType == null || postType.trim().isEmpty() || content == null || content.trim().isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Post type and content are required");
            return ResponseEntity.badRequest().body(error);
        }

        String imagePathsStr = null;
        Object imagePathsObj = requestBody.get("image_paths");
        if (imagePathsObj != null) {
            try {
                imagePathsStr = objectMapper.writeValueAsString(imagePathsObj);
            } catch (Exception e) {
                // Ignore serialization error
            }
        }

        CommunityPost post = CommunityPost.builder()
                .postType(postType)
                .username(username)
                .content(content)
                .mosqueName((String) requestBody.get("mosque_name"))
                .isWuduClean(Boolean.TRUE.equals(requestBody.get("is_wudu_clean")))
                .isAcWorking(Boolean.TRUE.equals(requestBody.get("is_ac_working")))
                .isFemaleFriendly(Boolean.TRUE.equals(requestBody.get("is_female_friendly")))
                .eventName((String) requestBody.get("event_name"))
                .eventDate((String) requestBody.get("event_date"))
                .eventLocation((String) requestBody.get("event_location"))
                .imagePaths(imagePathsStr)
                .commentCount(0)
                .helpfulCount(0)
                .inspiringCount(0)
                .usefulCount(0)
                .build();

        CommunityPost savedPost = postRepository.save(post);
        return ResponseEntity.status(HttpStatus.CREATED).body(formatPost(savedPost));
    }

    @PutMapping("/posts/{id}")
    public ResponseEntity<Map<String, Object>> update(
            @PathVariable Long id,
            @RequestHeader(value = "X-User-Username", required = false) String username,
            @RequestBody Map<String, Object> requestBody) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        Optional<CommunityPost> postOpt = postRepository.findById(id);
        if (postOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Post not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        CommunityPost post = postOpt.get();
        if (!post.getUsername().equals(username)) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        }

        if (requestBody.containsKey("content")) {
            post.setContent((String) requestBody.get("content"));
        }
        if (requestBody.containsKey("mosque_name")) {
            post.setMosqueName((String) requestBody.get("mosque_name"));
        }
        if (requestBody.containsKey("is_wudu_clean")) {
            post.setWuduClean(Boolean.TRUE.equals(requestBody.get("is_wudu_clean")));
        }
        if (requestBody.containsKey("is_ac_working")) {
            post.setAcWorking(Boolean.TRUE.equals(requestBody.get("is_ac_working")));
        }
        if (requestBody.containsKey("is_female_friendly")) {
            post.setFemaleFriendly(Boolean.TRUE.equals(requestBody.get("is_female_friendly")));
        }
        if (requestBody.containsKey("event_name")) {
            post.setEventName((String) requestBody.get("event_name"));
        }
        if (requestBody.containsKey("event_date")) {
            post.setEventDate((String) requestBody.get("event_date"));
        }
        if (requestBody.containsKey("event_location")) {
            post.setEventLocation((String) requestBody.get("event_location"));
        }
        if (requestBody.containsKey("image_paths")) {
            try {
                post.setImagePaths(objectMapper.writeValueAsString(requestBody.get("image_paths")));
            } catch (Exception e) {
                // Ignore
            }
        }

        postRepository.save(post);

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Post updated");
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/posts/{id}")
    public ResponseEntity<Map<String, Object>> delete(
            @PathVariable Long id,
            @RequestHeader(value = "X-User-Username", required = false) String username) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        Optional<CommunityPost> postOpt = postRepository.findById(id);
        if (postOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Post not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        CommunityPost post = postOpt.get();
        if (!post.getUsername().equals(username)) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        }

        postRepository.delete(post);

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Post deleted");
        return ResponseEntity.ok(response);
    }

    @PostMapping("/posts/{id}/react")
    public ResponseEntity<Map<String, Object>> react(
            @PathVariable Long id,
            @RequestBody Map<String, String> requestBody) {

        String reactionType = requestBody.get("reaction_type");
        if (reactionType == null || (!reactionType.equals("helpful") && !reactionType.equals("inspiring") && !reactionType.equals("useful"))) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Invalid reaction type");
            return ResponseEntity.badRequest().body(error);
        }

        Optional<CommunityPost> postOpt = postRepository.findById(id);
        if (postOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Post not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        CommunityPost post = postOpt.get();
        if (reactionType.equals("helpful")) {
            post.setHelpfulCount(post.getHelpfulCount() + 1);
        } else if (reactionType.equals("inspiring")) {
            post.setInspiringCount(post.getInspiringCount() + 1);
        } else if (reactionType.equals("useful")) {
            post.setUsefulCount(post.getUsefulCount() + 1);
        }

        postRepository.save(post);

        Map<String, Object> response = new HashMap<>();
        response.put("id", post.getId());
        response.put("helpful_count", post.getHelpfulCount());
        response.put("inspiring_count", post.getInspiringCount());
        response.put("useful_count", post.getUsefulCount());

        return ResponseEntity.ok(response);
    }

    // --- COMMENTS & REPLIES API ---

    @GetMapping("/posts/{postId}/comments")
    public ResponseEntity<List<Map<String, Object>>> getComments(@PathVariable Long postId) {
        List<CommunityComment> comments = commentRepository.findByPostIdOrderByCreatedAtAsc(postId);
        if (comments.isEmpty()) {
            return ResponseEntity.ok(Collections.emptyList());
        }

        List<Long> commentIds = comments.stream().map(CommunityComment::getId).collect(Collectors.toList());
        List<CommunityReply> replies = replyRepository.findByCommentIdInOrderByCreatedAtAsc(commentIds);

        Map<Long, List<Map<String, Object>>> repliesMap = new HashMap<>();
        for (CommunityReply r : replies) {
            Map<String, Object> rMap = new HashMap<>();
            rMap.put("id", r.getId());
            rMap.put("comment_id", r.getCommentId());
            rMap.put("username", r.getUsername());
            rMap.put("content", r.getContent());
            rMap.put("created_at", r.getCreatedAt() != null ? r.getCreatedAt().toString() : null);

            repliesMap.computeIfAbsent(r.getCommentId(), k -> new ArrayList<>()).add(rMap);
        }

        List<Map<String, Object>> formatted = comments.stream().map(c -> {
            Map<String, Object> cMap = new HashMap<>();
            cMap.put("id", c.getId());
            cMap.put("post_id", c.getPostId());
            cMap.put("username", c.getUsername());
            cMap.put("content", c.getContent());
            cMap.put("created_at", c.getCreatedAt() != null ? c.getCreatedAt().toString() : null);
            cMap.put("replies", repliesMap.getOrDefault(c.getId(), Collections.emptyList()));
            return cMap;
        }).collect(Collectors.toList());

        return ResponseEntity.ok(formatted);
    }

    @PostMapping("/posts/{postId}/comments")
    public ResponseEntity<Map<String, Object>> addComment(
            @PathVariable Long postId,
            @RequestHeader(value = "X-User-Username", required = false) String username,
            @RequestBody Map<String, String> requestBody) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        String content = requestBody.get("content");
        if (content == null || content.trim().isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Comment content is required");
            return ResponseEntity.badRequest().body(error);
        }

        Optional<CommunityPost> postOpt = postRepository.findById(postId);
        if (postOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Post not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        CommunityComment comment = CommunityComment.builder()
                .postId(postId)
                .username(username)
                .content(content.trim())
                .build();

        CommunityComment savedComment = commentRepository.save(comment);

        // Increment post comment count
        CommunityPost post = postOpt.get();
        post.setCommentCount(post.getCommentCount() + 1);
        postRepository.save(post);

        Map<String, Object> commentData = new HashMap<>();
        commentData.put("id", savedComment.getId());
        commentData.put("post_id", savedComment.getPostId());
        commentData.put("username", savedComment.getUsername());
        commentData.put("content", savedComment.getContent());
        commentData.put("created_at", savedComment.getCreatedAt() != null ? savedComment.getCreatedAt().toString() : null);
        commentData.put("replies", Collections.emptyList());

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("comment", commentData);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @DeleteMapping("/comments/{id}")
    public ResponseEntity<Map<String, Object>> deleteComment(
            @PathVariable Long id,
            @RequestHeader(value = "X-User-Username", required = false) String username) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        Optional<CommunityComment> commentOpt = commentRepository.findById(id);
        if (commentOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Comment not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        CommunityComment comment = commentOpt.get();
        if (!comment.getUsername().equals(username)) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized to delete this comment");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        }

        // Count how many replies this comment has to update the post comment_count
        List<CommunityReply> replies = replyRepository.findByCommentIdInOrderByCreatedAtAsc(List.of(id));
        int totalToDecrement = 1 + replies.size();

        commentRepository.delete(comment);

        // Decrement comment count on post
        Optional<CommunityPost> postOpt = postRepository.findById(comment.getPostId());
        if (postOpt.isPresent()) {
            CommunityPost post = postOpt.get();
            post.setCommentCount(Math.max(0, post.getCommentCount() - totalToDecrement));
            postRepository.save(post);
        }

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Comment deleted");

        return ResponseEntity.ok(response);
    }

    @PostMapping("/comments/{commentId}/replies")
    public ResponseEntity<Map<String, Object>> addReply(
            @PathVariable Long commentId,
            @RequestHeader(value = "X-User-Username", required = false) String username,
            @RequestBody Map<String, String> requestBody) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        String content = requestBody.get("content");
        if (content == null || content.trim().isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Reply content is required");
            return ResponseEntity.badRequest().body(error);
        }

        Optional<CommunityComment> commentOpt = commentRepository.findById(commentId);
        if (commentOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Comment not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        CommunityComment comment = commentOpt.get();

        CommunityReply reply = CommunityReply.builder()
                .commentId(commentId)
                .username(username)
                .content(content.trim())
                .build();

        CommunityReply savedReply = replyRepository.save(reply);

        // Increment post comment count
        Optional<CommunityPost> postOpt = postRepository.findById(comment.getPostId());
        if (postOpt.isPresent()) {
            CommunityPost post = postOpt.get();
            post.setCommentCount(post.getCommentCount() + 1);
            postRepository.save(post);
        }

        Map<String, Object> replyData = new HashMap<>();
        replyData.put("id", savedReply.getId());
        replyData.put("comment_id", savedReply.getCommentId());
        replyData.put("username", savedReply.getUsername());
        replyData.put("content", savedReply.getContent());
        replyData.put("created_at", savedReply.getCreatedAt() != null ? savedReply.getCreatedAt().toString() : null);

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("reply", replyData);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @DeleteMapping("/replies/{id}")
    public ResponseEntity<Map<String, Object>> deleteReply(
            @PathVariable Long id,
            @RequestHeader(value = "X-User-Username", required = false) String username) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        Optional<CommunityReply> replyOpt = replyRepository.findById(id);
        if (replyOpt.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Reply not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }

        CommunityReply reply = replyOpt.get();
        if (!reply.getUsername().equals(username)) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized to delete this reply");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
        }

        replyRepository.delete(reply);

        // Decrement post comment count
        Optional<CommunityComment> commentOpt = commentRepository.findById(reply.getCommentId());
        if (commentOpt.isPresent()) {
            Optional<CommunityPost> postOpt = postRepository.findById(commentOpt.get().getPostId());
            if (postOpt.isPresent()) {
                CommunityPost post = postOpt.get();
                post.setCommentCount(Math.max(0, post.getCommentCount() - 1));
                postRepository.save(post);
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Reply deleted");

        return ResponseEntity.ok(response);
    }

    // --- FILE UPLOAD ---

    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> upload(
            @RequestHeader(value = "X-User-Username", required = false) String username,
            @RequestParam("image") MultipartFile file) {

        if (username == null) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }

        if (file == null || file.isEmpty()) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "No file uploaded");
            return ResponseEntity.badRequest().body(error);
        }

        try {
            File dir = new File(uploadPath);
            if (!dir.exists()) {
                dir.mkdirs();
            }

            String originalName = file.getOriginalFilename();
            String extension = ".jpg";
            if (originalName != null && originalName.contains(".")) {
                extension = originalName.substring(originalName.lastIndexOf("."));
            }

            String newFilename = UUID.randomUUID().toString() + extension;
            File dest = new File(dir, newFilename);
            file.transferTo(dest.getAbsoluteFile());

            Map<String, Object> response = new HashMap<>();
            response.put("status", "success");
            response.put("path", "uploads/posts/" + newFilename);

            return ResponseEntity.ok(response);
        } catch (IOException e) {
            Map<String, Object> error = new HashMap<>();
            error.put("status", "error");
            error.put("message", "Failed to save file: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }
}
