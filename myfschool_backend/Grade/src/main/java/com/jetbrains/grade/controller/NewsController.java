package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.NewsCreateRequest;
import com.jetbrains.grade.dto.NewsDTO;
import com.jetbrains.grade.dto.NewsUpdateRequest;
import com.jetbrains.grade.dto.PageResponse;
import com.jetbrains.grade.model.News;
import com.jetbrains.grade.service.NewsService;
import com.jetbrains.grade.util.PaginationUtils;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
@Tag(name = "News", description = "Quản lý và tra cứu tin tức trường học")
public class NewsController {

    private final NewsService newsService;

    @Operation(summary = "Lấy danh sách tin tức", description = "Trả về danh sách tin tức. Nếu truyền param 'page', kết quả được phân trang (PageResponse); nếu không truyền, trả về List thông thường để tương thích ngược.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Lấy danh sách tin tức thành công")
    })
    @GetMapping
    public ResponseEntity<?> getAll(
            @Parameter(description = "Số trang (0-indexed). Nếu không truyền sẽ trả về toàn bộ danh sách.")
            @RequestParam(required = false) Integer page,
            @Parameter(description = "Kích thước trang (mặc định 20, tối đa 100).")
            @RequestParam(required = false) Integer size,
            @Parameter(description = "Trường sắp xếp (ví dụ: publishedDate, id).")
            @RequestParam(required = false) String sort,
            @Parameter(description = "Hướng sắp xếp (asc hoặc desc). Mặc định desc.")
            @RequestParam(required = false, defaultValue = "desc") String direction
    ) {
        if (page == null) {
            List<NewsDTO> list = newsService.getActiveNews().stream()
                    .map(this::mapToDTO)
                    .toList();
            return ResponseEntity.ok(list);
        }

        Sort sortObj = Sort.by("desc".equalsIgnoreCase(direction) ? Sort.Direction.DESC : Sort.Direction.ASC,
                (sort != null && !sort.isBlank()) ? sort.trim() : "publishedDate");
        Pageable pageable = PaginationUtils.createPageable(page, size, sortObj);
        Page<NewsDTO> pagedNews = newsService.getActiveNews(pageable).map(this::mapToDTO);
        return ResponseEntity.ok(PageResponse.fromPage(pagedNews));
    }

    @Operation(summary = "Xem chi tiết tin tức theo ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Lấy chi tiết tin tức thành công"),
            @ApiResponse(responseCode = "404", description = "Không tìm thấy tin tức với ID tương ứng")
    })
    @GetMapping("/{id}")
    public ResponseEntity<NewsDTO> getById(@PathVariable Integer id) {
        News news = newsService.getById(id)
                .orElseThrow(() -> new NoSuchElementException("Không tìm thấy tin tức với ID: " + id));
        return ResponseEntity.ok(mapToDTO(news));
    }

    @Operation(summary = "Tạo tin tức mới (Admin)")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Tạo tin tức thành công"),
            @ApiResponse(responseCode = "400", description = "Dữ liệu không hợp lệ"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Không có quyền Admin")
    })
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<NewsDTO> create(@Valid @RequestBody NewsCreateRequest request) {
        News created = newsService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(mapToDTO(created));
    }

    @Operation(summary = "Cập nhật tin tức (Admin)")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cập nhật tin tức thành công"),
            @ApiResponse(responseCode = "400", description = "Dữ liệu không hợp lệ"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Không có quyền Admin"),
            @ApiResponse(responseCode = "404", description = "Không tìm thấy tin tức để cập nhật")
    })
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<NewsDTO> update(@PathVariable Integer id, @Valid @RequestBody NewsUpdateRequest request) {
        News updated = newsService.update(id, request);
        return ResponseEntity.ok(mapToDTO(updated));
    }

    @Operation(summary = "Xóa tin tức (Admin)")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Xóa tin tức thành công"),
            @ApiResponse(responseCode = "401", description = "Chưa xác thực"),
            @ApiResponse(responseCode = "403", description = "Không có quyền Admin"),
            @ApiResponse(responseCode = "404", description = "Không tìm thấy tin tức để xóa")
    })
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> delete(@PathVariable Integer id) {
        newsService.delete(id);
        return ResponseEntity.ok(Map.of("success", true, "message", "Xóa tin tức thành công"));
    }

    private NewsDTO mapToDTO(News n) {
        return NewsDTO.builder()
                .id(n.getId())
                .title(n.getTitle())
                .content(n.getContent())
                .imageUrl(n.getImageUrl())
                .category(n.getCategory())
                .publishedDate(n.getPublishedDate())
                .build();
    }
}

