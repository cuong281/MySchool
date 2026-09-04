package com.jetbrains.grade.service.push;

import com.jetbrains.grade.model.User;
import com.jetbrains.grade.model.UserDeviceToken;
import com.jetbrains.grade.repository.UserDeviceTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class PushNotificationDispatcher {

    private final PushNotificationProvider pushProvider;
    private final UserDeviceTokenRepository tokenRepository;

    /**
     * Dispatches push notification best-effort. Failures never fail the main transaction.
     */
    public void dispatch(User user, String title, String body, Map<String, String> data) {
        if (user == null || user.getId() == null) {
            return;
        }

        try {
            List<UserDeviceToken> tokens = tokenRepository.findByUserId(user.getId());
            if (tokens.isEmpty()) {
                log.debug("No registered device tokens found for user ID: {}", user.getId());
                return;
            }

            for (UserDeviceToken token : tokens) {
                try {
                    pushProvider.sendPush(token.getDeviceToken(), title, body, data);
                } catch (Exception e) {
                    log.warn("Failed to push to device token for user {}: {}", user.getId(), e.getMessage());
                }
            }
        } catch (Exception e) {
            log.warn("Unexpected error in PushNotificationDispatcher for user {}: {}", user.getId(), e.getMessage());
        }
    }
}
