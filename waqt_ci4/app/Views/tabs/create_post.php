<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div style="max-width: 700px; margin: 0 auto; padding-bottom: 3rem;">
    <div style="margin-bottom: 1.5rem;">
        <a href="<?= base_url('community') ?>" class="btn-back-link">
            ⬅️ Kembali ke Komunitas
        </a>
    </div>

    <div class="history-section-card" style="padding: 2.25rem;">
        <h2 style="font-family: 'Outfit', sans-serif; font-size: 1.75rem; color: hsl(var(--primary)); margin-bottom: 0.5rem; font-weight: 800;">Tulis Kiriman Baru</h2>
        <p style="font-size: 0.9rem; color: #64748b; margin-bottom: 2rem;">Bagikan renungan spiritual, review masjid, atau info kegiatan/event terdekat.</p>

        <?php if (session()->getFlashdata('error')) : ?>
            <div class="error-banner" style="margin-bottom: 1.5rem;">
                <?= esc(session()->getFlashdata('error')) ?>
            </div>
        <?php endif; ?>

        <form action="<?= base_url('community/post') ?>" method="POST" enctype="multipart/form-data" id="composePostForm">
            <?= csrf_field() ?>
            <input type="hidden" name="post_type" id="postTypeInput" value="reflection">
            
            <!-- Type selector tabs -->
            <label class="form-label" style="margin-bottom: 0.5rem; font-weight: 700; display: block;">Tipe Kiriman</label>
            <div class="post-type-selector" style="margin-bottom: 1.5rem;">
                <button type="button" class="post-type-btn active" id="btnReflection">Refleksi</button>
                <button type="button" class="post-type-btn" id="btnMosque">Review Masjid</button>
                <button type="button" class="post-type-btn" id="btnEvent">Info Event</button>
            </div>

            <!-- Name of Mosque (Hidden by default, shown for mosque type) -->
            <div class="form-group" id="mosqueNameGroup" style="display: none; margin-bottom: 1.25rem;">
                <label class="form-label">Nama Masjid</label>
                <input
                    type="text"
                    name="mosque_name"
                    id="mosque_name"
                    class="form-input"
                    placeholder="Contoh: Masjid Raya Al-Azhar..."
                />
            </div>

            <!-- Event details (Hidden by default, shown for event type) -->
            <div id="eventDetailsGroup" style="display: none; margin-bottom: 1.25rem;">
                <div class="form-group" style="margin-bottom: 1rem;">
                    <label class="form-label">Nama Kegiatan / Event</label>
                    <input
                        type="text"
                        name="event_name"
                        id="event_name"
                        class="form-input"
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
                    placeholder="Tulis refleksi spiritual atau renungan..."
                    required
                ></textarea>
            </div>

            <!-- Mosque review facilities checklist (Hidden by default, shown for mosque type) -->
            <div class="form-group" id="mosqueReviewGroup" style="display: none; margin-bottom: 1.5rem;">
                <label class="form-label">Review Fasilitas Masjid (Checklist)</label>
                <div class="checkbox-group">
                    <label class="checkbox-label">
                        <input type="checkbox" name="is_wudu_clean" value="1" />
                        Tempat Wudhu Bersih
                    </label>
                    <label class="checkbox-label">
                        <input type="checkbox" name="is_ac_working" value="1" />
                        AC / Kipas Berfungsi
                    </label>
                    <label class="checkbox-label">
                        <input type="checkbox" name="is_female_friendly" value="1" />
                        Ramah Jamaah Perempuan
                    </label>
                </div>
            </div>

            <!-- Images upload input -->
            <div class="form-group" style="margin-bottom: 2rem;">
                <label class="form-label">Unggah Foto (Bisa lebih dari satu)</label>
                <input
                    type="file"
                    name="images[]"
                    id="postImages"
                    class="form-input"
                    accept="image/*"
                    multiple
                    style="padding: 0.5rem;"
                />
                <p style="font-size: 0.75rem; color: #64748b; margin-top: 0.35rem;">Format: JPG, PNG, JPEG. Anda dapat memilih beberapa gambar sekaligus untuk dijadikan galeri geser (carousel).</p>
                
                <!-- Image Preview Grid -->
                <div id="imagePreviewContainer" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(100px, 1fr)); gap: 10px; margin-top: 10px;"></div>
            </div>

            <div style="display: flex; gap: 1rem;">
                <a href="<?= base_url('community') ?>" class="btn-danger" style="flex: 1; text-align: center; text-decoration: none; display: flex; align-items: center; justify-content: center; font-weight: 700;">Batal</a>
                <button type="submit" class="btn-primary" style="flex: 2; font-weight: 700; padding: 0.85rem;">Publikasikan Kiriman</button>
            </div>
        </form>
    </div>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        const btnReflection = document.getElementById("btnReflection");
        const btnMosque = document.getElementById("btnMosque");
        const btnEvent = document.getElementById("btnEvent");
        const postTypeInput = document.getElementById("postTypeInput");
        const mosqueNameGroup = document.getElementById("mosqueNameGroup");
        const mosqueReviewGroup = document.getElementById("mosqueReviewGroup");
        const eventDetailsGroup = document.getElementById("eventDetailsGroup");
        const postContent = document.getElementById("postContent");

        const mosqueName = document.getElementById("mosque_name");
        const eventName = document.getElementById("event_name");
        const eventDate = document.getElementById("event_date");
        const eventLocation = document.getElementById("event_location");

        function setType(type) {
            postTypeInput.value = type;
            btnReflection.classList.remove("active");
            btnMosque.classList.remove("active");
            btnEvent.classList.remove("active");

            if (type === "reflection") {
                btnReflection.classList.add("active");
                mosqueNameGroup.style.display = "none";
                mosqueReviewGroup.style.display = "none";
                eventDetailsGroup.style.display = "none";
                postContent.placeholder = "Tulis refleksi spiritual atau renungan...";
                mosqueName.removeAttribute("required");
                eventName.removeAttribute("required");
                eventDate.removeAttribute("required");
                eventLocation.removeAttribute("required");
            } else if (type === "mosque") {
                btnMosque.classList.add("active");
                mosqueNameGroup.style.display = "block";
                mosqueReviewGroup.style.display = "block";
                eventDetailsGroup.style.display = "none";
                postContent.placeholder = "Bagaimana kebersihan wudhu atau AC masjid ini?";
                mosqueName.setAttribute("required", "required");
                eventName.removeAttribute("required");
                eventDate.removeAttribute("required");
                eventLocation.removeAttribute("required");
            } else if (type === "event") {
                btnEvent.classList.add("active");
                mosqueNameGroup.style.display = "none";
                mosqueReviewGroup.style.display = "none";
                eventDetailsGroup.style.display = "block";
                postContent.placeholder = "Tulis deskripsi detail event atau kegiatan masjid...";
                mosqueName.removeAttribute("required");
                eventName.setAttribute("required", "required");
                eventDate.setAttribute("required", "required");
                eventLocation.setAttribute("required", "required");
            }
        }

        btnReflection.addEventListener("click", () => setType("reflection"));
        btnMosque.addEventListener("click", () => setType("mosque"));
        btnEvent.addEventListener("click", () => setType("event"));

        // Image selection live preview
        const postImages = document.getElementById('postImages');
        const imagePreviewContainer = document.getElementById('imagePreviewContainer');

        if (postImages && imagePreviewContainer) {
            postImages.addEventListener('change', function() {
                imagePreviewContainer.innerHTML = '';
                const files = this.files;
                
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
