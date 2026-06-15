<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<!-- Dashboard Main Content Container -->
<div id="dashboardMainView">
    <!-- Greeting Row -->
    <div class="greeting-row">
        <div class="greeting-text-box">
            <span class="greeting-sub">Assalamu'alaikum</span>
            <span class="greeting-name"><?= esc($username) ?></span>
        </div>
        
        <div class="web-streak-badge" id="btnShowStreak">
            <img src="<?= base_url('assets/icon_streak.png') ?>" class="web-streak-icon" id="streakBadgeIcon" alt="Streak badge">
            <span class="web-streak-count" id="streakBadgeCount">0x</span>
            <span class="web-streak-label">Days</span>
        </div>
    </div>

    <!-- Countdown Card -->
    <div class="web-prayer-card">
        <div class="prayer-card-bg-overlay"></div>
        <div class="prayer-card-content">
            <div class="prayer-card-header">
                <span class="prayer-card-icon" id="prayerCardIcon">☀️</span>
                <span class="prayer-card-name" id="prayerCardName">Fajr</span>
            </div>
            <div class="prayer-card-time" id="prayerCardTime">--:--</div>
            <div class="prayer-card-info">Next Prayer (<span id="prayerCardNextLabel">Fajr</span>) In</div>
            <div class="prayer-card-countdown-row">
                <span class="prayer-card-countdown-text" id="prayerCardCountdown">00 : 00 : 00</span>
            </div>
        </div>
    </div>

    <!-- Date Card -->
    <div class="web-date-card">
        <div class="web-date-gregorian" id="currentGregorianDate">
            --
        </div>
        <div class="web-date-hijri">8 Dzulhijjah 1447 H</div>
    </div>

    <!-- Tracker Pill -->
    <div class="web-tracker-pill" id="prayerTrackerPill">
        <!-- Will be populated dynamically by JS -->
    </div>

    <!-- Dari Komunitas Section -->
    <div class="dashboard-community-section" style="margin-top: 2rem;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
            <h3 style="font-family: 'Outfit', sans-serif; font-weight: 700; color: #1e293b; font-size: 1.25rem; margin: 0;">Highlight Komunitas</h3>
            <a href="<?= base_url('community') ?>" style="font-size: 0.85rem; font-weight: 600; color: hsl(var(--primary)); text-decoration: none;">Lihat Semua →</a>
        </div>
        
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem;">
            <?php if (empty($recentPosts)) : ?>
                <div class="history-section-card" style="grid-column: 1 / -1; text-align: center; color: #64748b; padding: 2rem;">
                    Belum ada postingan komunitas.
                </div>
            <?php else : ?>
                <?php foreach ($recentPosts as $post) : ?>
                    <div class="dashboard-post-card">
                        <div class="history-section-card" style="height: 100%; display: flex; flex-direction: column; justify-content: space-between; padding: 1.25rem;">
                            <div>
                                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.75rem;">
                                    <span style="font-weight: 700; font-size: 0.8rem; color: #475569;">@<?= esc($post['username']) ?></span>
                                    <span class="feed-badge <?= esc($post['post_type']) ?>" style="font-size: 0.7rem; padding: 0.2rem 0.5rem;">
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
                                
                                <a href="<?= base_url('community/post/' . $post['id']) ?>" style="text-decoration: none; color: inherit; display: block;">
                                    <?php if ($post['post_type'] === 'event' && !empty($post['event_name'])) : ?>
                                        <div style="font-weight: 700; font-size: 0.85rem; color: #1e293b; margin-bottom: 0.25rem;">📅 <?= esc($post['event_name']) ?></div>
                                    <?php elseif ($post['post_type'] === 'mosque' && !empty($post['mosque_name'])) : ?>
                                        <div style="font-weight: 700; font-size: 0.85rem; color: #1e293b; margin-bottom: 0.25rem;">📍 <?= esc($post['mosque_name']) ?></div>
                                    <?php endif; ?>
                                    
                                    <p style="font-size: 0.85rem; color: #334155; line-height: 1.5; margin: 0; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; margin-bottom: 0.5rem;">
                                        <?= esc($post['content']) ?>
                                    </p>
                                </a>

                                <!-- Swipeable Image Carousel Slider (if contains uploaded images) -->
                                <?php if (!empty($post['image_paths']) && is_array($post['image_paths'])) : ?>
                                    <div class="post-carousel-container" style="max-height: 180px; margin-top: 0.5rem; margin-bottom: 0.5rem;">
                                        <div class="post-carousel-slides">
                                            <?php foreach ($post['image_paths'] as $imgPath) : ?>
                                                <div class="post-carousel-slide" style="max-height: 180px;">
                                                    <img src="<?= base_url($imgPath) ?>" alt="Post image" style="max-height: 180px;">
                                                </div>
                                            <?php endforeach; ?>
                                        </div>
                                        <?php if (count($post['image_paths']) > 1) : ?>
                                            <button type="button" class="carousel-control prev" onclick="moveCarousel(event, -1)" style="width: 24px; height: 24px; font-size: 1rem;">‹</button>
                                            <button type="button" class="carousel-control next" onclick="moveCarousel(event, 1)" style="width: 24px; height: 24px; font-size: 1rem;">›</button>
                                            <div class="carousel-dots" style="bottom: 8px;">
                                                <?php foreach ($post['image_paths'] as $index => $imgPath) : ?>
                                                    <span class="carousel-dot <?= $index === 0 ? 'active' : '' ?>" style="width: 5px; height: 5px;"></span>
                                                <?php endforeach; ?>
                                            </div>
                                        <?php endif; ?>
                                    </div>
                                <?php endif; ?>
                            </div>
                            
                            <a href="<?= base_url('community/post/' . $post['id']) ?>" style="text-decoration: none; color: inherit; display: block;">
                                <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 1rem; border-top: 1px solid #f1f5f9; padding-top: 0.5rem; font-size: 0.75rem; color: #64748b;">
                                    <span>💬 <?= $post['comment_count'] ?? 0 ?> Komentar</span>
                                    <span>👍 <?= ($post['inspiring_count'] + $post['helpful_count'] + $post['useful_count']) ?> Reaksi</span>
                                </div>
                            </a>
                        </div>
                    </div>
                <?php endforeach; ?>
            <?php endif; ?>
        </div>
    </div>

    <!-- Renungan & Rekomendasi Section -->
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1rem; margin-top: 2rem;">
        <!-- Renungan Harian Widget -->
        <div class="history-section-card" style="padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between;">
            <div>
                <div class="widget-title" style="margin-bottom: 1rem; font-family: 'Outfit', sans-serif; font-weight: 700; color: hsl(var(--primary)); font-size: 1.1rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 0.5rem;">
                    📖 Renungan Harian
                </div>
                <p style="font-size: 0.9rem; color: #334155; line-height: 1.6; font-style: italic; margin-bottom: 1rem;">
                    <?= esc($dailyReflection['quote']) ?>
                </p>
            </div>
            <div style="font-size: 0.8rem; font-weight: 700; color: hsl(var(--primary)); text-align: right;">
                <?= esc($dailyReflection['source']) ?>
            </div>
        </div>

        <!-- Rekomendasi Masjid Widget -->
        <div class="history-section-card" style="padding: 1.5rem;">
            <div class="widget-title" style="margin-bottom: 1rem; font-family: 'Outfit', sans-serif; font-weight: 700; color: hsl(var(--primary)); font-size: 1.1rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 0.5rem;">
                Masjid Rekomendasi
            </div>
            
            <div style="display: flex; flex-direction: column; gap: 0.75rem;">
                <?php foreach ($recommendedMosques as $index => $mosque) : ?>
                    <div style="display: flex; flex-direction: column; gap: 0.15rem; <?= $index < count($recommendedMosques) - 1 ? 'padding-bottom: 0.5rem; border-bottom: 1px solid #f8fafc;' : '' ?>">
                        <div style="font-weight: 700; font-size: 0.9rem; color: #1e293b;"><?= esc($mosque['name']) ?></div>
                        <div style="font-size: 0.75rem; color: #64748b;">📍 <?= esc($mosque['distance']) ?> · <?= esc($mosque['description']) ?></div>
                    </div>
                <?php endforeach; ?>
            </div>
        </div>
    </div>
