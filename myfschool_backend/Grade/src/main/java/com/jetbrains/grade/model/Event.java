package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "Events")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "EventID")
    private Integer id;

    @Column(name = "Title", nullable = false, length = 200)
    private String title;

    @Column(name = "Description", length = 1000)
    private String description;

    @Column(name = "StartAt")
    private LocalDateTime startAt;

    @Column(name = "EndAt")
    private LocalDateTime endAt;

    @Column(name = "Location", length = 255)
    private String location;

    @Column(name = "Category", length = 50)
    private String category;

    @Column(name = "Status", length = 50)
    private String status;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "BannerFileID")
    private FileEntity bannerFile;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "CreatedByUserID")
    private User createdBy;
}
