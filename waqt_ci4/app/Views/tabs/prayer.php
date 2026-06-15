<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div class="history-section-card">
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; border-bottom: 1px solid #f1f5f9; padding-bottom: 1rem;">
        <div>
            <h3 style="margin: 0;">Jadwal Sholat</h3>
            <p style="font-size: 0.85rem; color: #64748b; fontWeight: 500; margin: 0.25rem 0 0 0; cursor: pointer;" id="locationPickerTrigger">
                📍 <span id="labelSelectedCity">Jakarta</span>, Indonesia <span style="color: hsl(var(--primary)); font-size: 0.75rem;">(Ganti Kota)</span>
            </p>
        </div>
        
        <!-- Alarm Status Indicator -->
        <div style="display: flex; align-items: center; gap: 0.75rem;">
            <button id="btnToggleMute" style="background: white; border: 1px solid #e2e8f0; border-radius: 50%; width: 38px; height: 38px; font-size: 1.2rem; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: var(--transition);">
                <span id="muteStatusIcon">🔔</span>
            </button>
            <button id="alarmPickerTrigger" style="background: white; border: 1px solid #e2e8f0; border-radius: 10px; padding: 0.45rem 0.85rem; font-size: 0.75rem; font-weight: 700; color: hsl(var(--primary)); cursor: pointer; transition: var(--transition);">
                🎵 <span id="labelSelectedAdzan">Adzan Bilal</span>
            </button>
        </div>
    </div>

    <!-- Prayer item list -->
    <div class="schedule-grid" id="prayerSchedulesGrid">
        <!-- Will be populated dynamically by JS for active highlights -->
        <div class="qada-item-card" id="row-Fajr" style="border: 1px solid rgba(0,0,0,0.04);">
            <div class="qada-item-left">
                <div class="qada-item-icon-circle done" style="background-color: #F5E9DA; color: hsl(var(--primary));">☀️</div>
                <div class="qada-item-info">
                    <span class="qada-item-name">Fajr</span>
                    <span class="active-label" style="font-size: 0.75rem; color: rgba(255,255,255,0.8); font-weight: 600; display: none;">Aktif Sekarang</span>
                </div>
            </div>
            <span style="font-family: Outfit; font-size: 1.2rem; font-weight: bold; color: hsl(var(--primary));">04:42</span>
        </div>

        <div class="qada-item-card" id="row-Dzuhur" style="border: 1px solid rgba(0,0,0,0.04);">
            <div class="qada-item-left">
                <div class="qada-item-icon-circle done" style="background-color: #F5E9DA; color: hsl(var(--primary));">☀️</div>
                <div class="qada-item-info">
                    <span class="qada-item-name">Dzuhur</span>
                    <span class="active-label" style="font-size: 0.75rem; color: rgba(255,255,255,0.8); font-weight: 600; display: none;">Aktif Sekarang</span>
                </div>
            </div>
            <span style="font-family: Outfit; font-size: 1.2rem; font-weight: bold; color: hsl(var(--primary));">11:58</span>
        </div>

        <div class="qada-item-card" id="row-Ashar" style="border: 1px solid rgba(0,0,0,0.04);">
            <div class="qada-item-left">
                <div class="qada-item-icon-circle done" style="background-color: #F5E9DA; color: hsl(var(--primary));">🌤️</div>
                <div class="qada-item-info">
                    <span class="qada-item-name">Ashar</span>
                    <span class="active-label" style="font-size: 0.75rem; color: rgba(255,255,255,0.8); font-weight: 600; display: none;">Aktif Sekarang</span>
                </div>
            </div>
            <span style="font-family: Outfit; font-size: 1.2rem; font-weight: bold; color: hsl(var(--primary));">15:19</span>
        </div>

        <div class="qada-item-card" id="row-Maghrib" style="border: 1px solid rgba(0,0,0,0.04);">
            <div class="qada-item-left">
                <div class="qada-item-icon-circle done" style="background-color: #F5E9DA; color: hsl(var(--primary));">🌙</div>
                <div class="qada-item-info">
                    <span class="qada-item-name">Maghrib</span>
                    <span class="active-label" style="font-size: 0.75rem; color: rgba(255,255,255,0.8); font-weight: 600; display: none;">Aktif Sekarang</span>
                </div>
            </div>
            <span style="font-family: Outfit; font-size: 1.2rem; font-weight: bold; color: hsl(var(--primary));">17:53</span>
        </div>

        <div class="qada-item-card" id="row-Isha" style="border: 1px solid rgba(0,0,0,0.04);">
            <div class="qada-item-left">
                <div class="qada-item-icon-circle done" style="background-color: #F5E9DA; color: hsl(var(--primary));">🌙</div>
                <div class="qada-item-info">
                    <span class="qada-item-name">Isha</span>
                    <span class="active-label" style="font-size: 0.75rem; color: rgba(255,255,255,0.8); font-weight: 600; display: none;">Aktif Sekarang</span>
                </div>
            </div>
            <span style="font-family: Outfit; font-size: 1.2rem; font-weight: bold; color: hsl(var(--primary));">19:06</span>
        </div>
    </div>
</div>

<!-- MODAL: LOCATION DIALOG -->
<div class="auth-container" id="locationModal" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; zIndex: 1000; backgroundColor: rgba(0,0,0,0.5); display: none;">
    <div class="auth-card" style="max-width: 380px; text-align: left; padding: 2rem;">
        <h3 style="font-family: 'DM Serif Display', serif; font-size: 1.6rem; color: hsl(var(--primary)); margin-bottom: 1.25rem; text-align: center;">Pilih Kota</h3>
        <div style="display: flex; flex-direction: column; gap: 0.5rem; max-height: 240px; overflow-y: auto; margin-bottom: 1.5rem; padding-right: 0.5rem;" id="locationModalList">
            <!-- Will be populated dynamically by JS -->
        </div>
        <button class="btn-danger" id="btnCancelLocation">Batal</button>
    </div>
</div>

<!-- MODAL: ADZAN SELECTION DIALOG -->
<div class="auth-container" id="adzanModal" style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; zIndex: 1000; backgroundColor: rgba(0,0,0,0.5); display: none;">
    <div class="auth-card" style="max-width: 380px; text-align: left; padding: 2rem;">
        <h3 style="font-family: 'DM Serif Display', serif; font-size: 1.6rem; color: hsl(var(--primary)); margin-bottom: 1.25rem; text-align: center;">Pilih Nada Adzan</h3>
        <div style="display: flex; flex-direction: column; gap: 0.85rem; margin-bottom: 1.5rem;" id="adzanModalList">
            <!-- Will be populated dynamically by JS -->
        </div>
        <button class="btn-danger" id="btnCancelAdzan">Batal</button>
    </div>
</div>
<?= $this->endSection() ?>
