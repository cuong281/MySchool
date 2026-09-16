package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.EventCreateRequest;
import com.jetbrains.grade.dto.EventDTO;
import com.jetbrains.grade.dto.EventUpdateRequest;
import com.jetbrains.grade.dto.PageResponse;
import com.jetbrains.grade.model.Event;
import com.jetbrains.grade.service.EventService;
import com.jetbrains.grade.util.PaginationUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/events")
@RequiredArgsConstructor
@Tag(name = "Events", description = "Quản lý và tra cứu sự kiện trường học")
public class EventController {

    private final EventService eventService;

    @Operation(summary = "Lấy danh sách sự kiện", description = "Trả về danh sách sự kiện. Nếu truyền 'page', kết quả được phân trang (PageResponse); nếu không truyền, trả về List thông thường để tương thích ngược.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Lấy danh sách sự kiện thành công")
    })
    @GetMapping
    public ResponseEntity<?> getAllEvents(
            @Parameter(description = "Số trang (0-indexed). Nếu không truyền sẽ trả về toàn bộ danh sách.")
            @RequestParam(required = false) Integer page,
            @Parameter(description = "Kích thước trang (mặc định 20, tối đa 100).")
            @RequestParam(required = false) Integer size,
            @Parameter(description = "Trường sắp xếp.")
            @RequestParam(required = false) String sort,
            @Parameter(description = "Hướng sắp xếp (asc hoặc desc). Mặc định asc.")
            @RequestParam(required = false, defaultValue = "asc") String direction
    ) {
        List<EventDTO> allEvents = eventService.getAllEvents().stream()
                .map(this::mapToDTO)
                .sorted((a, b) -> {
                    int pA = "Đang diễn ra".equals(a.getStatus()) ? 1 : ("Sắp tới".equals(a.getStatus()) ? 2 : 3);
                    int pB = "Đang diễn ra".equals(b.getStatus()) ? 1 : ("Sắp tới".equals(b.getStatus()) ? 2 : 3);
                    if (pA != pB) return Integer.compare(pA, pB);
                    return a.getDate().compareTo(b.getDate());
                })
                .toList();

        if (page == null) {
            return ResponseEntity.ok(allEvents);
        }

        Pageable pageable = PaginationUtils.createPageable(page, size, sort, direction);
        int start = (int) Math.min(pageable.getOffset(), allEvents.size());
        int end = Math.min(start + pageable.getPageSize(), allEvents.size());
        List<EventDTO> pagedContent = allEvents.subList(start, end);
        Page<EventDTO> pageResult = new PageImpl<>(pagedContent, pageable, allEvents.size());

        return ResponseEntity.ok(PageResponse.fromPage(pageResult));
    }

    @Operation(summary = "Xem chi tiết sự kiện theo ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Lấy chi tiết sự kiện thành công"),
            @ApiResponse(responseCode = "404", description = "Không tìm thấy sự kiện với ID tương ứng")
    })
    @GetMapping("/{id}")
    public ResponseEntity<EventDTO> getById(@PathVariable Integer id) {
        Event event = eventService.getById(id)
                .orElseThrow(() -> new NoSuchElementException("Không tìm thấy sự kiện với ID: " + id));
        return ResponseEntity.ok(mapToDTO(event));
    }

    @Operation(summary = "Tạo sự kiện mới (Admin)")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Tạo sự kiện mới thành công"),
            @ApiResponse(responseCode = "400", description = "Dữ liệu không hợp lệ"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Không có quyền Admin")
    })
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<EventDTO> createEvent(@Valid @RequestBody EventCreateRequest request) {
        Event created = eventService.createEvent(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(mapToDTO(created));
    }

    @Operation(summary = "Cập nhật sự kiện (Admin)")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cập nhật sự kiện thành công"),
            @ApiResponse(responseCode = "400", description = "Dữ liệu không hợp lệ"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Không có quyền Admin"),
            @ApiResponse(responseCode = "404", description = "Không tìm thấy sự kiện để cập nhật")
    })
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<EventDTO> updateEvent(@PathVariable Integer id, @Valid @RequestBody EventUpdateRequest request) {
        Event updated = eventService.updateEvent(id, request);
        return ResponseEntity.ok(mapToDTO(updated));
    }

    @Operation(summary = "Xóa sự kiện (Admin)")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Xóa sự kiện thành công"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Không có quyền Admin"),
            @ApiResponse(responseCode = "404", description = "Không tìm thấy sự kiện để xóa")
    })
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> deleteEvent(@PathVariable Integer id) {
        eventService.deleteEvent(id);
        return ResponseEntity.ok(Map.of("success", true, "message", "Xóa sự kiện thành công"));
    }

    private EventDTO mapToDTO(Event e) {
        LocalDate today = LocalDate.now();
        LocalDate startDate = e.getStartAt() != null ? e.getStartAt().toLocalDate() : today;
        LocalDate endDate = e.getEndAt() != null ? e.getEndAt().toLocalDate() : startDate;

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

        return EventDTO.builder()
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
    }
}

