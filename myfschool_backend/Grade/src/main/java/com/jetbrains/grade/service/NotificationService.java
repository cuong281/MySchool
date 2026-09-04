package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.NotificationDTO;
import com.jetbrains.grade.model.Notification;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.model.UserDeviceToken;
import com.jetbrains.grade.repository.NotificationRepository;
import com.jetbrains.grade.repository.UserDeviceTokenRepository;
import com.jetbrains.grade.repository.UserRepository;
import com.jetbrains.grade.security.SecurityUtils;
import com.jetbrains.grade.service.push.PushNotificationDispatcher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserDeviceTokenRepository deviceTokenRepository;
    private final UserRepository userRepository;
    private final PushNotificationDispatcher pushDispatcher;

    @Transactional
    public Notification createNotification(User user, String title, String body, String type, Integer referenceId) {
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setType(type);
        notification.setReferenceId(referenceId);
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());

        Notification saved = notificationRepository.save(notification);

        // Best-effort Push Notification (never throws out to break transaction)
        try {
            pushDispatcher.dispatch(user, title, body, Map.of(
                    "type", type != null ? type : "SYSTEM",
                    "referenceId", referenceId != null ? String.valueOf(referenceId) : "",
                    "notificationId", String.valueOf(saved.getId())
            ));
        } catch (Exception e) {
            log.warn("FCM push failed for user {}: {}", user.getId(), e.getMessage());
        }

        return saved;
    }

    public List<NotificationDTO> getMyNotifications() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(currentUserId).stream()
                .map(this::mapToDTO)
                .toList();
    }

    public long getUnreadCount() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        return notificationRepository.countByUserIdAndIsReadFalse(currentUserId);
    }

    @Transactional
    public NotificationDTO markAsRead(Integer notificationId) {
        Integer currentUserId = SecurityUtils.getCurrentUserId();

        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay thong bao voi ID: " + notificationId));

        // Enforce ownership: student/user can only mark their own notification as read
        if (!SecurityUtils.isAdmin() && !notification.getUser().getId().equals(currentUserId)) {
            throw new AccessDeniedException("Ban khong co quyen thay doi thong bao cua nguoi dung khac");
        }

        notification.setIsRead(true);
        notification.setReadAt(LocalDateTime.now());
        Notification saved = notificationRepository.save(notification);
        return mapToDTO(saved);
    }

    @Transactional
    public void markAllAsRead() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        notificationRepository.markAllAsReadByUserId(currentUserId);
    }

    @Transactional
    public void registerDeviceToken(String deviceToken, String deviceType) {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        User user = userRepository.findByIdAndIsActiveTrue(currentUserId)
                .orElseThrow(() -> new IllegalArgumentException("User not found or inactive"));

        var existingOpt = deviceTokenRepository.findByUserIdAndDeviceToken(currentUserId, deviceToken);
        if (existingOpt.isPresent()) {
            UserDeviceToken existing = existingOpt.get();
            existing.setLastActiveAt(LocalDateTime.now());
            if (deviceType != null) {
                existing.setDeviceType(deviceType);
            }
            deviceTokenRepository.save(existing);
        } else {
            UserDeviceToken token = new UserDeviceToken();
            token.setUser(user);
            token.setDeviceToken(deviceToken);
            token.setDeviceType(deviceType != null ? deviceType : "ANDROID");
            token.setCreatedAt(LocalDateTime.now());
            token.setLastActiveAt(LocalDateTime.now());
            deviceTokenRepository.save(token);
        }
    }

    @Transactional
    public void unregisterDeviceToken(String deviceToken) {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        deviceTokenRepository.deleteByUserIdAndDeviceToken(currentUserId, deviceToken);
    }

    private NotificationDTO mapToDTO(Notification n) {
        return NotificationDTO.builder()
                .id(n.getId())
                .userId(n.getUser() != null ? n.getUser().getId() : null)
                .title(n.getTitle())
                .body(n.getBody())
                .type(n.getType())
                .referenceId(n.getReferenceId())
                .isRead(n.getIsRead())
                .createdAt(n.getCreatedAt())
                .readAt(n.getReadAt())
                .build();
    }
}
