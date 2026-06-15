<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div class="view-post-container">
    <div style="margin-bottom: 1.5rem;">
        <a href="<?= base_url('community') ?>" class="btn-back-link">
            ⬅️ Kembali ke Komunitas
        </a>
    </div>
    
    <!-- Main Post Card -->
    <div class="feed-card detail-card" data-post-id="<?= $post['id'] ?>">
        <div class="feed-card-header">
            <div class="feed-author-box">
                <div class="feed-avatar-dummy" data-author="<?= esc($post['username']) ?>">
                    <?= strtoupper(substr($post['username'], 0, 1)) ?>
                </div>
                <div class="feed-author-info">
                    <span class="feed-author-name"><?= esc($post['username']) ?></span>
                    <span class="feed-timestamp"> · <?= date('j M Y, H:i', strtotime($post['created_at'])) ?></span>
                </div>
            </div>
            <span class="feed-badge <?= esc($post['post_type']) ?>">
                <?php
                    switch ($post['post_type']) {
                        case 'reflection': echo 'Refleksi'; break;
                        case 'mosque': echo 'Masjid'; break;
                        case 'event': echo 'Event'; break;
                        default: echo esc($post['post_type']);
                    }
                ?>
            </span>
        </div>

        <?php if ($post['post_type'] === 'mosque' && !empty($post['mosque_name'])) : ?>
            <h4 class="feed-mosque-title">📍 <?= esc($post['mosque_name']) ?></h4>
        <?php endif; ?>

        <?php if ($post['post_type'] === 'event' && !empty($post['event_name'])) : ?>
            <div class="feed-event-details">
                <div class="feed-event-title">📅 <?= esc($post['event_name']) ?></div>
                <div class="feed-event-meta">
                    <span>🕒 <?= esc($post['event_date']) ?></span> · 
                    <span>📍 <?= esc($post['event_location']) ?></span>
                </div>
            </div>
        <?php endif; ?>

        <!-- Swipeable Image Carousel Slider (if contains uploaded images) -->
        <?php if (!empty($post['image_paths']) && is_array($post['image_paths'])) : ?>
            <div class="post-carousel-container">
                <div class="post-carousel-slides">
                    <?php foreach ($post['image_paths'] as $imgPath) : ?>
                        <div class="post-carousel-slide">
                            <img src="<?= base_url($imgPath) ?>" alt="Post image">
                        </div>
                    <?php endforeach; ?>
                </div>
                <?php if (count($post['image_paths']) > 1) : ?>
                    <button type="button" class="carousel-control prev" onclick="moveCarousel(event, -1)">‹</button>
                    <button type="button" class="carousel-control next" onclick="moveCarousel(event, 1)">›</button>
                    <div class="carousel-dots">
                        <?php foreach ($post['image_paths'] as $index => $imgPath) : ?>
                            <span class="carousel-dot <?= $index === 0 ? 'active' : '' ?>"></span>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>
        <?php endif; ?>
        
        <p class="feed-content" style="font-size: 1.1rem; line-height: 1.6; color: #1e293b; margin-top: 1rem; margin-bottom: 1.5rem;">
            <?= nl2br(esc($post['content'])) ?>
        </p>

        <?php if ($post['post_type'] === 'mosque') : ?>
            <div class="feed-checklist" style="margin-bottom: 1.5rem;">
                <span class="feed-checklist-item <?= $post['is_wudu_clean'] ? 'yes' : 'no' ?>">
                    <?= $post['is_wudu_clean'] ? '✓' : '✗' ?> Wudhu Bersih
                </span>
                <span class="feed-checklist-item <?= $post['is_ac_working'] ? 'yes' : 'no' ?>">
                    <?= $post['is_ac_working'] ? '✓' : '✗' ?> AC/Kipas OK
                </span>
                <span class="feed-checklist-item <?= $post['is_female_friendly'] ? 'yes' : 'no' ?>">
                    <?= $post['is_female_friendly'] ? '✓' : '✗' ?> Ramah Perempuan
                </span>
            </div>
        <?php endif; ?>

        <!-- Reactions Row -->
        <div class="feed-reactions-row" style="display: flex; gap: 0.5rem; align-items: center; width: 100%; border-top: 1px solid #e2e8f0; padding-top: 1rem;">
            <button class="btn-reaction" data-reaction-type="inspiring">
                💡 Inspiring (<span class="count"><?= $post['inspiring_count'] ?></span>)
            </button>
            <button class="btn-reaction" data-reaction-type="helpful">
                🤝 Helpful (<span class="count"><?= $post['helpful_count'] ?></span>)
            </button>
            <button class="btn-reaction" data-reaction-type="useful">
                📌 Useful (<span class="count"><?= $post['useful_count'] ?></span>)
            </button>
        </div>
    </div>

    <!-- Comments and Replies Container Card -->
    <div class="history-section-card" style="margin-top: 1.5rem; padding: 1.5rem;">
        <h3 style="margin-bottom: 1.25rem;">Diskusi & Komentar (<span id="totalCommentCount"><?= $post['comment_count'] ?? 0 ?></span>)</h3>
        
        <!-- Add Comment Form -->
        <form id="ajaxCommentForm" style="margin-bottom: 2rem; display: flex; flex-direction: column; gap: 0.75rem;">
            <div class="form-group">
                <textarea
                    id="commentTextarea"
                    class="form-input"
                    style="min-height: 80px; resize: vertical; padding: 0.75rem;"
                    placeholder="Tulis komentar spiritual atau tanggapan..."
                    required
                ></textarea>
            </div>
            <button type="submit" class="btn-primary" style="align-self: flex-end; padding: 0.5rem 1.25rem; width: auto;">
                Kirim Komentar
            </button>
        </form>

        <!-- Comments List -->
        <div id="commentsListContainer" class="comments-list-wrapper">
            <?php if (empty($comments)) : ?>
                <div id="noCommentsAlert" style="text-align: center; color: #64748b; padding: 2rem; font-style: italic;">
                    Belum ada komentar. Mari mulai diskusinya!
                </div>
            <?php else : ?>
                <?php foreach ($comments as $comment) : ?>
                    <div class="comment-item-card" data-comment-id="<?= $comment['id'] ?>" style="margin-bottom: 1.5rem; padding-bottom: 1.5rem; border-bottom: 1px solid #f1f5f9;">
                        <!-- Comment Header -->
                        <div style="display: flex; justify-content: space-between; align-items: start;">
                            <div style="display: flex; gap: 0.75rem; align-items: center; margin-bottom: 0.5rem;">
                                <div class="comment-avatar-fallback">
                                    <?= strtoupper(substr($comment['username'], 0, 1)) ?>
                                </div>
                                <div>
                                    <span style="font-weight: 700; font-size: 0.85rem; color: #1e293b;"><?= esc($comment['username']) ?></span>
                                    <?php if ($comment['username'] === $post['username']) : ?>
                                        <span class="author-badge">Author</span>
                                    <?php endif; ?>
                                    <span style="font-size: 0.75rem; color: #64748b; margin-left: 0.25rem;">
                                        · <?= date('j M Y, H:i', strtotime($comment['created_at'])) ?>
                                    </span>
                                </div>
                            </div>
                            <?php if ($comment['username'] === $username) : ?>
                                <button class="btn-comment-delete" onclick="handleDeleteComment(<?= $comment['id'] ?>)">Hapus</button>
                            <?php endif; ?>
                        </div>

                        <!-- Comment content -->
                        <p class="comment-text-body" style="font-size: 0.9rem; color: #334155; margin-left: 2.25rem; margin-top: 0.25rem; margin-bottom: 0.5rem; line-height: 1.5;">
                            <?= nl2br(esc($comment['content'])) ?>
                        </p>

                        <!-- Reply trigger -->
                        <div style="margin-left: 2.25rem; margin-bottom: 0.75rem;">
                            <button class="btn-reply-trigger" onclick="toggleReplyBox(<?= $comment['id'] ?>)">
                                ↩ Balas
                            </button>
                        </div>

                        <!-- Inline Reply Box (Hidden by default) -->
                        <div id="replyBox-<?= $comment['id'] ?>" style="display: none; margin-left: 2.25rem; margin-bottom: 1rem; margin-top: 0.5rem;">
                            <form onsubmit="handleSendReply(event, <?= $comment['id'] ?>)" style="display: flex; gap: 0.5rem; align-items: start;">
                                <input 
                                    type="text" 
                                    class="form-input reply-input-field" 
                                    style="padding: 0.5rem; font-size: 0.85rem; border-radius: 6px;" 
                                    placeholder="Tulis balasan..." 
                                    required
                                />
                                <button type="submit" class="btn-primary" style="padding: 0.5rem 1rem; font-size: 0.8rem; border-radius: 6px; width: auto;">Kirim</button>
                                <button type="button" class="btn-danger" onclick="toggleReplyBox(<?= $comment['id'] ?>)" style="padding: 0.5rem 1rem; font-size: 0.8rem; border-radius: 6px; width: auto;">Batal</button>
                            </form>
                        </div>

                        <!-- Replies List (Indented) -->
                        <div class="comment-replies-list" id="repliesContainer-<?= $comment['id'] ?>" style="margin-left: 2.25rem; border-left: 2px solid #f1f5f9; padding-left: 1rem; display: flex; flex-direction: column; gap: 1rem; margin-top: 0.5rem;">
                            <?php if (!empty($comment['replies'])) : ?>
                                <?php foreach ($comment['replies'] as $reply) : ?>
                                    <div class="reply-item-card" data-reply-id="<?= $reply['id'] ?>">
                                        <div style="display: flex; justify-content: space-between; align-items: start;">
                                            <div style="display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.25rem;">
                                                <div class="reply-avatar-fallback">
                                                    <?= strtoupper(substr($reply['username'], 0, 1)) ?>
                                                </div>
                                                <div>
                                                    <span style="font-weight: 700; font-size: 0.8rem; color: #1e293b;"><?= esc($reply['username']) ?></span>
                                                    <?php if ($reply['username'] === $post['username']) : ?>
                                                        <span class="author-badge replies-badge">Author</span>
                                                    <?php endif; ?>
                                                    <span style="font-size: 0.7rem; color: #64748b; margin-left: 0.25rem;">
                                                        · <?= date('j M Y, H:i', strtotime($reply['created_at'])) ?>
                                                    </span>
                                                </div>
                                            </div>
                                            <?php if ($reply['username'] === $username) : ?>
                                                <button class="btn-comment-delete" onclick="handleDeleteReply(<?= $reply['id'] ?>, <?= $comment['id'] ?>)" style="font-size: 0.7rem;">Hapus</button>
                                            <?php endif; ?>
                                        </div>
                                        <p class="reply-text-body" style="font-size: 0.85rem; color: #475569; margin-left: 1.75rem; margin-top: 0.15rem; line-height: 1.4;">
                                            <?= nl2br(esc($reply['content'])) ?>
                                        </p>
                                    </div>
                                <?php endforeach; ?>
                            <?php endif; ?>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>
</div>

<script>
    const currentPostId = <?= $post['id'] ?>;
    window.currentPostAuthor = '<?= esc($post['username']) ?>';
</script>
<?= $this->endSection() ?>
