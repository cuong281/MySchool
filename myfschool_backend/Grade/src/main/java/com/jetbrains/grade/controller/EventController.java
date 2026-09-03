package com.jetbrains.grade.controller;

import com.jetbrains.grade.model.Event;
import com.jetbrains.grade.service.EventService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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
        return ResponseEntity.ok(eventService.getAllEvents().stream().map(e -> com.jetbrains.grade.dto.EventDTO.builder()
                .id(e.getId())
                .title(e.getTitle())
                .description(e.getDescription())
                .date(e.getStartAt() != null ? e.getStartAt().toLocalDate().toString() : "")
                .time(e.getStartAt() != null ? String.format("%02d:%02d", e.getStartAt().getHour(), e.getStartAt().getMinute()) : "")
                .location(e.getLocation())
                .category(e.getCategory())
                .status(e.getStatus())
                .color("#000000")
                .icon("event")
                .build()).toList());
    }

    @PostMapping
    public ResponseEntity<Event> createEvent(@RequestBody Event event) {
        return ResponseEntity.ok(eventService.createEvent(event));
    }
}
