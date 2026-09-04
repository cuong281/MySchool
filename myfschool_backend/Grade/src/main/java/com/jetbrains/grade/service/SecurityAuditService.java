package com.jetbrains.grade.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
public class SecurityAuditService {

    public void logSecurityEvent(String action, Integer actorUserId, String username, List<String> roles,
                                 String resource, String status, String details) {
        log.info("[AUDIT] Timestamp={}, Action={}, ActorId={}, Username={}, Roles={}, Resource={}, Status={}, Details={}",
                LocalDateTime.now(), action, actorUserId != null ? actorUserId : "ANONYMOUS",
                username != null ? username : "N/A", roles != null ? roles : "[]",
                resource != null ? resource : "N/A", status, details != null ? details : "");
    }
}
