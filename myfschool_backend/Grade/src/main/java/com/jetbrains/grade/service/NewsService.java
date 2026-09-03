package com.jetbrains.grade.service;

import com.jetbrains.grade.model.News;
import com.jetbrains.grade.repository.NewsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class NewsService {

    private final NewsRepository newsRepository;

    public List<News> getActiveNews() {
        return newsRepository.findByIsActiveTrueOrderByPublishedDateDesc();
    }

    public Optional<News> getById(Integer id) {
        return newsRepository.findById(id);
    }

    public News create(News news) {
        news.setId(null);
        news.setIsActive(true);
        if (news.getPublishedDate() == null) {
            news.setPublishedDate(LocalDateTime.now());
        }
        return newsRepository.save(news);
    }

    public News update(Integer id, News updated) {
        News existing = newsRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("News not found"));
        
        existing.setTitle(updated.getTitle());
        existing.setContent(updated.getContent());
        existing.setImageUrl(updated.getImageUrl());
        existing.setCategory(updated.getCategory());
        existing.setPublishedDate(updated.getPublishedDate());
        existing.setIsActive(updated.getIsActive());
        
        return newsRepository.save(existing);
    }

    public void delete(Integer id) {
        newsRepository.deleteById(id);
    }
}
