<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div>
    <!-- Header Card -->
    <div class="history-section-card" style="margin-bottom: 1.5rem;">
        <h3 style="margin: 0;">Profile</h3>
        <p style="font-size: 0.85rem; color: #64748b; font-weight: 500; margin: 0.25rem 0 0 0;">Manage your account and preferences</p>
    </div>

    <!-- Profile Card -->
    <div class="streak-hero-card gold" style="padding: 2.5rem 1.5rem; margin-bottom: 2rem;">
        <div style="position: relative; margin-bottom: 1.25rem;">
            <!-- Hidden file input for avatar -->
            <input 
                type="file" 
                id="profileAvatarFile" 
                accept="image/*" 
                style="display: none;" 
            />
            <div 
                class="streak-hero-avatar-shell profile-avatar-clickable" 
                id="btnChangeAvatar"
                style="border: 2px solid hsl(var(--gold)); padding: 4px; cursor: pointer; position: relative;"
                title="Klik untuk mengubah foto profil"
            >
                <div id="profilePictureContainer">
                    <!-- Dynamic avatar picture or fallback initials -->
                    <div style="width: 72px; height: 72px; borderRadius: 50%; backgroundColor: #F5E9DA; display: flex; alignItems: center; justifyContent: center; fontSize: 2rem; color: hsl(var(--primary)); fontWeight: bold;">
                        <?= strtoupper(substr($username ?? 'W', 0, 1)) ?>
                    </div>
                </div>
                <!-- Camera icon overlay -->
                <div class="avatar-camera-overlay">
                    <span>📷</span>
                </div>
            </div>
        </div>

        <div style="display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.25rem;">
            <span style="font-family: 'DM Serif Display', serif; font-size: 1.8rem; font-weight: bold; color: hsl(var(--gold));" id="profileNameLabel">
                <?= esc($username) ?>
            </span>
        </div>
        <span style="font-size: 0.8rem; color: rgba(255, 255, 255, 0.8);">Anggota sejak Dzulhijjah 1447 H</span>
    </div>

    <!-- Settings Card List -->
    <div class="qada-list-container" style="margin-bottom: 2.5rem;">
        
        <!-- About WAQT -->
        <div class="qada-item-card" id="btnAboutDialog" style="cursor: pointer;">
            <div class="qada-item-left">
                <div class="qada-item-icon-circle done" style="background-color: rgba(31,111,91,0.1); color: hsl(var(--primary));">ℹ️</div>
                <div class="qada-item-info">
                    <span class="qada-item-name">Tentang WAQT</span>
                    <span class="qada-item-sub">Versi 1.0.0+1</span>
                </div>
            </div>
            <span style="color: #64748b; font-size: 1.25rem;">›</span>
        </div>

        <!-- Ubah Kredensial Akun (Accordion) -->
        <div class="qada-item-card" style="flex-direction: column; align-items: stretch; gap: 0; transition: var(--transition);" id="credentialsAccordionCard">
            <div id="btnToggleCredentials" style="display: flex; justify-content: space-between; align-items: center; width: 100%; cursor: pointer;">
                <div class="qada-item-left">
                    <div class="qada-item-icon-circle done" style="background-color: rgba(31,111,91,0.1); color: hsl(var(--primary));">🔒</div>
                    <div class="qada-item-info">
                        <span class="qada-item-name">Ubah Kredensial Akun</span>
                        <span class="qada-item-sub">Ganti username atau password Anda</span>
                    </div>
                </div>
                <span id="accordionArrow" style="color: #64748b; font-size: 1.25rem; transition: transform 0.25s ease-in-out; display: inline-block;">›</span>
            </div>

            <div id="credentialsFormContent" style="display: none; padding-top: 1.25rem; border-top: 1px solid #f1f5f9; margin-top: 1rem;">
                <div id="profileAlertContainer"></div>
                
                <form id="updateCredentialsForm">
                    <div class="form-group" style="margin-bottom: 1rem;">
                        <label class="form-label" for="new_username">Username Baru</label>
                        <input
                            id="new_username"
                            type="text"
                            class="form-input"
                            value="<?= esc($username) ?>"
                            placeholder="Username Baru"
                            required
                        />
                    </div>

                    <div class="form-group" style="margin-bottom: 1rem;">
                        <label class="form-label" for="new_password">Password Baru</label>
                        <input
                            id="new_password"
                            type="password"
                            class="form-input"
                            placeholder="Masukkan Password Baru jika ingin diubah"
                        />
                    </div>

                    <div class="form-group" style="margin-bottom: 1.5rem;">
                        <label class="form-label" for="confirm_password">Konfirmasi Password Baru</label>
                        <input
                            id="confirm_password"
                            type="password"
                            class="form-input"
                            placeholder="Konfirmasi Password Baru jika ingin diubah"
                        />
                    </div>

                    <button type="submit" class="btn-primary" style="width: 100%;">
                        Simpan Perubahan
                    </button>
                </form>
            </div>
        </div>
    </div>

    <!-- Kiriman Anda Section -->
    <div style="margin-top: 2.5rem; margin-bottom: 2rem;">
        <h3 style="font-family: 'Outfit', sans-serif; font-weight: 800; color: #1e293b; font-size: 1.4rem; margin-bottom: 1rem;">Kiriman Anda</h3>
        
        <?php if (session()->getFlashdata('success')) : ?>
            <div class="success-banner" style="background-color: #dcfce7; border: 1px solid #bbf7d0; color: #166534; padding: 0.85rem 1rem; border-radius: 12px; font-weight: 600; margin-bottom: 1rem;">
                <?= esc(session()->getFlashdata('success')) ?>
            </div>
        <?php endif; ?>
        
        <?php if (session()->getFlashdata('error')) : ?>
            <div class="error-banner" style="margin-bottom: 1rem;">
                <?= esc(session()->getFlashdata('error')) ?>
            </div>
        <?php endif; ?>

        <?php if (empty($posts)) : ?>
            <div class="history-section-card" style="text-align: center; color: #64748b; padding: 2rem;">
                Anda belum menulis kiriman apapun.
            </div>
        <?php else : ?>
            <div style="display: flex; flex-direction: column; gap: 1rem;">
                <?php foreach ($posts as $post) : ?>
                    <div class="feed-card" data-post-id="<?= $post['id'] ?>">
                        <div class="feed-card-header" style="margin-bottom: 0.75rem;">
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
                            
                            <!-- Edit & Delete Buttons -->
                            <div style="display: flex; gap: 0.5rem; align-items: center;">
                                <a href="<?= base_url('community/post/edit/' . $post['id']) ?>" class="btn-primary" style="padding: 0.35rem 0.75rem; font-size: 0.75rem; border-radius: 8px; width: auto; font-weight: 700; text-decoration: none; box-shadow: none;">✏️ Edit</a>
                                <button onclick="confirmDelete(event, '<?= base_url('community/post/delete/' . $post['id']) ?>')" class="btn-danger" style="padding: 0.35rem 0.75rem; font-size: 0.75rem; border-radius: 8px; width: auto; font-weight: 700; text-decoration: none; border: none; box-shadow: none;">🗑️ Hapus</button>
                            </div>
                        </div>

                        <?php if ($post['post_type'] === 'mosque' && !empty($post['mosque_name'])) : ?>
                            <h4 class="feed-mosque-title">📍 <?= esc($post['mosque_name']) ?></h4>
                        <?php endif; ?>

                        <?php if ($post['post_type'] === 'event' && !empty($post['event_name'])) : ?>
                            <div class="feed-event-details" style="margin-bottom: 0.5rem;">
                                <div class="feed-event-title" style="font-weight: 700;">📅 <?= esc($post['event_name']) ?></div>
                                <div class="feed-event-meta" style="font-size: 0.8rem; color: #64748b;">
                                    <span>🕒 <?= esc($post['event_date']) ?></span> · 
                                    <span>📍 <?= esc($post['event_location']) ?></span>
                                </div>
                            </div>
                        <?php endif; ?>

                        <!-- Swipeable Image Carousel Slider (if contains uploaded images) -->
                        <?php if (!empty($post['image_paths']) && is_array($post['image_paths'])) : ?>
                            <div class="post-carousel-container" style="max-height: 250px;">
                                <div class="post-carousel-slides">
                                    <?php foreach ($post['image_paths'] as $imgPath) : ?>
                                        <div class="post-carousel-slide" style="max-height: 250px;">
                                            <img src="<?= base_url($imgPath) ?>" alt="Post image" style="max-height: 250px;">
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

                        <p class="feed-content" style="margin-bottom: 0.5rem;"><?= nl2br(esc($post['content'])) ?></p>

                        <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid #f1f5f9; padding-top: 0.5rem; font-size: 0.75rem; color: #64748b;">
                            <span>💬 <?= $post['comment_count'] ?? 0 ?> Komentar</span>
                            <span>👍 <?= ($post['inspiring_count'] + $post['helpful_count'] + $post['useful_count']) ?> Reaksi</span>
                        </div>
                    </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>

    <!-- Red Logout Button -->
    <a href="<?= base_url('logout') ?>" class="btn-danger" style="box-shadow: none; width: 100%; display: block; text-align: center; margin-bottom: 2rem;">
        Keluar dari Akun (Logout)
    </a>

    <script>
    function confirmDelete(event, url) {
        event.preventDefault();
        if (confirm('Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat dibatalkan.')) {
            window.location.href = url;
        }
    }
    </script>

    <!-- CUSTOM MODAL: ABOUT DIALOG -->
    <div class="auth-container" id="aboutModal" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: 1000; background-color: rgba(0,0,0,0.5); display: none;">
        <div class="auth-card" style="max-width: 380px;">
            <div style="font-size: 2.5rem; margin-bottom: 0.5rem;">🕌</div>
            <h3 style="font-family: 'DM Serif Display', serif; font-size: 1.6rem; color: hsl(var(--primary)); margin-bottom: 0.5rem;">About WAQT</h3>
            <p style="font-weight: bold; font-size: 0.9rem; color: hsl(var(--primary)); margin-bottom: 0.75rem;">Version 1.0.0+1</p>
            <p style="font-size: 0.85rem; color: #475569; line-height: 1.5; margin-bottom: 1.5rem;">
                Raffi and Ridhwan project prayer app to fulfill CCIT project assignment.
            </p>
            <button class="btn-primary" id="btnExitAbout">Tutup</button>
        </div>
    </div>
</div>
<?= $this->endSection() ?>
