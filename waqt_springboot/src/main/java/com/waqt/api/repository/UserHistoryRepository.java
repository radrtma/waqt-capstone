package com.waqt.api.repository;

import com.waqt.api.entity.UserHistory;
import com.waqt.api.entity.UserHistoryId;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface UserHistoryRepository extends JpaRepository<UserHistory, UserHistoryId> {
    List<UserHistory> findByUserId(Long userId, Pageable pageable);
}
