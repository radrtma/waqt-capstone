package com.waqt.api.repository;

import com.waqt.api.entity.UserStreak;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserStreakRepository extends JpaRepository<UserStreak, Long> {
}
