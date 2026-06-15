package com.waqt.api.repository;

import com.waqt.api.entity.CommunityReply;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CommunityReplyRepository extends JpaRepository<CommunityReply, Long> {
    List<CommunityReply> findByCommentIdInOrderByCreatedAtAsc(List<Long> commentIds);
}
