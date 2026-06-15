package com.waqt.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_history")
@IdClass(UserHistoryId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserHistory {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Id
    @Column(length = 50)
    private String date;

    @Column(name = "fajr_done", nullable = false)
    private boolean fajrDone;

    @Column(name = "dzuhur_done", nullable = false)
    private boolean dzuhurDone;

    @Column(name = "ashar_done", nullable = false)
    private boolean asharDone;

    @Column(name = "maghrib_done", nullable = false)
    private boolean maghribDone;

    @Column(name = "isha_done", nullable = false)
    private boolean ishaDone;

    @Column(name = "updated_at", insertable = false, updatable = false, columnDefinition = "datetime default current_timestamp on update current_timestamp")
    private LocalDateTime updatedAt;
}
