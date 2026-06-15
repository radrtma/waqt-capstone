package com.waqt.api.repository;

import com.waqt.api.entity.UserQada;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface UserQadaRepository extends JpaRepository<UserQada, String> {
    List<UserQada> findByUserId(Long userId);
}