</div>

<!-- Streak Sub-view Detail Screen (hidden by default) -->
<div id="streakDetailView" style="display: none;">
    <div style="display: flex; flex-direction: column; gap: 1rem; margin-bottom: 2rem; align-items: flex-start;">
        <div>
            <h2 style="font-family: 'DM Serif Display', serif; font-size: 2rem; color: hsl(var(--primary)); margin: 0;">Spiritual Streak</h2>
            <p style="font-size: 0.85rem; color: #64748b; margin: 0;">Keep your prayer flame alive</p>
        </div>
        <button id="btnBackToDashboard" class="btn-back-link">
            ⬅️ Kembali
        </button>
    </div>

    <!-- Streak Hero Card -->
    <div class="streak-hero-card gold" id="streakHeroCard">
        <div class="streak-hero-avatar-shell">
            <img src="<?= base_url('assets/icon_streak.png') ?>" id="streakHeroIcon" class="streak-hero-icon" alt="streak flame">
        </div>
        <div class="streak-hero-number" id="streakHeroNumber">0</div>
        <div class="streak-hero-label" id="streakHeroLabel">Days Streak</div>
        <div class="streak-restore-warning" id="streakRestoreWarning" style="display: none;">Complete Qada below to restore your streak!</div>
    </div>

    <!-- Qada Section -->
    <div class="history-section-card">
        <div class="qada-section-header" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 0.75rem;">
            <span class="qada-section-title" style="font-family: 'Outfit', sans-serif; font-weight: 700; color: hsl(var(--primary)); font-size: 1.3rem;">Qada Sholat</span>
            <span class="qada-section-progress" id="qadaProgress" style="font-weight: 700; color: #64748b;">0/0</span>
        </div>
        
        <div class="qada-list-container" id="qadaListContainer" style="display: flex; flex-direction: column; gap: 0.75rem;">
            <!-- Will be populated dynamically by JS -->
        </div>
    </div>
</div>
<?= $this->endSection() ?>
