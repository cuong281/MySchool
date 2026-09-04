package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Integer> {

    @Query("SELECT m FROM Message m JOIN FETCH m.sender JOIN FETCH m.receiver " +
           "WHERE (m.sender.id = :user1 AND m.receiver.id = :user2) " +
           "   OR (m.sender.id = :user2 AND m.receiver.id = :user1) " +
           "ORDER BY m.sentAt ASC")
    List<Message> findConversation(@Param("user1") Integer user1, @Param("user2") Integer user2);

    @Query("SELECT DISTINCT CASE WHEN m.sender.id = :userId THEN m.receiver.id ELSE m.sender.id END " +
           "FROM Message m " +
           "WHERE m.sender.id = :userId OR m.receiver.id = :userId")
    List<Integer> findConversationPartnerIds(@Param("userId") Integer userId);

    @Query("SELECT m FROM Message m JOIN FETCH m.sender JOIN FETCH m.receiver " +
           "WHERE (m.sender.id = :user1 AND m.receiver.id = :user2) " +
           "   OR (m.sender.id = :user2 AND m.receiver.id = :user1) " +
           "ORDER BY m.sentAt DESC")
    List<Message> findLatestMessageBetween(@Param("user1") Integer user1, @Param("user2") Integer user2);

    @Query("SELECT COUNT(m) FROM Message m " +
           "WHERE m.sender.id = :senderId AND m.receiver.id = :receiverId AND m.isRead = false")
    Long countUnreadMessages(@Param("senderId") Integer senderId, @Param("receiverId") Integer receiverId);

    @Modifying
    @Query("UPDATE Message m SET m.isRead = true, m.readAt = :readAt " +
           "WHERE m.sender.id = :senderId AND m.receiver.id = :receiverId AND m.isRead = false")
    int markAsRead(@Param("senderId") Integer senderId, @Param("receiverId") Integer receiverId, @Param("readAt") LocalDateTime readAt);
}
