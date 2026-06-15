<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WAQT - Desktop Companion Dashboard</title>
    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=DM+Serif+Display:ital@0;1&family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <!-- Main Style CSS -->
    <link rel="stylesheet" href="<?= base_url('css/app.css') ?>">
</head>
<body>
    <div class="app-layout">
        <!-- TOPBAR / NAVBAR -->
        <header class="topbar">
            <div class="topbar-left">
                <a href="<?= base_url('dashboard') ?>" class="logo-link">
                    <span class="logo-icon">🕌</span>
                    <span class="logo-text">WAQT</span>
                </a>
            </div>
            
            <nav class="top-nav">
                <a href="<?= base_url('dashboard') ?>" class="top-nav-item <?= ($activeTab === 'dashboard') ? 'active' : '' ?>">
                    Dashboard
                </a>
                <a href="<?= base_url('prayer') ?>" class="top-nav-item <?= ($activeTab === 'schedule') ? 'active' : '' ?>">
                    Jadwal
                </a>
                <a href="<?= base_url('history') ?>" class="top-nav-item <?= ($activeTab === 'history') ? 'active' : '' ?>">
                    Riwayat
                </a>
                <a href="<?= base_url('community') ?>" class="top-nav-item <?= ($activeTab === 'community') ? 'active' : '' ?>">
                    Komunitas
                </a>
                <a href="<?= base_url('profile') ?>" class="top-nav-item <?= ($activeTab === 'profile') ? 'active' : '' ?>">
                    Profile
                </a>
            </nav>
            
            <div class="topbar-right">
                <div class="topbar-user-info">
                    <div id="topbarAvatarContainer">
                        <div class="topbar-avatar-fallback"><?= strtoupper(substr($username ?? 'W', 0, 1)) ?></div>
                    </div>
                    <span class="topbar-username"><?= esc($username) ?></span>
                </div>
                <a href="<?= base_url('logout') ?>" class="btn-topbar-logout">Keluar</a>
            </div>
        </header>

        <!-- MAIN CONTAINER -->
        <div class="main-container">
            <!-- CONTENT AREA -->
            <main class="content-area">
                <?= $this->renderSection('content') ?>
            </main>
        </div>
    </div>

    <!-- Client-side configurations -->
    <script>
        window.sessionToken = '<?= $session_token ?? "" ?>';
        window.currentUsername = '<?= $username ?? "" ?>';
        window.apiBaseUrl = '<?= base_url('api') ?>';
        window.activeTab = '<?= $activeTab ?? "dashboard" ?>';
        window.baseUrl = '<?= base_url() ?>';
    </script>
    
    <!-- Main JavaScript App -->
    <script src="<?= base_url('js/app.js') ?>"></script>
</body>
</html>
