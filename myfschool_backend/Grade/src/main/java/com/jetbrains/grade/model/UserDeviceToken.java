package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "UserDeviceTokens")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserDeviceToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "TokenID")
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "UserID", nullable = false)
    private User user;

    @Column(name = "DeviceToken", nullable = false, length = 500)
    private String deviceToken;

    @Column(name = "DeviceType", nullable = false, length = 20)
    private String deviceType = "ANDROID";

    @Column(name = "LastActiveAt")
    private LocalDateTime lastActiveAt;

    @Column(name = "CreatedAt")
    private LocalDateTime createdAt;
}
