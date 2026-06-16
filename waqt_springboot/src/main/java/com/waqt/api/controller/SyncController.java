package com.waqt.api.controller;

import com.waqt.api.entity.*;
import com.waqt.api.repository.UserHistoryRepository;
import com.waqt.api.repository.UserQadaRepository;
import com.waqt.api.repository.UserStreakRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
public class SyncController {

    @Autowired
    private UserStreakRepository streakRepository;

    @Autowired
    private UserHistoryRepository historyRepository;

    @Autowired
    private UserQadaRepository qadaRepository;

    private boolean getBooleanSafely(Map<String, Object> map, String key) {
        Object value = map.get(key);
        if (value instanceof Boolean) {
            return (Boolean) value;
        } else if (value instanceof Number) {
            return ((Number) value).intValue() != 0;
        }
        return false;
    }

    @PostMapping("/sync")
    @Transactional
    public ResponseEntity<Map<String, Object>> sync(
            @RequestHeader(value = "X-User-ID", required = false) String userIdHeader,
            @RequestBody Map<String, Object> requestBody) {

        if (userIdHeader == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }

        Long userId = Long.parseLong(userIdHeader);

        // 1. Merge Streak
        if (requestBody.containsKey("streak")) {
            Map<String, Object> streakMap = (Map<String, Object>) requestBody.get("streak");
            if (streakMap != null) {
                int count = ((Number) streakMap.getOrDefault("count", 0)).intValue();
                boolean isFrozen = getBooleanSafely(streakMap, "is_frozen");
                String lastUpdatedDate = (String) streakMap.getOrDefault("last_updated_date", "");

                UserStreak streak = UserStreak.builder()
                        .userId(userId)
                        .count(count)
                        .isFrozen(isFrozen)
                        .lastUpdatedDate(lastUpdatedDate)
                        .build();

                streakRepository.save(streak);
            }
        }

        // 2. Merge History (Logical OR)
        if (requestBody.containsKey("history")) {
            List<Map<String, Object>> historyList = (List<Map<String, Object>>) requestBody.get("history");
            if (historyList != null) {
                for (Map<String, Object> h : historyList) {
                    String date = (String) h.get("date");
                    if (date == null) continue;

                    boolean fajrDone = getBooleanSafely(h, "fajr_done");
                    boolean dzuhurDone = getBooleanSafely(h, "dzuhur_done");
                    boolean asharDone = getBooleanSafely(h, "ashar_done");
                    boolean maghribDone = getBooleanSafely(h, "maghrib_done");
                    boolean ishaDone = getBooleanSafely(h, "isha_done");

                    Optional<UserHistory> existingOpt = historyRepository.findById(new UserHistoryId(userId, date));
                    if (existingOpt.isPresent()) {
                        UserHistory existing = existingOpt.get();
                        fajrDone = fajrDone || existing.isFajrDone();
                        dzuhurDone = dzuhurDone || existing.isDzuhurDone();
                        asharDone = asharDone || existing.isAsharDone();
                        maghribDone = maghribDone || existing.isMaghribDone();
                        ishaDone = ishaDone || existing.isIshaDone();
                    }

                    UserHistory history = UserHistory.builder()
                            .userId(userId)
                            .date(date)
                            .fajrDone(fajrDone)
                            .dzuhurDone(dzuhurDone)
                            .asharDone(asharDone)
                            .maghribDone(maghribDone)
                            .ishaDone(ishaDone)
                            .build();

                    historyRepository.save(history);
                }
            }
        }

        // 3. Merge Qada (Logical OR)
        if (requestBody.containsKey("qada")) {
            List<Map<String, Object>> qadaList = (List<Map<String, Object>>) requestBody.get("qada");
            if (qadaList != null) {
                for (Map<String, Object> q : qadaList) {
                    String uuid = (String) q.get("uuid");
                    if (uuid == null) continue;

                    String prayerName = (String) q.getOrDefault("prayer_name", "");
                    String dateMissed = (String) q.getOrDefault("date_missed", "");
                    boolean isCompleted = getBooleanSafely(q, "is_completed");

                    Optional<UserQada> existingOpt = qadaRepository.findById(uuid);
                    if (existingOpt.isPresent()) {
                        isCompleted = isCompleted || existingOpt.get().isCompleted();
                    }

                    UserQada qada = UserQada.builder()
                            .uuid(uuid)
                            .userId(userId)
                            .prayerName(prayerName)
                            .dateMissed(dateMissed)
                            .isCompleted(isCompleted)
                            .build();

                    qadaRepository.save(qada);
                }
            }
        }

        // Pull Consolidated Data
        Optional<UserStreak> dbStreakOpt = streakRepository.findById(userId);
        Map<String, Object> finalStreak = new HashMap<>();
        if (dbStreakOpt.isPresent()) {
            UserStreak dbStreak = dbStreakOpt.get();
            finalStreak.put("count", dbStreak.getCount());
            finalStreak.put("is_frozen", dbStreak.isFrozen());
            finalStreak.put("last_updated_date", dbStreak.getLastUpdatedDate());
        } else {
            finalStreak.put("count", 0);
            finalStreak.put("is_frozen", false);
            finalStreak.put("last_updated_date", "");
        }

        // Retrieve last 30 histories ordered by date DESC
        List<UserHistory> dbHistory = historyRepository.findByUserId(
                userId,
                PageRequest.of(0, 30, Sort.by("date").descending())
        );

        List<Map<String, Object>> finalHistory = new ArrayList<>();
        for (UserHistory h : dbHistory) {
            Map<String, Object> hMap = new HashMap<>();
            hMap.put("date", h.getDate());
            hMap.put("fajr_done", h.isFajrDone());
            hMap.put("dzuhur_done", h.isDzuhurDone());
            hMap.put("ashar_done", h.isAsharDone());
            hMap.put("maghrib_done", h.isMaghribDone());
            hMap.put("isha_done", h.isIshaDone());
            finalHistory.add(hMap);
        }

        // Retrieve all Qadas
        List<UserQada> dbQada = qadaRepository.findByUserId(userId);
        List<Map<String, Object>> finalQada = new ArrayList<>();
        for (UserQada q : dbQada) {
            Map<String, Object> qMap = new HashMap<>();
            qMap.put("uuid", q.getUuid());
            qMap.put("prayer_name", q.getPrayerName());
            qMap.put("date_missed", q.getDateMissed());
            qMap.put("is_completed", q.isCompleted());
            finalQada.add(qMap);
        }

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("streak", finalStreak);
        response.put("history", finalHistory);
        response.put("qada", finalQada);

        return ResponseEntity.ok(response);
    }
}
