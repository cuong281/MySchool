package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.ConversationDTO;
import com.jetbrains.grade.dto.MessageDTO;
import com.jetbrains.grade.dto.SendMessageRequest;
import com.jetbrains.grade.model.Message;
import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.repository.MessageRepository;
import com.jetbrains.grade.repository.UserRepository;
import com.jetbrains.grade.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class MessageService {

    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    @Transactional
    public MessageDTO sendMessage(SendMessageRequest req) {
        Integer senderUserId = SecurityUtils.getCurrentUserId();
        if (req.getReceiverUserId() == null) {
            throw new IllegalArgumentException("Nguoi nhan khong duoc de trong");
        }
        if (req.getReceiverUserId().equals(senderUserId)) {
            throw new IllegalArgumentException("Khong the tu gui tin nhan cho chinh minh");
        }
        if (req.getContent() == null || req.getContent().trim().isEmpty()) {
            throw new IllegalArgumentException("Noi dung tin nhan khong duoc de trong");
        }
        if (req.getContent().trim().length() > 2000) {
            throw new IllegalArgumentException("Noi dung tin nhan toi da 2000 ky tu");
        }

        User sender = userRepository.findById(senderUserId)
                .orElseThrow(() -> new NoSuchElementException("Khong tim thay nguoi gui voi ID: " + senderUserId));
        User receiver = userRepository.findById(req.getReceiverUserId())
                .orElseThrow(() -> new NoSuchElementException("Khong tim thay nguoi nhan voi ID: " + req.getReceiverUserId()));

        Message message = new Message();
        message.setSender(sender);
        message.setReceiver(receiver);
        message.setContent(req.getContent().trim());
        message.setSentAt(LocalDateTime.now());
        message.setIsRead(false);

        Message saved = messageRepository.save(message);

        // Best-effort in-app notification to receiver
        try {
            String senderName = getUserFullName(sender);
            String snippet = saved.getContent().length() > 80
                    ? saved.getContent().substring(0, 77) + "..."
                    : saved.getContent();

            notificationService.createNotification(
                    receiver,
                    "Tin nhắn mới từ " + senderName,
                    snippet,
                    "NEW_MESSAGE",
                    saved.getId()
            );
        } catch (Exception e) {
            log.warn("Failed to trigger message notification: {}", e.getMessage());
        }

        return mapToDTO(saved, senderUserId);
    }

    @Transactional(readOnly = true)
    public List<ConversationDTO> getConversations() {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        List<Integer> partnerIds = messageRepository.findConversationPartnerIds(currentUserId);

        List<ConversationDTO> conversations = new ArrayList<>();
        for (Integer partnerId : partnerIds) {
            User partner = userRepository.findById(partnerId).orElse(null);
            if (partner == null) continue;

            List<Message> latestList = messageRepository.findLatestMessageBetween(currentUserId, partnerId);
            Message latest = latestList.isEmpty() ? null : latestList.get(0);
            Long unread = messageRepository.countUnreadMessages(partnerId, currentUserId);

            conversations.add(ConversationDTO.builder()
                    .targetUserId(partner.getId())
                    .targetName(getUserFullName(partner))
                    .targetRole(getUserPrimaryRole(partner))
                    .targetAvatar(partner.getAvatarUrl())
                    .lastMessage(latest != null ? latest.getContent() : "")
                    .lastMessageTime(latest != null ? latest.getSentAt() : null)
                    .unreadCount(unread != null ? unread : 0L)
                    .build());
        }

        conversations.sort((c1, c2) -> {
            if (c1.getLastMessageTime() == null) return 1;
            if (c2.getLastMessageTime() == null) return -1;
            return c2.getLastMessageTime().compareTo(c1.getLastMessageTime());
        });

        return conversations;
    }

    @Transactional
    public List<MessageDTO> getMessagesWith(Integer targetUserId) {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        if (targetUserId == null) {
            throw new IllegalArgumentException("Target user ID khong duoc de trong");
        }
        User partner = userRepository.findById(targetUserId)
                .orElseThrow(() -> new NoSuchElementException("Nguoi dung khong ton tai"));

        // Auto mark messages from targetUser to currentUser as read
        messageRepository.markAsRead(targetUserId, currentUserId, LocalDateTime.now());

        List<Message> messages = messageRepository.findConversation(currentUserId, targetUserId);
        return messages.stream()
                .map(m -> mapToDTO(m, currentUserId))
                .collect(Collectors.toList());
    }

    @Transactional
    public boolean markAsRead(Integer targetUserId) {
        Integer currentUserId = SecurityUtils.getCurrentUserId();
        int count = messageRepository.markAsRead(targetUserId, currentUserId, LocalDateTime.now());
        return true;
    }

    private MessageDTO mapToDTO(Message m, Integer currentUserId) {
        boolean isMe = m.getSender().getId().equals(currentUserId);
        return MessageDTO.builder()
                .id(m.getId())
                .senderUserId(m.getSender().getId())
                .senderName(getUserFullName(m.getSender()))
                .senderAvatar(m.getSender().getAvatarUrl())
                .receiverUserId(m.getReceiver().getId())
                .receiverName(getUserFullName(m.getReceiver()))
                .receiverAvatar(m.getReceiver().getAvatarUrl())
                .content(m.getContent())
                .sentAt(m.getSentAt())
                .isRead(m.getIsRead())
                .isMe(isMe)
                .build();
    }

    private String getUserFullName(User u) {
        if (u.getLastName() != null || u.getFirstName() != null) {
            String last = u.getLastName() != null ? u.getLastName() : "";
            String first = u.getFirstName() != null ? u.getFirstName() : "";
            String full = (last + " " + first).trim();
            if (!full.isEmpty()) return full;
        }
        return u.getUsername();
    }

    private String getUserPrimaryRole(User u) {
        if (u.getRoles() != null && !u.getRoles().isEmpty()) {
            for (Role r : u.getRoles()) {
                String name = r.getRoleName();
                if ("ROLE_ADMIN".equalsIgnoreCase(name) || "ADMIN".equalsIgnoreCase(name)) return "Quản trị viên";
                if ("ROLE_TEACHER".equalsIgnoreCase(name) || "TEACHER".equalsIgnoreCase(name)) return "Giáo viên";
                if ("ROLE_STUDENT".equalsIgnoreCase(name) || "STUDENT".equalsIgnoreCase(name)) return "Học sinh";
            }
        }
        return "Người dùng";
    }
}
