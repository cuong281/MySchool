package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.DeviceTokenRequest;
import com.jetbrains.grade.dto.NotificationDTO;
import com.jetbrains.grade.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping("/me")
    public ResponseEntity<List<NotificationDTO>> getMyNotifications() {
        return ResponseEntity.ok(notificationService.getMyNotifications());
    }

    @GetMapping("/me/unread-count")
    public ResponseEntity<Map<String, Long>> getUnreadCount() {
        return ResponseEntity.ok(Map.of("unreadCount", notificationService.getUnreadCount()));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<NotificationDTO> markAsRead(@PathVariable Integer id) {
        return ResponseEntity.ok(notificationService.markAsRead(id));
    }

    @PatchMapping("/me/read-all")
    public ResponseEntity<Map<String, Object>> markAllAsRead() {
        notificationService.markAllAsRead();
        return ResponseEntity.ok(Map.of("success", true, "message", "Da danh dau tat ca thong bao la da doc"));
    }

    @PostMapping("/fcm-token")
    public ResponseEntity<Map<String, Object>> registerDeviceToken(@RequestBody DeviceTokenRequest req) {
        if (req.getDeviceToken() == null || req.getDeviceToken().isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Device token khong duoc de trong"));
        }
        notificationService.registerDeviceToken(req.getDeviceToken(), req.getDeviceType());
        return ResponseEntity.ok(Map.of("success", true, "message", "Dang ky device token thanh cong"));
    }

    @DeleteMapping("/fcm-token")
    public ResponseEntity<Map<String, Object>> unregisterDeviceToken(@RequestParam String deviceToken) {
        notificationService.unregisterDeviceToken(deviceToken);
        return ResponseEntity.ok(Map.of("success", true, "message", "Huy dang ky device token thanh cong"));
    }
}
