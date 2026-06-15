<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div class="community-split" style="display: flex; gap: 2rem; align-items: start;">
    
    <!-- LEFT COLUMN: Community Feed -->
    <div class="feed-container" id="communityFeedContainer" style="flex: 2; display: flex; flex-direction: column; gap: 1.5rem; min-width: 0;">
        
        <!-- Header Card with Compose Post Button -->
        <div style="display: flex; justify-content: space-between; align-items: center; background: white; padding: 1.25rem 1.5rem; border-radius: var(--border-radius-lg); border: 1px solid rgba(31, 111, 91, 0.04); box-shadow: var(--shadow-sm);">
            <div>
                <h3 style="font-family: 'Outfit', sans-serif; font-size: 1.5rem; color: #1e293b; font-weight: 800; margin: 0;">Diskusi Komunitas</h3>
                <p style="font-size: 0.8rem; color: #64748b; margin: 0; margin-top: 0.15rem;">Bagikan cerita dan berinteraksi bersama umat lainnya</p>
            </div>
            <a href="<?= base_url('community/post/create') ?>" class="btn-primary" style="text-decoration: none; padding: 0.65rem 1.25rem; font-weight: 700; border-radius: 12px; display: inline-flex; align-items: center; gap: 0.5rem; font-size: 0.9rem; width: auto;">
                ✍ Tulis Kiriman
            </a>
        </div>

        <?php if (session()->getFlashdata('error')) : ?>
            <div class="error-banner">
                <?= esc(session()->getFlashdata('error')) ?>
            </div>
        <?php endif; ?>

        <?php if (empty($posts)) : ?>
            <div class="feed-card" style="text-align: center; color: #64748b; padding: 3rem;">
                Belum ada kiriman komunitas. Jadilah yang pertama memposting!
            </div>
        <?php else : ?>
            <?php foreach ($posts as $post) : ?>
                <div class="feed-card" data-post-id="<?= $post['id'] ?>">
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
                    
                    <p class="feed-content"><?= nl2br(esc($post['content'])) ?></p>

                    <?php if ($post['post_type'] === 'mosque') : ?>
                        <div class="feed-checklist">
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

                    <!-- Non-toxic reactions system + Comments link -->
                    <div class="feed-reactions-row">
                        <button class="btn-reaction" data-reaction-type="inspiring">
                            💡 Inspiring (<span class="count"><?= $post['inspiring_count'] ?></span>)
                        </button>
                        <button class="btn-reaction" data-reaction-type="helpful">
                            🤝 Helpful (<span class="count"><?= $post['helpful_count'] ?></span>)
                        </button>
                        <button class="btn-reaction" data-reaction-type="useful">
                            📌 Useful (<span class="count"><?= $post['useful_count'] ?></span>)
                        </button>
                        
                        <a href="<?= base_url('community/post/' . $post['id']) ?>" class="btn-comment-link" style="margin-left: auto; display: flex; align-items: center; gap: 0.25rem; text-decoration: none; font-size: 0.8rem; font-weight: 600; color: #64748b; background: #f1f5f9; padding: 0.4rem 0.75rem; border-radius: 6px; transition: all 0.2s;">
                            💬 Komentar (<span class="comment-count"><?= $post['comment_count'] ?? 0 ?></span>)
                        </a>
                    </div>
                </div>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>

    <!-- RIGHT COLUMN: Insights, Recommendations & Widgets -->
    <div class="widgets-container" style="flex: 1; min-width: 300px; display: flex; flex-direction: column; gap: 1.5rem;">
        
        <!-- Keaktifan Komunitas -->
        <div class="history-section-card" style="padding: 1.25rem;">
            <div class="widget-title">Keaktifan Komunitas</div>
            <div class="widget-item" style="justify-content: space-between; font-size: 0.85rem;">
                <span style="font-weight: 600; color: #475569;">Anggota Aktif</span>
                <span id="activeMembersCount" data-base="<?= $activeMembers ?>" style="font-weight: 700; color: hsl(var(--primary)); transition: all 0.2s; display: inline-block; min-width: 50px; text-align: right;"><?= number_format($activeMembers, 0, ',', '.') ?></span>
            </div>
            <div class="widget-item" style="justify-content: space-between; font-size: 0.85rem;">
                <span style="font-weight: 600; color: #475569;">Shalat Terlacak</span>
                <span id="trackedPrayersCount" data-base="<?= $trackedPrayersCount ?>" style="font-weight: 700; color: hsl(var(--primary)); transition: all 0.2s; display: inline-block; min-width: 60px; text-align: right;"><?= number_format($trackedPrayersCount, 0, ',', '.') ?></span>
            </div>
            <div class="widget-item" style="justify-content: space-between; font-size: 0.85rem;">
                <span style="font-weight: 600; color: #475569;">Review Masjid</span>
                <span id="masjidReviewsCount" data-base="<?= $mosqueReviewsCount ?>" style="font-weight: 700; color: hsl(var(--primary)); transition: all 0.2s; display: inline-block; min-width: 50px; text-align: right;"><?= number_format($mosqueReviewsCount, 0, ',', '.') ?></span>
            </div>
        </div>

        <!-- Rekomendasi Masjid Terdekat -->
        <div class="history-section-card" style="padding: 1.25rem;">
            <div class="widget-title">Rekomendasi Masjid</div>
            <?php foreach ($recommendedMosques as $mosque) : ?>
                <div class="widget-item" style="flex-direction: column; align-items: flex-start; gap: 0.2rem;">
                    <div style="font-weight: 700; font-size: 0.85rem; color: hsl(var(--primary));"><?= esc($mosque['name']) ?></div>
                    <div style="font-size: 0.75rem; color: #64748b;"><?= esc($mosque['distance']) ?> · <?= esc($mosque['description']) ?></div>
                </div>
            <?php endforeach; ?>
        </div>

        <!-- Renungan Spiritual Harian -->
        <div class="history-section-card" style="padding: 1.25rem;">
            <div class="widget-title">Renungan Harian</div>
            <p style="font-size: 0.8rem; color: #475569; line-height: 1.5; font-style: italic; margin-bottom: 0.5rem;">
                <?= esc($dailyReflection['quote']) ?>
            </p>
            <div style="font-size: 0.75rem; font-weight: 700; color: hsl(var(--primary)); text-align: right;"><?= esc($dailyReflection['source']) ?></div>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
