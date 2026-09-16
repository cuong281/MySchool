package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.EventCreateRequest;
import com.jetbrains.grade.dto.EventUpdateRequest;
import com.jetbrains.grade.model.Event;
import com.jetbrains.grade.repository.EventRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class EventService {

    private final EventRepository eventRepository;

    @Transactional(readOnly = true)
    public List<Event> getAllEvents() {
        return eventRepository.findAll();
    }

    @Transactional(readOnly = true)
    public Page<Event> getAllEvents(Pageable pageable) {
        return eventRepository.findAll(pageable);
    }

    @Transactional(readOnly = true)
    public Optional<Event> getById(Integer id) {
        return eventRepository.findById(id);
    }

    @Transactional
    public Event createEvent(EventCreateRequest request) {
        Event event = new Event();
        event.setTitle(request.getTitle());
        event.setDescription(request.getDescription());
        event.setStartAt(request.getStartAt());
        event.setEndAt(request.getEndAt());
        event.setLocation(request.getLocation());
        event.setCategory(request.getCategory());
        event.setStatus(request.getStatus() != null ? request.getStatus() : "Sắp tới");
        return eventRepository.save(event);
    }

    @Transactional
    public Event updateEvent(Integer id, EventUpdateRequest request) {
        Event existing = eventRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Không tìm thấy sự kiện với ID: " + id));

        existing.setTitle(request.getTitle());
        existing.setDescription(request.getDescription());
        if (request.getStartAt() != null) {
            existing.setStartAt(request.getStartAt());
        }
        if (request.getEndAt() != null) {
            existing.setEndAt(request.getEndAt());
        }
        existing.setLocation(request.getLocation());
        existing.setCategory(request.getCategory());
        if (request.getStatus() != null) {
            existing.setStatus(request.getStatus());
        }

        return eventRepository.save(existing);
    }

    @Transactional
    public void deleteEvent(Integer id) {
        if (!eventRepository.existsById(id)) {
            throw new NoSuchElementException("Không tìm thấy sự kiện với ID: " + id);
        }
        eventRepository.deleteById(id);
    }
}
