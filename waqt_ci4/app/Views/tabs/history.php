<?= $this->extend('layouts/main') ?>

<?= $this->section('content') ?>
<div>
    <!-- Header Card -->
    <div class="history-section-card" style="margin-bottom: 1.5rem;">
        <h3 style="margin: 0;">History</h3>
        <p style="font-size: 0.85rem; color: #64748b; font-weight: 500; margin: 0.25rem 0 0 0;">Your prayer journey this week</p>
    </div>

    <!-- Weekly calendar row -->
    <div class="web-date-card" style="flex-direction: row; justify-content: space-between; padding: 1.25rem 0.75rem; margin-bottom: 2rem;" id="calendarRowContainer">
        <!-- Will be populated dynamically by JS -->
    </div>

    <!-- Selected Day Status List -->
    <div class="history-section-card">
        <h3 style="font-size: 1.2rem; margin-bottom: 1.5rem;" id="selectedDateTitle">Prayer Status</h3>
        <div class="qada-list-container" id="historyPrayerListContainer" style="display: flex; flex-direction: column; gap: 0.75rem;">
            <!-- Will be populated dynamically by JS -->
        </div>
    </div>
</div>
<?= $this->endSection() ?>
