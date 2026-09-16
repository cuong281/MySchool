package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.EventCreateRequest;
import com.jetbrains.grade.dto.EventUpdateRequest;
import com.jetbrains.grade.model.Event;
import com.jetbrains.grade.repository.EventRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.NoSuchElementException;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Mockito unit tests for EventService — no Spring context.
 */
@ExtendWith(MockitoExtension.class)
class EventServiceUnitTest {

    @Mock
    private EventRepository eventRepository;

    @InjectMocks
    private EventService eventService;

    // ── Create ───────────────────────────────────────────────────────

    @Test
    @DisplayName("createEvent → saves event with default status 'Sắp tới' when status is null")
    void createEvent_defaultStatus() {
        EventCreateRequest req = EventCreateRequest.builder()
                .title("Hội trại")
                .description("Hoạt động ngoại khóa")
                .startAt(LocalDateTime.of(2026, 10, 1, 8, 0))
                .build();

        Event savedEvent = new Event();
        savedEvent.setId(1);
        savedEvent.setTitle("Hội trại");
        savedEvent.setStatus("Sắp tới");

        when(eventRepository.save(any(Event.class))).thenReturn(savedEvent);

        Event result = eventService.createEvent(req);

        ArgumentCaptor<Event> captor = ArgumentCaptor.forClass(Event.class);
        verify(eventRepository).save(captor.capture());

        Event captured = captor.getValue();
        assertEquals("Hội trại", captured.getTitle());
        assertEquals("Sắp tới", captured.getStatus());
        assertNotNull(result);
        assertEquals(1, result.getId());
    }

    @Test
    @DisplayName("createEvent → uses provided status when not null")
    void createEvent_customStatus() {
        EventCreateRequest req = EventCreateRequest.builder()
                .title("Khai giảng")
                .startAt(LocalDateTime.of(2026, 9, 5, 7, 30))
                .status("Đang diễn ra")
                .build();

        when(eventRepository.save(any(Event.class))).thenAnswer(inv -> {
            Event e = inv.getArgument(0);
            e.setId(2);
            return e;
        });

        Event result = eventService.createEvent(req);
        assertEquals("Đang diễn ra", result.getStatus());
    }

    // ── Update ───────────────────────────────────────────────────────

    @Test
    @DisplayName("updateEvent → updates existing event fields")
    void updateEvent_success() {
        Event existing = new Event();
        existing.setId(1);
        existing.setTitle("Old Title");
        existing.setStatus("Sắp tới");
        existing.setStartAt(LocalDateTime.of(2026, 9, 1, 8, 0));

        when(eventRepository.findById(1)).thenReturn(Optional.of(existing));
        when(eventRepository.save(any(Event.class))).thenAnswer(inv -> inv.getArgument(0));

        EventUpdateRequest req = EventUpdateRequest.builder()
                .title("New Title")
                .description("Updated desc")
                .startAt(LocalDateTime.of(2026, 10, 1, 9, 0))
                .status("Đã kết thúc")
                .build();

        Event result = eventService.updateEvent(1, req);

        assertEquals("New Title", result.getTitle());
        assertEquals("Updated desc", result.getDescription());
        assertEquals("Đã kết thúc", result.getStatus());
        assertEquals(LocalDateTime.of(2026, 10, 1, 9, 0), result.getStartAt());
    }

    @Test
    @DisplayName("updateEvent → throws NoSuchElementException for non-existent ID")
    void updateEvent_notFound() {
        when(eventRepository.findById(999)).thenReturn(Optional.empty());

        EventUpdateRequest req = EventUpdateRequest.builder()
                .title("Irrelevant")
                .build();

        NoSuchElementException ex = assertThrows(NoSuchElementException.class,
                () -> eventService.updateEvent(999, req));
        assertTrue(ex.getMessage().contains("999"));
    }

    // ── Delete ───────────────────────────────────────────────────────

    @Test
    @DisplayName("deleteEvent → deletes when event exists")
    void deleteEvent_success() {
        when(eventRepository.existsById(1)).thenReturn(true);

        assertDoesNotThrow(() -> eventService.deleteEvent(1));
        verify(eventRepository).deleteById(1);
    }

    @Test
    @DisplayName("deleteEvent → throws NoSuchElementException for non-existent ID")
    void deleteEvent_notFound() {
        when(eventRepository.existsById(999)).thenReturn(false);

        NoSuchElementException ex = assertThrows(NoSuchElementException.class,
                () -> eventService.deleteEvent(999));
        assertTrue(ex.getMessage().contains("999"));
        verify(eventRepository, never()).deleteById(anyInt());
    }

    // ── getById ──────────────────────────────────────────────────────

    @Test
    @DisplayName("getById → returns Optional.of(event) when found")
    void getById_found() {
        Event event = new Event();
        event.setId(1);
        event.setTitle("Test");
        when(eventRepository.findById(1)).thenReturn(Optional.of(event));

        Optional<Event> result = eventService.getById(1);
        assertTrue(result.isPresent());
        assertEquals("Test", result.get().getTitle());
    }

    @Test
    @DisplayName("getById → returns Optional.empty() when not found")
    void getById_notFound() {
        when(eventRepository.findById(999)).thenReturn(Optional.empty());

        Optional<Event> result = eventService.getById(999);
        assertTrue(result.isEmpty());
    }
}
