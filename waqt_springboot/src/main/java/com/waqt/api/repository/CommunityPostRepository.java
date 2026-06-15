package com.waqt.api.repository;

import com.waqt.api.entity.CommunityPost;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CommunityPostRepository extends JpaRepository<CommunityPost, Long> {
    List<CommunityPost> findByPostTypeIn(List<String> postTypes, Pageable pageable);
}
