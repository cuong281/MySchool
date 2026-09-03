package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.TeacherContactDTO;
import com.jetbrains.grade.service.ContactService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contacts")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    @GetMapping("/user/{userId}")
    public List<TeacherContactDTO> getTeachersForStudent(@PathVariable Integer userId) {
        return contactService.getTeachersForUser(userId);
    }
}
