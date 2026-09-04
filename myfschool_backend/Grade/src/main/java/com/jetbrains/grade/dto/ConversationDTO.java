package com.jetbrains.grade.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversationDTO {
    private Integer targetUserId;
    private String targetName;
    private String targetRole;
    private String targetAvatar;
    private String lastMessage;
    private LocalDateTime lastMessageTime;
    private Long unreadCount;
}
