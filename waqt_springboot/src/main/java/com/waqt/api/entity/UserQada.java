package com.waqt.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_qada")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserQada {

    @Id
    @Column(length = 100)
    private String uuid;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "prayer_name", nullable = false, length = 50)
    private String prayerName;

    @Column(name = "date_missed", nullable = false, length = 50)
    private String dateMissed;

    @Column(name = "is_completed", nullable = false)
    private boolean isCompleted;

    @Column(name = "updated_at", insertable = false, updatable = false, columnDefinition = "datetime default current_timestamp on update current_timestamp")
    private LocalDateTime updatedAt;
}
