package com.jetbrains.grade.service.push;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Service;

import java.util.Map;

@Slf4j
@Service
@ConditionalOnMissingBean(type = "FirebasePushNotificationProvider")
public class MockPushNotificationProvider implements PushNotificationProvider {

    @Override
    public void sendPush(String deviceToken, String title, String body, Map<String, String> data) {
        log.info("[MOCK FCM PUSH] Target Token: {} | Title: '{}' | Body: '{}' | Data: {}",
                deviceToken != null && deviceToken.length() > 15 ? deviceToken.substring(0, 15) + "..." : deviceToken,
                title, body, data);
    }
}
