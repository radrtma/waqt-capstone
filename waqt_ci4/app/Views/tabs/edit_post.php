<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div style="max-width: 700px; margin: 0 auto; padding-bottom: 3rem;">
    <div style="margin-bottom: 1.5rem;">
        <a href="<?= base_url('profile') ?>" class="btn-back-link">
            ⬅️ Kembali ke Profil
        </a>
    </div>

    <div class="history-section-card" style="padding: 2.25rem;">
        <h2 style="font-family: 'Outfit', sans-serif; font-size: 1.75rem; color: hsl(var(--primary)); margin-bottom: 0.5rem; font-weight: 800;">Edit Kiriman Anda</h2>
        <p style="font-size: 0.9rem; color: #64748b; margin-bottom: 2rem;">Perbarui detail refleksi spiritual, review masjid, atau info event Anda.</p>

        <?php if (session()->getFlashdata('error')) : ?>
            <div class="error-banner" style="margin-bottom: 1.5rem;">
                <?= esc(session()->getFlashdata('error')) ?>
            </div>
        <?php endif; ?>

        <form action="<?= base_url('community/post/update/' . $post['id']) ?>" method="POST" enctype="multipart/form-data" id="editPostForm">
            <?= csrf_field() ?>
            <input type="hidden" name="post_type" id="postTypeInput" value="<?= esc($post['post_type']) ?>">
            <input type="hidden" name="existing_image_paths" value="<?= esc(json_encode($post['image_paths'])) ?>">
            
            <!-- Type selector tabs (Disabled during edit for database type integrity, or just active styling) -->
            <label class="form-label" style="margin-bottom: 0.5rem; font-weight: 700; display: block;">Tipe Kiriman</label>
            <div class="post-type-selector" style="margin-bottom: 1.5rem; pointer-events: none; opacity: 0.75;">
                <button type="button" class="post-type-btn <?= $post['post_type'] === 'reflection' ? 'active' : '' ?>" id="btnReflection">Refleksi</button>
                <button type="button" class="post-type-btn <?= $post['post_type'] === 'mosque' ? 'active' : '' ?>" id="btnMosque">Review Masjid</button>
                <button type="button" class="post-type-btn <?= $post['post_type'] === 'event' ? 'active' : '' ?>" id="btnEvent">Info Event</button>
            </div>

            <!-- Name of Mosque (Hidden by default, shown for mosque type) -->
            <div class="form-group" id="mosqueNameGroup" style="display: <?= $post['post_type'] === 'mosque' ? 'block' : 'none' ?>; margin-bottom: 1.25rem;">
                <label class="form-label">Nama Masjid</label>
                <input
                    type="text"
                    name="mosque_name"
                    id="mosque_name"
                    class="form-input"
                    value="<?= esc($post['mosque_name']) ?>"
                    placeholder="Contoh: Masjid Raya Al-Azhar..."
                />
            </div>

            <!-- Event details (Hidden by default, shown for event type) -->
            <div id="eventDetailsGroup" style="display: <?= $post['post_type'] === 'event' ? 'block' : 'none' ?>; margin-bottom: 1.25rem;">
                <div class="form-group" style="margin-bottom: 1rem;">
                    <label class="form-label">Nama Kegiatan / Event</label>
                    <input
                        type="text"
                        name="event_name"
                        id="event_name"
                        class="form-input"
                        value="<?= esc($post['event_name']) ?>"
                        placeholder="Contoh: Kajian Duha Akbar..."
                    />
                </div>
                <div class="form-group" style="margin-bottom: 1rem;">
                    <label class="form-label">Waktu Event</label>
                    <input
                        type="text"
                        name="event_date"
                        id="event_date"
                        class="form-input"
                        value="<?= esc($post['event_date']) ?>"
                        placeholder="Contoh: Ahad, 5 Juni pukul 09:00 WIB"
                    />
                </div>
                <div class="form-group" style="margin-bottom: 1rem;">
                    <label class="form-label">Lokasi Event</label>
                    <input
                        type="text"
                        name="event_location"
                        id="event_location"
                        class="form-input"
                        value="<?= esc($post['event_location']) ?>"
                        placeholder="Contoh: Aula Masjid Al-Azhar Lantai 2"
                    />
                </div>
            </div>

            <!-- Content textarea -->
            <div class="form-group" style="margin-bottom: 1.25rem;">
                <label class="form-label">Isi Postingan</label>
                <textarea
                    name="content"
                    id="postContent"
                    class="form-input"
                    style="min-height: 120px; resize: vertical; padding: 0.85rem;"
                    required
                ><?= esc($post['content']) ?></textarea>
            </div>

            <!-- Mosque review facilities checklist (Hidden by default, shown for mosque type) -->
            <div class="form-group" id="mosqueReviewGroup" style="display: <?= $post['post_type'] === 'mosque' ? 'block' : 'none' ?>; margin-bottom: 1.5rem;">
                <label class="form-label">Review Fasilitas Masjid (Checklist)</label>
                <div class="checkbox-group">
                    <label class="checkbox-label">
                        <input type="checkbox" name="is_wudu_clean" value="1" <?= $post['is_wudu_clean'] ? 'checked' : '' ?> />
                        Tempat Wudhu Bersih
                    </label>
                    <label class="checkbox-label">
                        <input type="checkbox" name="is_ac_working" value="1" <?= $post['is_ac_working'] ? 'checked' : '' ?> />
                        AC / Kipas Berfungsi
                    </label>
                    <label class="checkbox-label">
                        <input type="checkbox" name="is_female_friendly" value="1" <?= $post['is_female_friendly'] ? 'checked' : '' ?> />
                        Ramah Jamaah Perempuan
                    </label>
                </div>
            </div>

            <!-- Images upload input -->
            <div class="form-group" style="margin-bottom: 2rem;">
                <label class="form-label">Ganti Foto (Opsional, akan menggantikan foto saat ini)</label>
                <input
                    type="file"
                    name="images[]"
                    id="postImages"
                    class="form-input"
                    accept="image/*"
                    multiple
                    style="padding: 0.5rem;"
                />
                <p style="font-size: 0.75rem; color: #64748b; margin-top: 0.35rem;">Unggah foto baru jika ingin mengganti galeri foto saat ini.</p>
                
                <!-- Current images preview -->
                <?php if (!empty($post['image_paths']) && is_array($post['image_paths'])) : ?>
                    <div id="currentImagesLabel" style="font-size: 0.8rem; font-weight: 700; color: #334155; margin-top: 1rem; margin-bottom: 0.5rem;">Foto Saat Ini:</div>
                    <div id="currentImagesContainer" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(100px, 1fr)); gap: 10px; margin-bottom: 1rem;">
                        <?php foreach ($post['image_paths'] as $imgPath) : ?>
                            <div style="position: relative; border-radius: 8px; overflow: hidden; padding-top: 100%; border: 1px solid #e2e8f0;">
                                <img src="<?= base_url($imgPath) ?>" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; object-fit: cover;" />
                            </div>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
                
                <!-- Image Preview Grid for new files -->
                <div id="imagePreviewContainer" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(100px, 1fr)); gap: 10px; margin-top: 10px;"></div>
            </div>

            <div style="display: flex; gap: 1rem;">
                <a href="<?= base_url('profile') ?>" class="btn-danger" style="flex: 1; text-align: center; text-decoration: none; display: flex; align-items: center; justify-content: center; font-weight: 700;">Batal</a>
                <button type="submit" class="btn-primary" style="flex: 2; font-weight: 700; padding: 0.85rem;">Simpan Perubahan</button>
            </div>
        </form>
    </div>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        const postType = "<?= esc($post['post_type']) ?>";
        const mosqueName = document.getElementById("mosque_name");
        const eventName = document.getElementById("event_name");
        const eventDate = document.getElementById("event_date");
        const eventLocation = document.getElementById("event_location");

        // Validate required attributes based on post type on page load
        if (postType === "mosque") {
            mosqueName.setAttribute("required", "required");
        } else if (postType === "event") {
            eventName.setAttribute("required", "required");
            eventDate.setAttribute("required", "required");
            eventLocation.setAttribute("required", "required");
        }

        // Image selection live preview
        const postImages = document.getElementById('postImages');
        const imagePreviewContainer = document.getElementById('imagePreviewContainer');
        const currentImagesContainer = document.getElementById('currentImagesContainer');
        const currentImagesLabel = document.getElementById('currentImagesLabel');

        if (postImages && imagePreviewContainer) {
            postImages.addEventListener('change', function() {
                imagePreviewContainer.innerHTML = '';
                const files = this.files;
                
                // Hide current images preview if new images are selected
                if (files && files.length > 0) {
                    if (currentImagesContainer) currentImagesContainer.style.display = 'none';
                    if (currentImagesLabel) currentImagesLabel.style.display = 'none';
                } else {
                    if (currentImagesContainer) currentImagesContainer.style.display = 'grid';
                    if (currentImagesLabel) currentImagesLabel.style.display = 'block';
                }
                
                if (files) {
                    Array.from(files).forEach(file => {
                        if (file.type.startsWith('image/')) {
                            const reader = new FileReader();
                            reader.onload = function(e) {
                                const previewDiv = document.createElement('div');
                                previewDiv.style.position = 'relative';
                                previewDiv.style.borderRadius = '8px';
                                previewDiv.style.overflow = 'hidden';
                                previewDiv.style.paddingTop = '100%'; // Aspect ratio 1:1
                                previewDiv.style.border = '1px solid #e2e8f0';

                                const img = document.createElement('img');
                                img.src = e.target.result;
                                img.style.position = 'absolute';
                                img.style.top = '0';
                                img.style.left = '0';
                                img.style.width = '100%';
                                img.style.height = '100%';
                                img.style.objectFit = 'cover';

                                previewDiv.appendChild(img);
                                imagePreviewContainer.appendChild(previewDiv);
                            };
                            reader.readAsDataURL(file);
                        }
                    });
                }
            });
        }
    });
</script>
<?= $this->endSection() ?>
