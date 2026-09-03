package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "Files")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FileEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "FileID")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "UploadedByUserID")
    private User uploadedBy;

    @Column(name = "FileName", nullable = false, length = 255)
    private String fileName;

    @Column(name = "FileUrl", nullable = false, length = 500)
    private String fileUrl;

    @Column(name = "FileType", length = 50)
    private String fileType;

    @Column(name = "FileSize")
    private Long fileSize;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt = LocalDateTime.now();
}
