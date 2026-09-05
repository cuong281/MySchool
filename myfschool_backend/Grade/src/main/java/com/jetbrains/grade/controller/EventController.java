package com.jetbrains.grade.controller;

import com.jetbrains.grade.model.Event;
import com.jetbrains.grade.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/events")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class EventController {

    private final EventService eventService;

    @GetMapping
    public ResponseEntity<List<com.jetbrains.grade.dto.EventDTO>> getAllEvents() {
        java.time.LocalDate today = java.time.LocalDate.now();

        List<com.jetbrains.grade.dto.EventDTO> dtoList = eventService.getAllEvents().stream().map(e -> {
            java.time.LocalDate startDate = e.getStartAt() != null ? e.getStartAt().toLocalDate() : today;
            java.time.LocalDate endDate = e.getEndAt() != null ? e.getEndAt().toLocalDate() : startDate;

            String dynamicStatus;
            if (endDate.isBefore(today)) {
                dynamicStatus = "Đã kết thúc";
            } else if (startDate.isAfter(today)) {
                dynamicStatus = "Sắp tới";
            } else {
                dynamicStatus = "Đang diễn ra";
            }

            String cat = e.getCategory() != null ? e.getCategory().toUpperCase() : "";
            String color;
            String icon;

            switch (cat) {
                case "STEM":
                    color = "#0288D1";
                    icon = "precision_manufacturing_rounded";
                    break;
                case "SEMINAR":
                    color = "#6A1B9A";
                    icon = "school_rounded";
                    break;
                case "CULTURE":
                    color = "#E65100";
                    icon = "celebration_rounded";
                    break;
                case "SPORTS":
                    color = "#2E7D32";
                    icon = "sports_soccer_rounded";
                    break;
                case "MUSIC":
                    color = "#C2185B";
                    icon = "music_note_rounded";
                    break;
                case "COMPETITION":
                    color = "#F57F17";
                    icon = "emoji_events_rounded";
                    break;
                default:
                    color = "#1565C0";
                    icon = "school";
                    break;
            }

            return com.jetbrains.grade.dto.EventDTO.builder()
                    .id(e.getId())
                    .title(e.getTitle())
                    .description(e.getDescription())
                    .date(startDate.toString())
                    .time(e.getStartAt() != null ? String.format("%02d:%02d", e.getStartAt().getHour(), e.getStartAt().getMinute()) : "08:00")
                    .location(e.getLocation())
                    .category(e.getCategory())
                    .status(dynamicStatus)
                    .color(color)
                    .icon(icon)
                    .build();
        }).sorted((a, b) -> {
            int pA = "Đang diễn ra".equals(a.getStatus()) ? 1 : ("Sắp tới".equals(a.getStatus()) ? 2 : 3);
            int pB = "Đang diễn ra".equals(b.getStatus()) ? 1 : ("Sắp tới".equals(b.getStatus()) ? 2 : 3);
            if (pA != pB) return Integer.compare(pA, pB);
            return a.getDate().compareTo(b.getDate());
        }).toList();

        return ResponseEntity.ok(dtoList);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Event> createEvent(@RequestBody Event event) {
        return ResponseEntity.ok(eventService.createEvent(event));
    }
}
