package com.waqt.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_streaks")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserStreak {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(nullable = false)
    private int count;

    @Column(name = "is_frozen", nullable = false)
    private boolean isFrozen;

    @Column(name = "last_updated_date", length = 50)
    private String lastUpdatedDate;

    @Column(name = "updated_at", insertable = false, updatable = false, columnDefinition = "datetime default current_timestamp on update current_timestamp")
    private LocalDateTime updatedAt;
}
