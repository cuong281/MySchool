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
public class MessageDTO {
    private Integer id;
    private Integer senderUserId;
    private String senderName;
    private String senderAvatar;
    private Integer receiverUserId;
    private String receiverName;
    private String receiverAvatar;
    private String content;
    private LocalDateTime sentAt;
    private Boolean isRead;
    private Boolean isMe;
}
