package com.jetbrains.grade.controller;

import com.jetbrains.grade.dto.NewsDTO;
import com.jetbrains.grade.model.News;
import com.jetbrains.grade.service.NewsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/news")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class NewsController {

    private final NewsService newsService;

    @GetMapping
    public ResponseEntity<List<NewsDTO>> getAll() {
        List<NewsDTO> list = newsService.getActiveNews().stream()
                .map(n -> NewsDTO.builder()
                        .id(n.getId())
                        .title(n.getTitle())
                        .content(n.getContent())
                        .imageUrl(n.getImageUrl())
                        .category(n.getCategory())
                        .publishedDate(n.getPublishedDate())
                        .build())
                .toList();
        return ResponseEntity.ok(list);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Integer id) {
        return newsService.getById(id)
                .map(n -> ResponseEntity.ok(NewsDTO.builder()
                        .id(n.getId())
                        .title(n.getTitle())
                        .content(n.getContent())
                        .imageUrl(n.getImageUrl())
                        .category(n.getCategory())
                        .publishedDate(n.getPublishedDate())
                        .build()))
                .orElse(ResponseEntity.status(HttpStatus.NOT_FOUND).build());
    }

    @PostMapping
    public ResponseEntity<News> create(@RequestBody News news) {
        return ResponseEntity.status(HttpStatus.CREATED).body(newsService.create(news));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> update(@PathVariable Integer id, @RequestBody News news) {
        try {
            return ResponseEntity.ok(newsService.update(id, news));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Integer id) {
        newsService.delete(id);
        return ResponseEntity.ok(Map.of("success", true));
    }
}
