package com.jetbrains.grade.service.push;

import java.util.Map;

public interface PushNotificationProvider {
    void sendPush(String deviceToken, String title, String body, Map<String, String> data);
}
