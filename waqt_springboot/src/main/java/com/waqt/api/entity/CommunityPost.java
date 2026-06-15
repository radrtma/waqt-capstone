package com.waqt.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "community_posts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CommunityPost {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "post_type", nullable = false, length = 50)
    private String postType;

    @Column(nullable = false, length = 100)
    private String username;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String content;

    @Column(name = "mosque_name", length = 255)
    private String mosqueName;

    @Column(name = "is_wudu_clean", nullable = false)
    private boolean isWuduClean;

    @Column(name = "is_ac_working", nullable = false)
    private boolean isAcWorking;

    @Column(name = "is_female_friendly", nullable = false)
    private boolean isFemaleFriendly;

    @Column(name = "helpful_count", nullable = false)
    private int helpfulCount;

    @Column(name = "inspiring_count", nullable = false)
    private int inspiringCount;

    @Column(name = "useful_count", nullable = false)
    private int usefulCount;

    @Column(name = "event_name", length = 255)
    private String eventName;

    @Column(name = "event_date", length = 100)
    private String eventDate;

    @Column(name = "event_location", length = 255)
    private String eventLocation;

    @Column(name = "comment_count", nullable = false)
    private int commentCount;

    @Column(name = "image_paths", columnDefinition = "TEXT")
    private String imagePaths;

    @Column(name = "created_at", insertable = false, updatable = false, columnDefinition = "datetime default current_timestamp")
    private LocalDateTime createdAt;
}
