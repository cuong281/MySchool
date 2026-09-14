package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Integer> {

    List<Notification> findByUserIdOrderByCreatedAtDesc(Integer userId);

    long countByUserIdAndIsReadFalse(Integer userId);

    Optional<Notification> findByIdAndUserId(Integer id, Integer userId);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP WHERE n.user.id = :userId AND n.isRead = false")
    int markAllAsReadByUserId(@Param("userId") Integer userId);

    @Query("""
        SELECT COUNT(n) > 0 FROM Notification n
        WHERE n.user.id = :userId
          AND n.type = :type
          AND n.referenceId = :referenceId
          AND n.createdAt >= :after
    """)
    boolean existsReminderSentToday(
            @Param("userId") Integer userId,
            @Param("type") String type,
            @Param("referenceId") Integer referenceId,
            @Param("after") java.time.LocalDateTime after
    );
}
