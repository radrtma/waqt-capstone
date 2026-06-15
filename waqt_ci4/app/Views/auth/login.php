<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WAQT - Masuk / Daftar</title>
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Main Style CSS -->
    <link rel="stylesheet" href="<?= base_url('css/app.css') ?>">
</head>
<body>
    <div class="auth-container">
        <div class="auth-card">
            <h1 class="auth-logo">WAQT</h1>
            <p id="authSubtitle" class="auth-subtitle">Masuk untuk memantau ibadah & komunitas</p>

            <?php if (session()->getFlashdata('error')) : ?>
                <div class="error-banner">
                    <?= esc(session()->getFlashdata('error')) ?>
                </div>
            <?php endif; ?>

            <form action="<?= base_url('login') ?>" method="POST" id="authForm">
                <?= csrf_field() ?>
                <input type="hidden" name="auth_mode" id="authMode" value="login">

                <div class="form-group" style="text-align: left; margin-bottom: 1.25rem;">
                    <label class="form-label" for="username">Username</label>
                    <input
                        id="username"
                        name="username"
                        type="text"
                        class="form-input"
                        placeholder="Ketik username"
                        value="<?= old('username') ?>"
                        required
                    />
                </div>

                <div class="form-group" id="passwordGroup" style="text-align: left; margin-bottom: 2rem;">
                    <label class="form-label" for="password">Password</label>
                    <input
                        id="password"
                        name="password"
                        type="password"
                        class="form-input"
                        placeholder="Ketik password"
                        required
                    />
                </div>

                <div class="form-group" id="confirmPasswordGroup" style="text-align: left; margin-bottom: 2rem; display: none;">
                    <label class="form-label" for="confirm_password">Masukan Kembali Password Anda</label>
                    <input
                        id="confirm_password"
                        name="confirm_password"
                        type="password"
                        class="form-input"
                        placeholder="Masukkan kembali password"
                    />
                </div>

                <button type="submit" id="authSubmitBtn" class="btn-primary">
                    Masuk
                </button>
            </form>
 
            <div class="toggle-mode">
                <span id="toggleText">Belum punya akun?</span>
                <span id="toggleLink" class="toggle-link">Daftar Sekarang</span>
            </div>
        </div>
    </div>
 
    <script>
        // Clear user-specific local storage state to prevent data pollution between logins
        localStorage.removeItem('streak_count');
        localStorage.removeItem('streak_is_frozen');
        localStorage.removeItem('last_update_date');
        localStorage.removeItem('qada_list');
        localStorage.removeItem('history_list');
        localStorage.removeItem('username');
 
        const authMode = document.getElementById('authMode');
        const authSubtitle = document.getElementById('authSubtitle');
        const authSubmitBtn = document.getElementById('authSubmitBtn');
        const toggleText = document.getElementById('toggleText');
        const toggleLink = document.getElementById('toggleLink');
        const confirmPasswordGroup = document.getElementById('confirmPasswordGroup');
        const confirmPasswordInput = document.getElementById('confirm_password');
        const passwordGroup = document.getElementById('passwordGroup');
 
        toggleLink.addEventListener('click', function() {
            if (authMode.value === 'login') {
                authMode.value = 'register';
                authSubtitle.textContent = 'Daftar akun web baru Anda';
                authSubmitBtn.textContent = 'Daftar Akun';
                toggleText.textContent = 'Sudah punya akun?';
                toggleLink.textContent = 'Masuk di sini';
                confirmPasswordGroup.style.display = 'block';
                confirmPasswordInput.required = true;
                passwordGroup.style.marginBottom = '1.25rem';
            } else {
                authMode.value = 'login';
                authSubtitle.textContent = 'Masuk untuk memantau ibadah & komunitas';
                authSubmitBtn.textContent = 'Masuk';
                toggleText.textContent = 'Belum punya akun?';
                toggleLink.textContent = 'Daftar Sekarang';
                confirmPasswordGroup.style.display = 'none';
                confirmPasswordInput.required = false;
                confirmPasswordInput.value = '';
                passwordGroup.style.marginBottom = '2rem';
            }
        });

        const authForm = document.getElementById('authForm');
        authForm.addEventListener('submit', function(e) {
            if (authMode.value === 'register') {
                const password = document.getElementById('password').value;
                const confirmPassword = confirmPasswordInput.value;
                if (password !== confirmPassword) {
                    e.preventDefault();
                    alert('Masukkan kembali password Anda dengan benar (Konfirmasi password tidak cocok)!');
                }
            }
        });
    </script>
</body>
</html>
