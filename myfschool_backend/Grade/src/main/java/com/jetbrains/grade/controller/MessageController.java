package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.ConversationDTO;
import com.jetbrains.grade.dto.MessageDTO;
import com.jetbrains.grade.dto.SendMessageRequest;
import com.jetbrains.grade.service.MessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    @PostMapping
    public ResponseEntity<MessageDTO> sendMessage(@RequestBody SendMessageRequest req) {
        MessageDTO dto = messageService.sendMessage(req);
        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationDTO>> getConversations() {
        return ResponseEntity.ok(messageService.getConversations());
    }

    @GetMapping("/with/{targetUserId}")
    public ResponseEntity<List<MessageDTO>> getMessagesWith(@PathVariable Integer targetUserId) {
        return ResponseEntity.ok(messageService.getMessagesWith(targetUserId));
    }

    @PatchMapping("/read/{targetUserId}")
    public ResponseEntity<?> markAsRead(@PathVariable Integer targetUserId) {
        messageService.markAsRead(targetUserId);
        return ResponseEntity.ok(Map.of("success", true, "message", "Da danh dau da doc"));
    }
}
