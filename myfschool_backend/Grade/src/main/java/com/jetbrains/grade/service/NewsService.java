package com.jetbrains.grade.service;

import com.jetbrains.grade.dto.NewsCreateRequest;
import com.jetbrains.grade.dto.NewsUpdateRequest;
import com.jetbrains.grade.model.News;
import com.jetbrains.grade.repository.NewsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class NewsService {

    private final NewsRepository newsRepository;

    @Transactional(readOnly = true)
    public List<News> getActiveNews() {
        return newsRepository.findByIsActiveTrueOrderByPublishedDateDesc();
    }

    @Transactional(readOnly = true)
    public Page<News> getActiveNews(Pageable pageable) {
        return newsRepository.findByIsActiveTrue(pageable);
    }

    @Transactional(readOnly = true)
    public Optional<News> getById(Integer id) {
        return newsRepository.findById(id);
    }

    @Transactional
    public News create(NewsCreateRequest request) {
        News news = News.builder()
                .title(request.getTitle())
                .content(request.getContent())
                .imageUrl(request.getImageUrl())
                .category(request.getCategory())
                .publishedDate(request.getPublishedDate() != null ? request.getPublishedDate() : LocalDateTime.now())
                .isActive(true)
                .build();
        return newsRepository.save(news);
    }

    @Transactional
    public News update(Integer id, NewsUpdateRequest request) {
        News existing = newsRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Không tìm thấy tin tức với ID: " + id));

        existing.setTitle(request.getTitle());
        existing.setContent(request.getContent());
        existing.setImageUrl(request.getImageUrl());
        existing.setCategory(request.getCategory());
        if (request.getPublishedDate() != null) {
            existing.setPublishedDate(request.getPublishedDate());
        }
        if (request.getIsActive() != null) {
            existing.setIsActive(request.getIsActive());
        }

        return newsRepository.save(existing);
    }

    @Transactional
    public void delete(Integer id) {
        if (!newsRepository.existsById(id)) {
            throw new NoSuchElementException("Không tìm thấy tin tức với ID: " + id);
        }
        newsRepository.deleteById(id);
    }
}
