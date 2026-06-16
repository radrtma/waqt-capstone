// WAQT Desktop Companion Client Script
// Coordinates client state, handles AJAX syncing and UI updates

(function() {
    // ----------------------------------------------------
    // 1. Initial State & Configuration
    // ----------------------------------------------------
    const token = window.sessionToken || '';
    const username = window.currentUsername || '';
    const apiBaseUrl = window.apiBaseUrl || 'http://localhost:3000/api';
    const activeTab = window.activeTab || 'dashboard';
    const baseUrl = window.baseUrl || '';

    let streakCount = parseInt(localStorage.getItem('streak_count') || '0');
    let isFrozen = localStorage.getItem('streak_is_frozen') === 'true';
    let historyList = JSON.parse(localStorage.getItem('history_list') || '[]');
    let qadaList = JSON.parse(localStorage.getItem('qada_list') || '[]');
    let lastUpdateDate = localStorage.getItem('last_update_date') || new Date().toISOString().split('T')[0];

    let prayerStates = {
        Fajr: false, Dzuhur: false, Ashar: false, Maghrib: false, Isha: false
    };

    const _todayStr = new Date().toISOString().split('T')[0];
    const _todayRecord = historyList.find(h => h.date === _todayStr);
    if (_todayRecord) {
        prayerStates = {
            Fajr: _todayRecord.Fajr,
            Dzuhur: _todayRecord.Dzuhur,
            Ashar: _todayRecord.Ashar,
            Maghrib: _todayRecord.Maghrib,
            Isha: _todayRecord.Isha
        };
    }

    const timings = {
        Fajr: '04:42',
        Dzuhur: '11:58',
        Ashar: '15:19',
        Maghrib: '17:53',
        Isha: '19:06'
    };

    const adzanOptions = {
        bilal: 'Adzan Bilal',
        rcti: 'Adzan RCTI',
        rost_1: 'Adzan Rost 1',
        rost_2: 'Adzan Rost 2',
        upinipin: 'Adzan Upin Ipin',
    };

    const cityOptions = {
        'Jakarta': 'Indonesia',
        'Bandung': 'Indonesia',
        'Surabaya': 'Indonesia',
        'Semarang': 'Indonesia',
        'Medan': 'Indonesia',
        'Makassar': 'Indonesia',
        'Yogyakarta': 'Indonesia',
        'Palembang': 'Indonesia',
        'Denpasar': 'Indonesia',
    };

    let selectedAdzan = localStorage.getItem('selected_adzan') || 'bilal';
    let isAdzanMuted = localStorage.getItem('is_adzan_muted') === 'true';
    let selectedCity = localStorage.getItem('selected_city') || 'Jakarta';
    let selectedHistoryDate = new Date();

    // ----------------------------------------------------
    // 2. Global Utilities
    // ----------------------------------------------------
    function getActivePrayer() {
        const now = new Date();
        const nowTime = now.getHours() * 60 + now.getMinutes();
        const prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
        
        let active = 'Isha';
        for (let name of prayerNames) {
            const [h, m] = timings[name].split(':').map(Number);
            const prayerMinutes = h * 60 + m;
            if (nowTime >= prayerMinutes) {
                active = name;
            } else {
                break;
            }
        }
        return active;
    }

    function getNextPrayer() {
        const now = new Date();
        const prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
        const currentHour = now.getHours();
        const currentMinute = now.getMinutes();

        for (let name of prayerNames) {
            const [h, m] = timings[name].split(':').map(Number);
            if (currentHour < h || (currentHour === h && currentMinute < m)) {
                return name;
            }
        }
        return 'Fajr';
    }

    function getCountdown(prayerName) {
        const now = new Date();
        const [h, m] = timings[prayerName].split(':').map(Number);
        const target = new Date();
        target.setHours(h, m, 0, 0);

        let diff = target - now;
        if (diff < 0) {
            target.setDate(target.getDate() + 1);
            diff = target - now;
        }

        const hours = Math.floor(diff / 3600000);
        const minutes = Math.floor((diff % 3600000) / 60000);
        const seconds = Math.floor((diff % 60000) / 1000);

        const pad = (num) => String(num).padStart(2, '0');
        return `${pad(hours)} : ${pad(minutes)} : ${pad(seconds)}`;
    }

    function isPrayerTimeReached(prayerName) {
        const now = new Date();
        const timeStr = timings[prayerName];
        const [h, m] = timeStr.split(':').map(Number);
        const prayerTime = new Date();
        prayerTime.setHours(h, m, 0, 0);
        return now >= prayerTime;
    }

    function isPrayerMissed(prayerName) {
        if (prayerStates[prayerName] === true) return false;
        const prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
        const currentIndex = prayerNames.indexOf(prayerName);
        const now = new Date();

        let nextPrayerName;
        let isNextDay = false;

        if (currentIndex < prayerNames.length - 1) {
            nextPrayerName = prayerNames[currentIndex + 1];
        } else {
            nextPrayerName = 'Fajr';
            isNextDay = true;
        }

        const timeStr = timings[nextPrayerName];
        const [h, m] = timeStr.split(':').map(Number);
        const endTime = new Date();
        endTime.setHours(h, m, 0, 0);
        if (isNextDay) {
            endTime.setDate(endTime.getDate() + 1);
        }

        return now > endTime;
    }

    function getPrayerIcon(name) {
        switch (name.toLowerCase()) {
            case 'fajr': return '☀️';
            case 'dzuhur': return '☀️';
            case 'ashar': return '🌤️';
            case 'maghrib': return '🌙';
            case 'isha':
            default: return '🌙';
        }
    }

    async function fetchPrayerTimings(city = 'Jakarta') {
        const country = 'Indonesia';
        const method = 11; // Kemenag Indonesia
        const url = `https://api.aladhan.com/v1/timingsByCity?city=${encodeURIComponent(city)}&country=${encodeURIComponent(country)}&method=${method}`;
        const today = new Date().toISOString().split('T')[0];

        try {
            // Check cache
            const cachedDate = localStorage.getItem('prayer_cache_date');
            const cachedCity = localStorage.getItem('prayer_cache_city');
            const cachedJson = localStorage.getItem('prayer_cache_json');
            
            let data;
            if (cachedDate === today && cachedCity === city && cachedJson) {
                data = JSON.parse(cachedJson);
            } else {
                const response = await fetch(url);
                if (response.ok) {
                    data = await response.json();
                    localStorage.setItem('prayer_cache_date', today);
                    localStorage.setItem('prayer_cache_city', city);
                    localStorage.setItem('prayer_cache_json', JSON.stringify(data));
                } else {
                    throw new Error('Aladhan API request failed');
                }
            }

            if (data && data.data && data.data.timings) {
                const apiTimings = data.data.timings;
                timings.Fajr = apiTimings.Fajr.split(' ')[0];
                timings.Dzuhur = apiTimings.Dhuhr.split(' ')[0];
                timings.Ashar = apiTimings.Asr.split(' ')[0];
                timings.Maghrib = apiTimings.Maghrib.split(' ')[0];
                timings.Isha = apiTimings.Isha.split(' ')[0];

                // Update Hijri date in view if exists
                const hijri = data.data.date.hijri;
                const hijriStr = `${hijri.day} ${hijri.month.en} ${hijri.year} H`;
                document.querySelectorAll('.web-date-hijri').forEach(el => {
                    el.textContent = hijriStr;
                });

                // Re-render schedule timings text in schedules page
                const list = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
                list.forEach(name => {
                    const row = document.getElementById(`row-${name}`);
                    if (row) {
                        const timeSpan = row.querySelector('span[style*="Outfit"]');
                        if (timeSpan) {
                            timeSpan.textContent = timings[name];
                        }
                    }
                });

                updateWidgetsUI();
                runTicker();
            }
        } catch (e) {
            console.error('Failed to fetch prayer timings:', e);
        }
    }

    function checkRealTimeLogic() {
        if (!token) return;
        const todayStr = new Date().toISOString().split('T')[0];

        // 1. Day Change Check (Midnight Reset or Increment)
        if (todayStr !== lastUpdateDate) {
            const unpaidQada = qadaList.filter(q => !q.is_completed);
            if (unpaidQada.length > 0) {
                streakCount = 0; // Streak reset to 0
                qadaList = []; // clear uncompleted qada
                localStorage.setItem('qada_list', JSON.stringify(qadaList));
                console.log('Streak EXTINGUISHED because Qada was not cleared.');
            } else {
                streakCount++; // Streak increments
                console.log('Streak incremented to ' + streakCount);
            }

            isFrozen = false;
            prayerStates = {
                Fajr: false,
                Dzuhur: false,
                Ashar: false,
                Maghrib: false,
                Isha: false
            };

            lastUpdateDate = todayStr;
            localStorage.setItem('last_update_date', todayStr);
            localStorage.setItem('streak_count', streakCount.toString());
            localStorage.setItem('streak_is_frozen', 'false');

            updateWidgetsUI();
            performSync();
            return;
        }

        // 2. Real-time Missed Prayer check (Freeze immediately)
        const prayerNames = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
        let newlyMissed = false;

        for (let name of prayerNames) {
            const missed = isPrayerMissed(name);
            const completed = prayerStates[name];
            const alreadyInQada = qadaList.some(q => q.prayer_name === name && q.date_missed === todayStr);

            if (missed && !completed && !alreadyInQada) {
                isFrozen = true;
                const uuid = 'qada_' + Math.random().toString(36).substr(2, 9);
                qadaList.push({
                    uuid: uuid,
                    prayer_name: name,
                    date_missed: todayStr,
                    is_completed: false
                });

                localStorage.setItem('qada_list', JSON.stringify(qadaList));
                localStorage.setItem('streak_is_frozen', 'true');
                newlyMissed = true;
                console.log('RealTime: Missed ' + name + ' recorded as Qada.');
            }
        }

        if (newlyMissed) {
            updateWidgetsUI();
            performSync();
        }
    }

    // ----------------------------------------------------
    // 3. REST API Sync Logic
    // ----------------------------------------------------
    async function performSync(customQadaList = null) {
        if (!token) return;
        
        try {
            const historyPayload = historyList.map(h => ({
                date: h.date,
                fajr_done: h.Fajr,
                dzuhur_done: h.Dzuhur,
                ashar_done: h.Ashar,
                maghrib_done: h.Maghrib,
                isha_done: h.Isha
            }));

            const qadaPayload = (customQadaList || qadaList).map(q => ({
                uuid: q.uuid,
                prayer_name: q.prayer_name,
                date_missed: q.date_missed,
                is_completed: q.is_completed
            }));

            const response = await fetch(`${apiBaseUrl}/sync`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    streak: {
                        count: streakCount,
                        is_frozen: isFrozen,
                        last_updated_date: new Date().toISOString().split('T')[0]
                    },
                    history: historyPayload,
                    qada: qadaPayload
                })
            });

            if (response.ok) {
                const data = await response.json();
                if (data.status === 'success') {
                    streakCount = data.streak.count;
                    
                    if (data.qada) {
                        qadaList = data.qada;
                        localStorage.setItem('qada_list', JSON.stringify(qadaList));
                    }

                    // Force isFrozen based on unpaid Qada entries (self-healing alignment with Flutter)
                    const pendingQadaCount = qadaList.filter(q => !q.is_completed).length;
                    isFrozen = (pendingQadaCount > 0);
                    
                    localStorage.setItem('streak_count', streakCount.toString());
                    localStorage.setItem('streak_is_frozen', isFrozen.toString());

                    if (data.history && data.history.length > 0) {
                        historyList = data.history.map(h => ({
                            date: h.date,
                            Fajr: h.fajr_done,
                            Dzuhur: h.dzuhur_done,
                            Ashar: h.ashar_done,
                            Maghrib: h.maghrib_done,
                            Isha: h.isha_done
                        }));
                        localStorage.setItem('history_list', JSON.stringify(historyList));

                        // Sync today's checkbox values
                        const todayStr = new Date().toISOString().split('T')[0];
                        const todayRecord = historyList.find(h => h.date === todayStr);
                        if (todayRecord) {
                            prayerStates = {
                                Fajr: todayRecord.Fajr,
                                Dzuhur: todayRecord.Dzuhur,
                                Ashar: todayRecord.Ashar,
                                Maghrib: todayRecord.Maghrib,
                                Isha: todayRecord.Isha
                            };
                        } else {
                             // Force reset if no record today
                             prayerStates = { Fajr: false, Dzuhur: false, Ashar: false, Maghrib: false, Isha: false };
                        }
                    } else {
                        // Force reset if server has absolutely no history
                        historyList = [];
                        localStorage.removeItem('history_list');
                        prayerStates = { Fajr: false, Dzuhur: false, Ashar: false, Maghrib: false, Isha: false };
                    }

                    updateWidgetsUI();
                }
            }
        } catch (e) {
            console.error('Data Sync failed:', e);
        }
    }

    // ----------------------------------------------------
    // 4. UI Elements Renderer & Update
    // ----------------------------------------------------
    function initializeUserAvatars() {
        const pic = localStorage.getItem(`profile_pic_${username}`) || '';
        
        // Update topbar avatar
        const topbarAvatarContainer = document.getElementById('topbarAvatarContainer');
        if (topbarAvatarContainer) {
            if (pic) {
                topbarAvatarContainer.innerHTML = `<img src="${pic}" alt="${username}" class="topbar-avatar">`;
            } else {
                topbarAvatarContainer.innerHTML = `<div class="topbar-avatar-fallback">${username ? username[0].toUpperCase() : ''}</div>`;
            }
        }

        // Profile tab avatar
        const profilePictureContainer = document.getElementById('profilePictureContainer');
        if (profilePictureContainer) {
            if (pic) {
                profilePictureContainer.innerHTML = `<img src="${pic}" alt="${username}" style="width: 72px; height: 72px; borderRadius: 50%; objectFit: cover; display: block;">`;
            } else {
                profilePictureContainer.innerHTML = `
                    <div style="width: 72px; height: 72px; borderRadius: 50%; backgroundColor: #F5E9DA; display: flex; alignItems: center; justifyContent: center; fontSize: 2rem; color: hsl(var(--primary)); fontWeight: bold;">
                        ${username ? username[0].toUpperCase() : ''}
                    </div>`;
            }
        }

        // Pre-rendered author avatars on community page
        document.querySelectorAll('.feed-avatar-dummy').forEach(div => {
            const author = div.getAttribute('data-author');
            const authorPic = localStorage.getItem(`profile_pic_${author}`) || '';
            if (authorPic) {
                div.innerHTML = `<img src="${authorPic}" alt="${author}" class="feed-avatar-image">`;
                div.style.backgroundColor = 'transparent';
                div.style.border = 'none';
            }
        });
    }

    function updateWidgetsUI() {
        // Update streak count badges
        const badgeCount = document.getElementById('streakBadgeCount');
        const badgeIcon = document.getElementById('streakBadgeIcon');
        if (badgeCount) {
            badgeCount.textContent = `${streakCount}x`;
            badgeCount.className = 'web-streak-count';
            if (isFrozen) badgeCount.classList.add('frozen');
            else if (streakCount === 0) badgeCount.classList.add('off');
        }
        if (badgeIcon) {
            let iconSrc = `${baseUrl}/assets/icon_streak.png`;
            if (isFrozen) iconSrc = `${baseUrl}/assets/icon_streak_freeze.png`;
            else if (streakCount === 0) iconSrc = `${baseUrl}/assets/icon_streak_off.png`;
            badgeIcon.src = iconSrc;
        }

        // Streak sub-view
        const streakHeroCard = document.getElementById('streakHeroCard');
        const streakHeroIcon = document.getElementById('streakHeroIcon');
        const streakHeroNumber = document.getElementById('streakHeroNumber');
        const streakHeroLabel = document.getElementById('streakHeroLabel');
        const streakRestoreWarning = document.getElementById('streakRestoreWarning');

        if (streakHeroCard) {
            streakHeroCard.className = 'streak-hero-card ' + (isFrozen ? 'blue' : (streakCount === 0) ? 'grey' : 'gold');
            streakHeroNumber.textContent = streakCount;
            streakHeroLabel.textContent = isFrozen ? 'Streak Frozen' : (streakCount === 0) ? 'Streak Extinguished' : 'Days Streak';
            
            if (streakHeroIcon) {
                let iconSrc = `${baseUrl}/assets/icon_streak.png`;
                if (isFrozen) iconSrc = `${baseUrl}/assets/icon_streak_freeze.png`;
                else if (streakCount === 0) iconSrc = `${baseUrl}/assets/icon_streak_off.png`;
                streakHeroIcon.src = iconSrc;
            }

            if (isFrozen) {
                streakRestoreWarning.style.display = 'block';
            } else {
                streakRestoreWarning.style.display = 'none';
            }
        }

        // Qada list
        const qadaListContainer = document.getElementById('qadaListContainer');
        const qadaProgress = document.getElementById('qadaProgress');
        if (qadaListContainer) {
            const completedCount = qadaList.filter(q => q.is_completed).length;
            if (qadaProgress) {
                qadaProgress.textContent = `${completedCount}/${qadaList.length}`;
            }

            if (qadaList.length === 0) {
                qadaListContainer.innerHTML = `
                    <div class="qada-empty-state">
                        <div class="qada-empty-icon">✓</div>
                        <div class="qada-empty-title">All caught up!</div>
                        <div style="font-size: 0.8rem;">Tidak ada hutang sholat Qada untuk hari ini.</div>
                    </div>`;
            } else {
                qadaListContainer.innerHTML = qadaList.map(q => `
                    <div class="qada-item-card">
                        <div class="qada-item-left">
                            <div class="qada-item-icon-circle ${q.is_completed ? 'done' : 'pending'}">
                                ${q.is_completed ? '✓' : '!'}
                            </div>
                            <div class="qada-item-info">
                                <span class="qada-item-name">${q.prayer_name}</span>
                                <span class="qada-item-sub">
                                    ${q.is_completed ? 'Goal Refilled' : `Restores streak from ${q.date_missed}`}
                                </span>
                            </div>
                        </div>
                        ${q.is_completed ? 
                            `<span style="color: #166534; font-weight: bold; font-size: 0.85rem;">Lunas</span>` : 
                            `<button class="btn-qada-restore" data-uuid="${q.uuid}">Qada Now</button>`
                        }
                    </div>`).join('');
                
                // Add event listeners to restore buttons
                qadaListContainer.querySelectorAll('.btn-qada-restore').forEach(btn => {
                    btn.addEventListener('click', function() {
                        const uuid = this.getAttribute('data-uuid');
                        handleQadaRestore(uuid);
                    });
                });
            }
        }

        // Populate Dashboard Prayer Tracker Pill
        const trackerPill = document.getElementById('prayerTrackerPill');
        if (trackerPill) {
            const list = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
            trackerPill.innerHTML = list.map(label => {
                const isCompleted = prayerStates[label];
                const reached = isPrayerTimeReached(label);
                const missed = isPrayerMissed(label);
                
                let iconSrc = `${baseUrl}/assets/icon_clock.png`;
                if (isCompleted) iconSrc = `${baseUrl}/assets/icon_check.png`;
                else if (missed) iconSrc = `${baseUrl}/assets/icon_x.png`;

                return `
                    <div class="web-indicator-item ${(!reached && !missed) ? 'disabled' : ''}" data-prayer="${label}">
                        <div class="web-indicator-circle ${isCompleted ? 'completed' : 'pending'}">
                            <img src="${iconSrc}" class="web-indicator-icon" alt="${label}">
                        </div>
                        <span class="web-indicator-label">${label}</span>
                    </div>`;
            }).join('');

            // Click listener for tracking
            trackerPill.querySelectorAll('.web-indicator-item').forEach(el => {
                el.addEventListener('click', function() {
                    const label = this.getAttribute('data-prayer');
                    const reached = isPrayerTimeReached(label);
                    const isCompleted = prayerStates[label];
                    const missed = isPrayerMissed(label);
                    
                    if (!reached) {
                        alert(`Belum masuk waktu ${label}.`);
                    } else if (isCompleted) {
                        alert('Sholat sudah selesai, tidak bisa dibatalkan.');
                    } else if (missed) {
                        alert(`Waktu sholat ${label} sudah terlewat (silang merah). Silakan lunasi hutang sholat ini melalui menu Qada di bawah.`);
                    } else {
                        handleTogglePrayer(label);
                    }
                });
            });
        }
    }

    // ----------------------------------------------------
    // 5. Actions / Handlers
    // ----------------------------------------------------
    async function handleTogglePrayer(label) {
        if (prayerStates[label] === true) return;
        prayerStates[label] = true;
        const todayStr = new Date().toISOString().split('T')[0];
        
        const existing = historyList.find(h => h.date === todayStr);
        if (existing) {
            historyList = historyList.map(h => h.date === todayStr ? { ...h, [label]: true } : h);
        } else {
            const newRecord = { date: todayStr, Fajr: false, Dzuhur: false, Ashar: false, Maghrib: false, Isha: false };
            newRecord[label] = true;
            historyList.unshift(newRecord);
        }
        localStorage.setItem('history_list', JSON.stringify(historyList));

        // Check if all Qada are completed to unfreeze
        const pendingQadaCount = qadaList.filter(q => !q.is_completed).length;
        if (pendingQadaCount === 0 && isFrozen) {
            isFrozen = false;
            localStorage.setItem('streak_is_frozen', 'false');
        }

        updateWidgetsUI();
        await performSync();
    }

    async function handleQadaRestore(uuid) {
        const qadaItem = qadaList.find(q => q.uuid === uuid);
        const prayerName = qadaItem ? qadaItem.prayer_name : null;

        const updatedList = qadaList.map(q => {
            if (q.uuid === uuid) {
                return { ...q, is_completed: true };
            }
            return q;
        });
        qadaList = updatedList;
        localStorage.setItem('qada_list', JSON.stringify(qadaList));

        if (prayerName) {
            prayerStates[prayerName] = true;
            const todayStr = new Date().toISOString().split('T')[0];
            const existing = historyList.find(h => h.date === todayStr);
            if (existing) {
                historyList = historyList.map(h => h.date === todayStr ? { ...h, [prayerName]: true } : h);
            } else {
                const newRecord = { date: todayStr, Fajr: false, Dzuhur: false, Ashar: false, Maghrib: false, Isha: false };
                newRecord[prayerName] = true;
                historyList.unshift(newRecord);
            }
            localStorage.setItem('history_list', JSON.stringify(historyList));
        }

        // Check if all Qada are completed to unfreeze
        const pendingQadaCount = updatedList.filter(q => !q.is_completed).length;
        if (pendingQadaCount === 0 && isFrozen) {
            isFrozen = false;
            localStorage.setItem('streak_is_frozen', 'false');
        }

        updateWidgetsUI();
        await performSync(updatedList);
    }

    // ----------------------------------------------------
    // 6. Real-time Clock Ticker & Highlights
    // ----------------------------------------------------
    function runTicker() {
        // Run missed check and day change check
        checkRealTimeLogic();

        const nextPrayer = getNextPrayer();
        const activePrayer = getActivePrayer();
        const nextPrayerTime = timings[nextPrayer];

        // 1. Update countdown card elements
        const iconEl = document.getElementById('prayerCardIcon');
        const nameEl = document.getElementById('prayerCardName');
        const timeEl = document.getElementById('prayerCardTime');
        const nextLabelEl = document.getElementById('prayerCardNextLabel');
        const countdownEl = document.getElementById('prayerCardCountdown');

        if (iconEl) iconEl.textContent = getPrayerIcon(nextPrayer);
        if (nameEl) nameEl.textContent = nextPrayer;
        if (timeEl) timeEl.textContent = nextPrayerTime;
        if (nextLabelEl) nextLabelEl.textContent = nextPrayer;
        if (countdownEl) countdownEl.textContent = getCountdown(nextPrayer);

        // 2. Update Gregorian Date Text
        const dateEl = document.getElementById('currentGregorianDate');
        if (dateEl) {
            dateEl.textContent = new Date().toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' });
        }

        // 3. Highlight active row in Jadwal Sholat tab
        const list = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
        list.forEach(name => {
            const row = document.getElementById(`row-${name}`);
            if (row) {
                const isActive = (activePrayer === name);
                const activeLabel = row.querySelector('.active-label');
                
                if (isActive) {
                    row.className = 'qada-item-card active-highlight';
                    row.style.backgroundColor = 'hsl(var(--primary))';
                    row.style.color = 'white';
                    
                    const iconBox = row.querySelector('.qada-item-icon-circle');
                    if (iconBox) {
                        iconBox.style.backgroundColor = 'rgba(255,255,255,0.15)';
                        iconBox.style.color = 'hsl(var(--gold))';
                    }
                    if (activeLabel) activeLabel.style.display = 'block';
                } else {
                    row.className = 'qada-item-card';
                    row.style.backgroundColor = 'white';
                    row.style.color = 'inherit';
                    row.style.borderColor = 'rgba(0,0,0,0.04)';
                    
                    const iconBox = row.querySelector('.qada-item-icon-circle');
                    if (iconBox) {
                        iconBox.style.backgroundColor = '#F5E9DA';
                        iconBox.style.color = 'hsl(var(--primary))';
                    }
                    if (activeLabel) activeLabel.style.display = 'none';
                }
            }
        });
    }

    // ----------------------------------------------------
    // 7. Tab View Coordinators & Dynamic Sub-Views
    // ----------------------------------------------------
    function setupDashboardSubToggles() {
        const btnShowStreak = document.getElementById('btnShowStreak');
        const btnBackToDashboard = document.getElementById('btnBackToDashboard');
        const dashboardMainView = document.getElementById('dashboardMainView');
        const streakDetailView = document.getElementById('streakDetailView');

        if (btnShowStreak && btnBackToDashboard && dashboardMainView && streakDetailView) {
            btnShowStreak.addEventListener('click', function() {
                dashboardMainView.style.display = 'none';
                streakDetailView.style.display = 'block';
            });
            btnBackToDashboard.addEventListener('click', function() {
                streakDetailView.style.display = 'none';
                dashboardMainView.style.display = 'block';
            });
        }
    }

    // ----------------------------------------------------
    // 8. Prayer Tab Controls (Mute, Modals)
    // ----------------------------------------------------
    function setupPrayerTabControls() {
        const btnToggleMute = document.getElementById('btnToggleMute');
        const muteStatusIcon = document.getElementById('muteStatusIcon');
        const labelAdzan = document.getElementById('labelSelectedAdzan');
        const labelCity = document.getElementById('labelSelectedCity');

        // Initial settings
        if (muteStatusIcon) {
            muteStatusIcon.textContent = isAdzanMuted ? '🔕' : '🔔';
        }
        if (labelAdzan) {
            labelAdzan.textContent = adzanOptions[selectedAdzan] || 'Adzan Bilal';
        }
        if (labelCity) {
            labelCity.textContent = selectedCity;
        }

        if (btnToggleMute) {
            btnToggleMute.addEventListener('click', function() {
                isAdzanMuted = !isAdzanMuted;
                localStorage.setItem('is_adzan_muted', isAdzanMuted.toString());
                if (muteStatusIcon) {
                    muteStatusIcon.textContent = isAdzanMuted ? '🔕' : '🔔';
                }
            });
        }

        // Location selection modal triggers
        const locationPickerTrigger = document.getElementById('locationPickerTrigger');
        const locationModal = document.getElementById('locationModal');
        const locationModalList = document.getElementById('locationModalList');
        const btnCancelLocation = document.getElementById('btnCancelLocation');

        if (locationPickerTrigger && locationModal && locationModalList) {
            locationPickerTrigger.addEventListener('click', function() {
                // Populate location picker list
                locationModalList.innerHTML = Object.keys(cityOptions).map(city => `
                    <div class="location-item-row" data-city="${city}" style="padding: 0.65rem 0.85rem; border-radius: 10px; cursor: pointer; background-color: ${selectedCity === city ? 'hsl(var(--primary-light))' : 'transparent'}; display: flex; justify-content: space-between; align-items: center; transition: var(--transition);">
                        <div>
                            <div style="font-weight: bold; font-size: 0.9rem; color: hsl(var(--primary));">${city}</div>
                            <div style="font-size: 0.75rem; color: #64748b;">${cityOptions[city]}</div>
                        </div>
                        ${selectedCity === city ? `<span style="color: hsl(var(--primary)); font-weight: bold;">✓</span>` : ''}
                    </div>`).join('');

                locationModal.style.display = 'flex';

                // Add item listeners
                locationModalList.querySelectorAll('.location-item-row').forEach(row => {
                    row.addEventListener('click', async function() {
                        const newCity = this.getAttribute('data-city');
                        selectedCity = newCity;
                        localStorage.setItem('selected_city', newCity);
                        if (labelCity) labelCity.textContent = newCity;
                        locationModal.style.display = 'none';
                        await fetchPrayerTimings(newCity);
                    });
                });
            });
        }
        if (btnCancelLocation && locationModal) {
            btnCancelLocation.addEventListener('click', function() {
                locationModal.style.display = 'none';
            });
        }

        // Adzan selection modal triggers
        const alarmPickerTrigger = document.getElementById('alarmPickerTrigger');
        const adzanModal = document.getElementById('adzanModal');
        const adzanModalList = document.getElementById('adzanModalList');
        const btnCancelAdzan = document.getElementById('btnCancelAdzan');

        if (alarmPickerTrigger && adzanModal && adzanModalList) {
            alarmPickerTrigger.addEventListener('click', function() {
                // Populate adzan options
                adzanModalList.innerHTML = Object.entries(adzanOptions).map(([key, lbl]) => `
                    <label style="display: flex; align-items: center; gap: 0.75rem; font-size: 0.95rem; font-weight: 600; color: #334155; cursor: pointer;">
                        <input type="radio" name="adzanOption" value="${key}" ${selectedAdzan === key ? 'checked' : ''} style="width: 18px; height: 18px; accent-color: hsl(var(--primary));">
                        ${lbl}
                    </label>`).join('');

                adzanModal.style.display = 'flex';

                // Add radio change triggers
                adzanModalList.querySelectorAll('input[type="radio"]').forEach(radio => {
                    radio.addEventListener('change', function() {
                        const newAdzan = this.value;
                        selectedAdzan = newAdzan;
                        localStorage.setItem('selected_adzan', newAdzan);
                        if (labelAdzan) labelAdzan.textContent = adzanOptions[newAdzan];
                        adzanModal.style.display = 'none';
                    });
                });
            });
        }
        if (btnCancelAdzan && adzanModal) {
            btnCancelAdzan.addEventListener('click', function() {
                adzanModal.style.display = 'none';
            });
        }
    }

    // ----------------------------------------------------
    // 9. History Tab Logs & Calendar Row
    // ----------------------------------------------------
    function getWeekDays() {
        const firstDayOfWeek = new Date();
        // Shift date to Sunday of current week
        firstDayOfWeek.setDate(firstDayOfWeek.getDate() - (firstDayOfWeek.getDay() % 7));
        
        return Array.from({ length: 7 }).map((_, index) => {
            const d = new Date(firstDayOfWeek);
            d.setDate(firstDayOfWeek.getDate() + index);
            return d;
        });
    }

    function renderHistoryCalendar() {
        const container = document.getElementById('calendarRowContainer');
        if (!container) return;

        const days = getWeekDays();
        const now = new Date();

        container.innerHTML = days.map((d, index) => {
            const isSelected = d.getDate() === selectedHistoryDate.getDate() && d.getMonth() === selectedHistoryDate.getMonth();
            const isToday = d.getDate() === now.getDate() && d.getMonth() === now.getMonth();
            const dayLetter = ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.getDay()];

            return `
                <div class="calendar-day-item" data-index="${index}" style="display: flex; flex-direction: column; align-items: center; gap: 0.25rem; cursor: pointer; flex: 1;">
                    <span style="font-size: 0.75rem; font-weight: bold; color: ${isSelected ? 'hsl(var(--primary))' : '#64748b'};">
                        ${dayLetter}
                    </span>
                    <div style="width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 0.85rem; font-weight: bold; background-color: ${isSelected ? 'hsl(var(--primary))' : 'transparent'}; color: ${isSelected ? 'hsl(var(--gold))' : 'hsl(var(--primary))'}; border: ${isToday && !isSelected ? '1px solid hsl(var(--primary))' : 'none'};">
                        ${d.getDate()}
                    </div>
                </div>`;
        }).join('');

        // Calendar click listeners
        container.querySelectorAll('.calendar-day-item').forEach(el => {
            el.addEventListener('click', function() {
                const idx = parseInt(this.getAttribute('data-index'));
                selectedHistoryDate = days[idx];
                renderHistoryCalendar();
                renderHistoryList();
            });
        });
    }

    function renderHistoryList() {
        const container = document.getElementById('historyPrayerListContainer');
        const titleEl = document.getElementById('selectedDateTitle');
        if (!container) return;

        const dateStr = selectedHistoryDate.toISOString().split('T')[0];
        const record = historyList.find(h => h.date === dateStr);
        const now = new Date();
        const isPastDay = selectedHistoryDate < new Date(now.setHours(0,0,0,0));
        const isToday = selectedHistoryDate.getDate() === new Date().getDate() && selectedHistoryDate.getMonth() === new Date().getMonth();

        if (titleEl) {
            titleEl.textContent = `Status Shalat: ${selectedHistoryDate.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'short' })}`;
        }

        if (!record && !isToday) {
            container.innerHTML = `
                <div class="qada-empty-state" style="padding: 3rem;">
                    <span style="font-size: 2.5rem; opacity: 0.3;">📅</span>
                    <div class="qada-empty-title" style="margin-top: 0.5rem;">Tidak ada riwayat shalat untuk hari ini</div>
                </div>`;
            return;
        }

        const prayers = ['Fajr', 'Dzuhur', 'Ashar', 'Maghrib', 'Isha'];
        container.innerHTML = prayers.map(name => {
            const isDone = record ? record[name] : false;
            const hasMissed = isPastDay && !isDone;
            
            let statusText = 'Pending';
            let statusIcon = '🕒';
            
            if (isDone) {
                statusText = 'Completed';
                statusIcon = '✓';
            } else if (hasMissed) {
                statusText = 'Missed';
                statusIcon = '✗';
            }

            let iconColor = isDone ? 'hsl(var(--gold))' : (hasMissed ? '#ef4444' : '#64748b');
            let iconBg = isDone ? 'hsl(var(--primary))' : (hasMissed ? 'rgba(239, 68, 68, 0.1)' : 'rgba(148, 163, 184, 0.1)');

            return `
                <div class="qada-item-card">
                    <div class="qada-item-left">
                        <div class="qada-item-icon-circle" style="background-color: ${iconBg}; color: ${iconColor};">
                            ${statusIcon}
                        </div>
                        <span class="qada-item-name">${name}</span>
                    </div>
                    <span style="font-weight: bold; font-size: 0.85rem; color: ${iconColor};">
                        ${statusText}
                    </span>
                </div>`;
        }).join('');
    }

    // ----------------------------------------------------
    // 10. Profile Settings accordion & Photo Uploader
    // ----------------------------------------------------
    function setupProfileTabControls() {
        // Avatar Photo Uploader
        const btnChangeAvatar = document.getElementById('btnChangeAvatar');
        const fileInput = document.getElementById('profileAvatarFile');

        if (btnChangeAvatar && fileInput) {
            btnChangeAvatar.addEventListener('click', () => fileInput.click());
            
            fileInput.addEventListener('change', function(e) {
                const file = e.target.files[0];
                const alertContainer = document.getElementById('profileAlertContainer');

                if (file) {
                    if (file.size > 2 * 1024 * 1024) {
                        alert(`Ukuran file terlalu besar. Maksimal 2MB.`);
                        return;
                    }
                    const reader = new FileReader();
                    reader.onload = function(event) {
                        const base64Url = event.target.result;
                        localStorage.setItem(`profile_pic_${username}`, base64Url);
                        
                        initializeUserAvatars();
                        alert(`Foto profil berhasil diperbarui.`);
                    };
                    reader.readAsDataURL(file);
                }
            });
        }

        // Ubah Kredensial Accordion
        const btnToggleCredentials = document.getElementById('btnToggleCredentials');
        const credentialsFormContent = document.getElementById('credentialsFormContent');
        const accordionArrow = document.getElementById('accordionArrow');

        if (btnToggleCredentials && credentialsFormContent && accordionArrow) {
            btnToggleCredentials.addEventListener('click', function() {
                const isOpen = (credentialsFormContent.style.display === 'block');
                if (isOpen) {
                    credentialsFormContent.style.display = 'none';
                    accordionArrow.style.transform = 'none';
                } else {
                    credentialsFormContent.style.display = 'block';
                    accordionArrow.style.transform = 'rotate(90deg)';
                }
            });
        }

        // Credentials Update AJAX Form Submission
        const updateForm = document.getElementById('updateCredentialsForm');
        if (updateForm) {
            updateForm.addEventListener('submit', async function(e) {
                e.preventDefault();
                const newUsername = document.getElementById('new_username').value.trim();
                const newPassword = document.getElementById('new_password').value;
                const confirmPassword = document.getElementById('confirm_password').value;
                const alertContainer = document.getElementById('profileAlertContainer');

                if (alertContainer) alertContainer.innerHTML = '';

                if (newPassword && newPassword !== confirmPassword) {
                    if (alertContainer) {
                        alertContainer.innerHTML = `<div class="error-banner">Konfirmasi password tidak cocok.</div>`;
                    }
                    return;
                }

                const payload = {};
                if (newUsername && newUsername !== username) {
                    payload.username = newUsername;
                }
                if (newPassword) {
                    payload.password = newPassword;
                }

                if (Object.keys(payload).length === 0) {
                    if (alertContainer) {
                        alertContainer.innerHTML = `<div class="success-banner" style="background-color: #dcfce7; border: 1px solid #bbf7d0; color: #166534; padding: 0.85rem 1rem; border-radius: 12px; font-weight: 600;">Tidak ada perubahan data.</div>`;
                    }
                    return;
                }

                try {
                    const response = await fetch(`${apiBaseUrl}/auth/update`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${token}`
                        },
                        body: JSON.stringify(payload)
                    });

                    const data = await response.json();
                    if (response.ok) {
                        if (payload.username) {
                            const oldPic = localStorage.getItem(`profile_pic_${username}`);
                            if (oldPic) {
                                localStorage.setItem(`profile_pic_${payload.username}`, oldPic);
                                localStorage.removeItem(`profile_pic_${username}`);
                            }
                            localStorage.setItem('username', payload.username);
                            
                            // Synchronize immediately via refreshing page to let CodeIgniter update its backend session
                            if (alertContainer) {
                                alertContainer.innerHTML = `<div class="success-banner" style="background-color: #dcfce7; border: 1px solid #bbf7d0; color: #166534; padding: 0.85rem 1rem; border-radius: 12px; font-weight: 600;">Username berhasil diubah. Menghubungkan ulang...</div>`;
                            }
                            
                            // Hit a session update endpoint if needed, or simply log out/reload to keep sessions completely in sync
                            setTimeout(() => {
                                window.location.href = `${baseUrl}/logout`;
                            }, 1200);
                        } else {
                            if (alertContainer) {
                                alertContainer.innerHTML = `<div class="success-banner" style="background-color: #dcfce7; border: 1px solid #bbf7d0; color: #166534; padding: 0.85rem 1rem; border-radius: 12px; font-weight: 600;">Password berhasil diperbarui.</div>`;
                            }
                            document.getElementById('new_password').value = '';
                            document.getElementById('confirm_password').value = '';
                        }
                    } else {
                        if (alertContainer) {
                            alertContainer.innerHTML = `<div class="error-banner">${data.message || 'Gagal mengubah data.'}</div>`;
                        }
                    }
                } catch (err) {
                    if (alertContainer) {
                        alertContainer.innerHTML = `<div class="error-banner">Koneksi ke backend gagal.</div>`;
                    }
                }
            });
        }

        // About modal triggers
        const btnAbout = document.getElementById('btnAboutDialog');
        const aboutModal = document.getElementById('aboutModal');
        const btnExitAbout = document.getElementById('btnExitAbout');
        if (btnAbout && aboutModal && btnExitAbout) {
            btnAbout.addEventListener('click', function() {
                aboutModal.style.display = 'flex';
            });
            btnExitAbout.addEventListener('click', function() {
                aboutModal.style.display = 'none';
            });
        }
    }

    // ----------------------------------------------------
    // 11. Mobile Drawer Navigation Hamburger
    // ----------------------------------------------------
    function setupHamburgerDrawer() {
        const hamburgerBtn = document.getElementById('hamburgerBtn');
        const sidebar = document.getElementById('appSidebar');
        const backdrop = document.getElementById('sidebarBackdrop');

        if (hamburgerBtn && sidebar && backdrop) {
            hamburgerBtn.addEventListener('click', function() {
                sidebar.classList.add('open');
                backdrop.style.display = 'block';
            });

            backdrop.addEventListener('click', function() {
                sidebar.classList.remove('open');
                backdrop.style.display = 'none';
            });
        }
    }

    // ----------------------------------------------------
    // 12. Non-toxic Reactions Action Handler (AJAX proxy)
    // ------    // ----------------------------------------------------
    // 12. Non-toxic Reactions Action Handler (AJAX proxy) with Optimistic UI
    // ----------------------------------------------------
    function setupCommunityReactions() {
        const feedContainer = document.getElementById('communityFeedContainer') || document.querySelector('.view-post-container');
        if (!feedContainer) return;

        feedContainer.addEventListener('click', async function(e) {
            const btn = e.target.closest('.btn-reaction');
            if (!btn) return;

            const card = btn.closest('.feed-card');
            if (!card) return;

            const postId = card.getAttribute('data-post-id');
            const reactionType = btn.getAttribute('data-reaction-type');
            
            // Get current reactions counts to store for rollback
            const countEl = btn.querySelector('.count');
            if (!countEl) return;
            const originalVal = parseInt(countEl.textContent, 10) || 0;

            // Optimistic UI Update
            countEl.textContent = originalVal + 1;
            
            // Give button active style immediately
            const originalBorderColor = btn.style.borderColor;
            const originalBgColor = btn.style.backgroundColor;
            const originalColor = btn.style.color;
            btn.style.borderColor = 'hsl(var(--primary))';
            btn.style.backgroundColor = 'hsl(var(--primary-light))';
            btn.style.color = 'hsl(var(--primary))';

            try {
                const response = await fetch(`${apiBaseUrl}/posts/${postId}/react`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ reaction_type: reactionType })
                });

                if (response.ok) {
                    const data = await response.json();
                    
                    // Reset custom style & update all reaction counts dynamically from server
                    btn.style.borderColor = originalBorderColor;
                    btn.style.backgroundColor = originalBgColor;
                    btn.style.color = originalColor;

                    const inspiringBtn = card.querySelector('[data-reaction-type="inspiring"] .count');
                    const helpfulBtn = card.querySelector('[data-reaction-type="helpful"] .count');
                    const usefulBtn = card.querySelector('[data-reaction-type="useful"] .count');

                    if (inspiringBtn) inspiringBtn.textContent = data.inspiring_count;
                    if (helpfulBtn) helpfulBtn.textContent = data.helpful_count;
                    if (usefulBtn) usefulBtn.textContent = data.useful_count;
                } else {
                    throw new Error('Server returned non-ok status');
                }
            } catch (err) {
                console.error('Failed to post reaction:', err);
                // Rollback!
                countEl.textContent = originalVal;
                btn.style.borderColor = originalBorderColor;
                btn.style.backgroundColor = originalBgColor;
                btn.style.color = originalColor;
            }
        });
    }

    // ----------------------------------------------------
    // 12b. Real-time Community Stats Ticker
    // ----------------------------------------------------
    function initStatsTicker() {
        const activeMembersEl = document.getElementById('activeMembersCount');
        const trackedPrayersEl = document.getElementById('trackedPrayersCount');
        const masjidReviewsEl = document.getElementById('masjidReviewsCount');

        if (!activeMembersEl || !trackedPrayersEl || !masjidReviewsEl) return;

        let activeMembers = parseInt(activeMembersEl.getAttribute('data-base'), 10) || 1248;
        let trackedPrayers = parseInt(trackedPrayersEl.getAttribute('data-base'), 10) || 14892;
        let masjidReviews = parseInt(masjidReviewsEl.getAttribute('data-base'), 10) || 482;

        function formatNumber(num) {
            return num.toString().replace(/\B(?=(\d{3})+(?!\n))/g, ".");
        }

        function triggerPulse(el, newText) {
            el.textContent = newText;
            el.classList.remove('stats-pulsing');
            // Trigger reflow to restart CSS animation
            void el.offsetWidth;
            el.classList.add('stats-pulsing');
        }

        // Ticker for Active Members: randomly add 0-1 members every 10 seconds
        const activeInterval = setInterval(() => {
            const increment = Math.random() > 0.65 ? 1 : 0;
            if (increment > 0) {
                activeMembers += increment;
                triggerPulse(activeMembersEl, formatNumber(activeMembers));
            }
        }, 10000);

        // Ticker for Tracked Prayers: randomly add 0-3 prayers every 3 seconds
        const prayersInterval = setInterval(() => {
            const increment = Math.floor(Math.random() * 4); // 0 to 3
            if (increment > 0) {
                trackedPrayers += increment;
                triggerPulse(trackedPrayersEl, formatNumber(trackedPrayers));
            }
        }, 3000);

        // Ticker for Mosque Reviews: randomly add 0-1 reviews every 25 seconds
        const reviewsInterval = setInterval(() => {
            const increment = Math.random() > 0.85 ? 1 : 0;
            if (increment > 0) {
                masjidReviews += increment;
                triggerPulse(masjidReviewsEl, formatNumber(masjidReviews));
            }
        }, 25000);
        
        // Save interval references to window so they can be cleaned if needed (optional)
        window.statsIntervals = [activeInterval, prayersInterval, reviewsInterval];
    }

    // ----------------------------------------------------
    // 13. Comment & Reply AJAX System with Optimistic UI
    // ----------------------------------------------------
    function setupCommentSystem() {
        const commentForm = document.getElementById('ajaxCommentForm');
        if (!commentForm) return;

        commentForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            const commentTextarea = document.getElementById('commentTextarea');
            const content = commentTextarea.value.trim();
            if (!content) return;

            // Generate optimistic temporary ID and HTML element
            const tempId = 'temp-' + Date.now();
            const tempComment = {
                id: tempId,
                username: window.currentUsername || 'User',
                content: content,
                created_at: new Date().toISOString()
            };

            // Clear textarea immediately
            commentTextarea.value = '';

            const noCommentsAlert = document.getElementById('noCommentsAlert');
            let noCommentsAlertHidden = false;
            if (noCommentsAlert) {
                noCommentsAlert.style.display = 'none';
                noCommentsAlertHidden = true;
            }

            // Append new comment to DOM (optimistic)
            const container = document.getElementById('commentsListContainer');
            const commentHtml = createCommentHtml(tempComment);
            container.insertAdjacentHTML('afterbegin', commentHtml);

            const tempElement = container.querySelector(`[data-comment-id="${tempId}"]`);
            if (tempElement) {
                tempElement.style.opacity = '0.6';
            }

            // Update total count optimistically
            updateTotalCommentCount(1);

            try {
                const formData = new FormData();
                formData.append('post_id', currentPostId);
                formData.append('comment_text', content);

                const response = await fetch(`${baseUrl}/community/comment/add`, {
                    method: 'POST',
                    body: formData
                });

                if (response.ok) {
                    const data = await response.json();
                    if (data.status === 'success') {
                        // Success! Update temporary element with database ID and correct links
                        if (tempElement) {
                            tempElement.style.opacity = '1';
                            tempElement.setAttribute('data-comment-id', data.comment.id);
                            
                            // Re-bind delete button
                            const deleteBtn = tempElement.querySelector('.btn-comment-delete');
                            if (deleteBtn) {
                                deleteBtn.setAttribute('onclick', `handleDeleteComment(${data.comment.id})`);
                            }
                            
                            // Re-bind inline reply box elements
                            const replyBox = tempElement.querySelector('[id^="replyBox-"]');
                            if (replyBox) {
                                replyBox.id = `replyBox-${data.comment.id}`;
                            }
                            const replyForm = tempElement.querySelector('form');
                            if (replyForm) {
                                replyForm.setAttribute('onsubmit', `handleSendReply(event, ${data.comment.id})`);
                            }
                            const toggleBtn = tempElement.querySelector('.btn-reply-trigger');
                            if (toggleBtn) {
                                toggleBtn.setAttribute('onclick', `toggleReplyBox(${data.comment.id})`);
                            }
                            const replyBoxCancelBtn = tempElement.querySelector('.btn-danger');
                            if (replyBoxCancelBtn) {
                                replyBoxCancelBtn.setAttribute('onclick', `toggleReplyBox(${data.comment.id})`);
                            }
                            const repliesContainer = tempElement.querySelector('.comment-replies-list');
                            if (repliesContainer) {
                                repliesContainer.id = `repliesContainer-${data.comment.id}`;
                            }
                        }
                        if (noCommentsAlert && noCommentsAlertHidden) {
                            noCommentsAlert.remove();
                        }
                    } else {
                        throw new Error(data.message || 'Gagal menambahkan komentar');
                    }
                } else {
                    throw new Error('HTTP Status Error');
                }
            } catch (err) {
                console.error('Error adding comment:', err);
                alert(err.message || 'Gagal menambahkan komentar. Silakan coba lagi.');
                
                // Rollback!
                if (tempElement) {
                    tempElement.remove();
                }
                updateTotalCommentCount(-1);
                commentTextarea.value = content;
                if (noCommentsAlert && noCommentsAlertHidden) {
                    noCommentsAlert.style.display = 'block';
                }
            }
        });
    }

    window.moveCarousel = function(event, direction) {
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
        
        const btn = event.currentTarget;
        const container = btn.closest('.post-carousel-container');
        if (!container) return;

        const slides = container.querySelector('.post-carousel-slides');
        if (!slides) return;

        const slideWidth = slides.getBoundingClientRect().width || slides.clientWidth;
        if (slideWidth === 0) return;
        
        const currentScroll = slides.scrollLeft;
        const currentIndex = Math.round(currentScroll / slideWidth);
        const targetIndex = Math.max(0, Math.min(slides.children.length - 1, currentIndex + direction));

        slides.scrollTo({
            left: targetIndex * slideWidth,
            behavior: 'smooth'
        });

        const dots = container.querySelectorAll('.carousel-dot');
        dots.forEach((dot, index) => {
            if (index === targetIndex) {
                dot.classList.add('active');
            } else {
                dot.classList.remove('active');
            }
        });
    };

    // Expose helpers to window for inline onclick attributes
    window.toggleReplyBox = function(commentId) {
        const replyBox = document.getElementById(`replyBox-${commentId}`);
        if (replyBox) {
            replyBox.style.display = replyBox.style.display === 'none' ? 'block' : 'none';
            if (replyBox.style.display === 'block') {
                const input = replyBox.querySelector('.reply-input-field');
                if (input) input.focus();
            }
        }
    };

    window.handleSendReply = async function(e, commentId) {
        e.preventDefault();
        const replyBox = document.getElementById(`replyBox-${commentId}`);
        if (!replyBox) return;

        const input = replyBox.querySelector('.reply-input-field');
        const content = input.value.trim();
        if (!content) return;

        // Generate optimistic temporary ID and elements
        const tempId = 'temp-' + Date.now();
        const tempReply = {
            id: tempId,
            comment_id: commentId,
            username: window.currentUsername || 'User',
            content: content,
            created_at: new Date().toISOString()
        };

        // Reset input and hide reply box optimistically
        input.value = '';
        replyBox.style.display = 'none';

        // Append reply to container optimistically
        const repliesContainer = document.getElementById(`repliesContainer-${commentId}`);
        if (!repliesContainer) return;
        const replyHtml = createReplyHtml(tempReply, commentId);
        repliesContainer.insertAdjacentHTML('beforeend', replyHtml);

        const tempElement = repliesContainer.querySelector(`[data-reply-id="${tempId}"]`);
        if (tempElement) {
            tempElement.style.opacity = '0.6';
        }

        // Update total count optimistically
        updateTotalCommentCount(1);

        try {
            const formData = new FormData();
            formData.append('comment_id', commentId);
            formData.append('reply_text', content);

            const response = await fetch(`${baseUrl}/community/reply/add`, {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                const data = await response.json();
                if (data.status === 'success') {
                    // Success! Update temp element with real database ID
                    if (tempElement) {
                        tempElement.style.opacity = '1';
                        tempElement.setAttribute('data-reply-id', data.reply.id);
                        
                        // Re-bind delete reply button
                        const deleteBtn = tempElement.querySelector('.btn-comment-delete');
                        if (deleteBtn) {
                            deleteBtn.setAttribute('onclick', `handleDeleteReply(${data.reply.id}, ${commentId})`);
                        }
                    }
                } else {
                    throw new Error(data.message || 'Gagal mengirim balasan');
                }
            } else {
                throw new Error('HTTP Status Error');
            }
        } catch (err) {
            console.error('Error adding reply:', err);
            alert(err.message || 'Gagal mengirim balasan. Silakan coba lagi.');

            // Rollback!
            if (tempElement) {
                tempElement.remove();
            }
            updateTotalCommentCount(-1);
            replyBox.style.display = 'block';
            input.value = content;
            input.focus();
        }
    };

    window.handleDeleteComment = async function(commentId) {
        if (!confirm('Apakah Anda yakin ingin menghapus komentar ini beserta seluruh balasannya?')) return;

        const commentEl = document.querySelector(`[data-comment-id="${commentId}"]`);
        if (!commentEl) return;

        // Optimistic UI hide & count decrement
        const repliesCount = commentEl.querySelectorAll('.reply-item-card').length;
        const totalDecremented = 1 + repliesCount;

        const originalDisplay = commentEl.style.display;
        commentEl.style.display = 'none';
        updateTotalCommentCount(-totalDecremented);

        try {
            const formData = new FormData();
            formData.append('comment_id', commentId);

            const response = await fetch(`${baseUrl}/community/comment/delete`, {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                const data = await response.json();
                if (data.status === 'success') {
                    // Success: permanently remove
                    commentEl.remove();

                    // If list is empty, show empty state
                    const container = document.getElementById('commentsListContainer');
                    if (container && container.children.length === 0) {
                        container.innerHTML = `
                            <div id="noCommentsAlert" style="text-align: center; color: #64748b; padding: 2rem; font-style: italic;">
                                Belum ada komentar. Mari mulai diskusinya!
                            </div>
                        `;
                    }
                } else {
                    throw new Error(data.message || 'Gagal menghapus komentar');
                }
            } else {
                throw new Error('HTTP Status Error');
            }
        } catch (err) {
            console.error('Error deleting comment:', err);
            alert(err.message || 'Gagal menghapus komentar. Silakan coba lagi.');

            // Rollback!
            commentEl.style.display = originalDisplay;
            updateTotalCommentCount(totalDecremented);
        }
    };

    window.handleDeleteReply = async function(replyId, commentId) {
        if (!confirm('Apakah Anda yakin ingin menghapus balasan ini?')) return;

        const replyEl = document.querySelector(`[data-reply-id="${replyId}"]`);
        if (!replyEl) return;

        const originalDisplay = replyEl.style.display;
        replyEl.style.display = 'none';
        updateTotalCommentCount(-1);

        try {
            const formData = new FormData();
            formData.append('reply_id', replyId);

            const response = await fetch(`${baseUrl}/community/reply/delete`, {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                const data = await response.json();
                if (data.status === 'success') {
                    // Success: permanently remove
                    replyEl.remove();
                } else {
                    throw new Error(data.message || 'Gagal menghapus balasan');
                }
            } else {
                throw new Error('HTTP Status Error');
            }
        } catch (err) {
            console.error('Error deleting reply:', err);
            alert(err.message || 'Gagal menghapus balasan. Silakan coba lagi.');

            // Rollback!
            replyEl.style.display = originalDisplay;
            updateTotalCommentCount(1);
        }
    };

    // Helper functions for template construction
    function createCommentHtml(comment) {
        const formattedDate = 'Baru saja';
        const avatarLetter = comment.username.substring(0, 1).toUpperCase();
        
        const isAuthor = comment.username === window.currentPostAuthor;
        const authorBadge = isAuthor ? '<span class="author-badge">Author</span>' : '';
        
        // Show delete button only if it's the current logged in user
        const showDeleteBtn = comment.username === window.currentUsername;
        const deleteBtnHtml = showDeleteBtn 
            ? `<button class="btn-comment-delete" onclick="handleDeleteComment(${comment.id})">Hapus</button>`
            : '';
        
        return `
            <div class="comment-item-card" data-comment-id="${comment.id}" style="margin-bottom: 1.5rem; padding-bottom: 1.5rem; border-bottom: 1px solid #f1f5f9; animation: slideIn 0.3s ease-out;">
                <div style="display: flex; justify-content: space-between; align-items: start;">
                    <div style="display: flex; gap: 0.75rem; align-items: center; margin-bottom: 0.5rem;">
                        <div class="comment-avatar-fallback">
                            ${avatarLetter}
                        </div>
                        <div>
                            <span style="font-weight: 700; font-size: 0.85rem; color: #1e293b;">${comment.username}</span>
                            ${authorBadge}
                            <span style="font-size: 0.75rem; color: #64748b; margin-left: 0.25rem;">
                                · ${formattedDate}
                            </span>
                        </div>
                    </div>
                    ${deleteBtnHtml}
                </div>

                <p class="comment-text-body" style="font-size: 0.9rem; color: #334155; margin-left: 2.25rem; margin-top: 0.25rem; margin-bottom: 0.5rem; line-height: 1.5;">
                    ${escapeHtml(comment.content)}
                </p>

                <div style="margin-left: 2.25rem; margin-bottom: 0.75rem;">
                    <button class="btn-reply-trigger" onclick="toggleReplyBox(${comment.id})">
                        ↩ Balas
                    </button>
                </div>

                <div id="replyBox-${comment.id}" style="display: none; margin-left: 2.25rem; margin-bottom: 1rem; margin-top: 0.5rem;">
                    <form onsubmit="handleSendReply(event, ${comment.id})" style="display: flex; gap: 0.5rem; align-items: start;">
                        <input 
                            type="text" 
                            class="form-input reply-input-field" 
                            style="padding: 0.5rem; font-size: 0.85rem; border-radius: 6px;" 
                            placeholder="Tulis balasan..." 
                            required
                        />
                        <button type="submit" class="btn-primary" style="padding: 0.5rem 1rem; font-size: 0.8rem; border-radius: 6px; width: auto;">Kirim</button>
                        <button type="button" class="btn-danger" onclick="toggleReplyBox(${comment.id})" style="padding: 0.5rem 1rem; font-size: 0.8rem; border-radius: 6px; width: auto;">Batal</button>
                    </form>
                </div>

                <div class="comment-replies-list" id="repliesContainer-${comment.id}" style="margin-left: 2.25rem; border-left: 2px solid #f1f5f9; padding-left: 1rem; display: flex; flex-direction: column; gap: 1rem; margin-top: 0.5rem;">
                </div>
            </div>
        `;
    }

    function createReplyHtml(reply, commentId) {
        const formattedDate = 'Baru saja';
        const avatarLetter = reply.username.substring(0, 1).toUpperCase();

        const isAuthor = reply.username === window.currentPostAuthor;
        const authorBadge = isAuthor ? '<span class="author-badge replies-badge">Author</span>' : '';

        // Show delete button only if it's the current logged in user
        const showDeleteBtn = reply.username === window.currentUsername;
        const deleteBtnHtml = showDeleteBtn 
            ? `<button class="btn-comment-delete" onclick="handleDeleteReply(${reply.id}, ${commentId})" style="font-size: 0.7rem;">Hapus</button>`
            : '';

        return `
            <div class="reply-item-card" data-reply-id="${reply.id}" style="animation: slideIn 0.3s ease-out;">
                <div style="display: flex; justify-content: space-between; align-items: start;">
                    <div style="display: flex; gap: 0.5rem; align-items: center; margin-bottom: 0.25rem;">
                        <div class="reply-avatar-fallback">
                            ${avatarLetter}
                        </div>
                        <div>
                            <span style="font-weight: 700; font-size: 0.8rem; color: #1e293b;">${reply.username}</span>
                            ${authorBadge}
                            <span style="font-size: 0.7rem; color: #64748b; margin-left: 0.25rem;">
                                · ${formattedDate}
                            </span>
                        </div>
                    </div>
                    ${deleteBtnHtml}
                </div>
                <p class="reply-text-body" style="font-size: 0.85rem; color: #475569; margin-left: 1.75rem; margin-top: 0.15rem; line-height: 1.4;">
                    ${escapeHtml(reply.content)}
                </p>
            </div>
        `;
    }

    function updateTotalCommentCount(change) {
        const el = document.getElementById('totalCommentCount');
        if (el) {
            const currentCount = parseInt(el.textContent, 10) || 0;
            el.textContent = Math.max(0, currentCount + change);
        }
    }

    function escapeHtml(text) {
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function setupCarousels() {
        document.querySelectorAll('.post-carousel-slides').forEach(slides => {
            slides.addEventListener('scroll', function() {
                const container = this.closest('.post-carousel-container');
                if (!container) return;
                const slideWidth = this.clientWidth;
                if (slideWidth === 0) return;
                const activeIndex = Math.round(this.scrollLeft / slideWidth);
                const dots = container.querySelectorAll('.carousel-dot');
                dots.forEach((dot, index) => {
                    if (index === activeIndex) {
                        dot.classList.add('active');
                    } else {
                        dot.classList.remove('active');
                    }
                });
            });
        });
    }

    // ----------------------------------------------------
    // 14. Initialization Bootstrapping
    // ----------------------------------------------------
    document.addEventListener("DOMContentLoaded", async function() {
        // Initial setup
        initializeUserAvatars();
        setupHamburgerDrawer();
        setupCarousels();

        // Fetch dynamic prayer timings on page load
        await fetchPrayerTimings(selectedCity);

        if (token) {
            performSync();
        }

        // Tab specific setups
        if (activeTab === 'dashboard') {
            setupDashboardSubToggles();
            updateWidgetsUI();
            
            // Run ticker immediately and check active sholat times
            runTicker();
            setInterval(runTicker, 1000);
        } else if (activeTab === 'schedule') {
            setupPrayerTabControls();
            runTicker();
            setInterval(runTicker, 1000);
        } else if (activeTab === 'history') {
            renderHistoryCalendar();
            renderHistoryList();
        } else if (activeTab === 'profile') {
            setupProfileTabControls();
        } else if (activeTab === 'community') {
            setupCommunityReactions();
            setupCommentSystem();
            initStatsTicker();
        }
    });

})();
