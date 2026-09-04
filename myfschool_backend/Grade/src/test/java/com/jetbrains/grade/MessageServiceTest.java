package com.jetbrains.grade;

import com.jetbrains.grade.dto.ConversationDTO;
import com.jetbrains.grade.dto.MessageDTO;
import com.jetbrains.grade.dto.SendMessageRequest;
import com.jetbrains.grade.model.Role;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.security.CustomUserDetails;
import com.jetbrains.grade.service.MessageService;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
public class MessageServiceTest {

    @Autowired
    private MessageService messageService;

    @AfterEach
    public void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private void authenticateUser(int userId, String username, String roleName) {
        User user = new User();
        user.setId(userId);
        user.setUsername(username);
        Role role = new Role();
        role.setId(1);
        role.setRoleName(roleName);
        user.setRoles(Set.of(role));

        CustomUserDetails details = new CustomUserDetails(user);
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities());
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @Test
    public void testSendMessageAndRetrieve() {
        // 1. Admin (User 1) sends message to User 4 (Teacher 1)
        authenticateUser(1, "admin", "ROLE_ADMIN");
        SendMessageRequest req = SendMessageRequest.builder()
                .receiverUserId(4)
                .content("Xin chao giao vien, day la tin nhan tu Admin")
                .build();

        MessageDTO sent = messageService.sendMessage(req);
        assertNotNull(sent.getId());
        assertEquals("Xin chao giao vien, day la tin nhan tu Admin", sent.getContent());
        assertEquals(1, sent.getSenderUserId());
        assertEquals(4, sent.getReceiverUserId());
        assertTrue(sent.getIsMe());

        // 2. Admin retrieves conversation with User 4
        List<MessageDTO> adminMessages = messageService.getMessagesWith(4);
        assertFalse(adminMessages.isEmpty());
        assertTrue(adminMessages.stream().anyMatch(m -> m.getContent().contains("Xin chao giao vien")));

        // 3. User 4 (Teacher) logs in and retrieves conversation with Admin
        authenticateUser(4, "teacher1", "ROLE_TEACHER");
        List<MessageDTO> teacherMessages = messageService.getMessagesWith(1);
        assertFalse(teacherMessages.isEmpty());
        MessageDTO received = teacherMessages.get(teacherMessages.size() - 1);
        assertEquals(1, received.getSenderUserId());
        assertFalse(received.getIsMe());

        // 4. Check conversation list for User 4
        List<ConversationDTO> conversations = messageService.getConversations();
        assertFalse(conversations.isEmpty());
        ConversationDTO convoWithAdmin = conversations.stream()
                .filter(c -> c.getTargetUserId().equals(1))
                .findFirst()
                .orElse(null);
        assertNotNull(convoWithAdmin);
        assertTrue(convoWithAdmin.getLastMessage().contains("Xin chao"));
    }

    @Test
    public void testSelfMessageProhibited() {
        authenticateUser(1, "admin", "ROLE_ADMIN");
        SendMessageRequest req = SendMessageRequest.builder()
                .receiverUserId(1) // self
                .content("Tu gui cho minh")
                .build();

        assertThrows(IllegalArgumentException.class, () -> messageService.sendMessage(req));
    }
}
