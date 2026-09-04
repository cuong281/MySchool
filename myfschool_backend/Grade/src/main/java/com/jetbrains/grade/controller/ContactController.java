package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.TeacherContactDTO;
import com.jetbrains.grade.service.ContactService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/contacts")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    @GetMapping("/me")
    public List<TeacherContactDTO> getMyTeachers() {
        return contactService.getMyTeachers();
    }

    @GetMapping("/user/{userId}")
    public List<TeacherContactDTO> getTeachersForStudent(@PathVariable Integer userId) {
        return contactService.getTeachersForUser(userId);
    }

    @PatchMapping("/me/phone-privacy")
    public org.springframework.http.ResponseEntity<java.util.Map<String, Object>> updatePhonePrivacy(
            @RequestBody java.util.Map<String, Boolean> body) {
        Boolean isPhonePublic = body != null && body.getOrDefault("isPhonePublic", false);
        boolean updated = contactService.updateMyPhonePrivacy(isPhonePublic);
        return org.springframework.http.ResponseEntity.ok(java.util.Map.of(
                "isPhonePublic", updated,
                "message", "Cap nhat quyen rieng tu SĐT thanh cong"
        ));
    }
}
