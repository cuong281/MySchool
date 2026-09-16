package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.News;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NewsRepository extends JpaRepository<News, Integer> {
    List<News> findByIsActiveTrueOrderByPublishedDateDesc();
    Page<News> findByIsActiveTrue(Pageable pageable);
}
