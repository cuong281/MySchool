package com.jetbrains.grade.service;

import com.jetbrains.grade.model.RefreshToken;
import com.jetbrains.grade.model.User;
import com.jetbrains.grade.repository.RefreshTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;

    @Value("${jwt.refresh-token-expiration-ms:604800000}")
    private long refreshTokenExpirationMs; // Default 7 days

    /**
     * Hashes a raw refresh token using SHA-256 to ensure plaintext is never stored in DB.
     */
    public String hashToken(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not available", e);
        }
    }

    /**
     * Creates a new RefreshToken for the user, stores the SHA-256 hash in DB, and returns the raw token.
     */
    @Transactional
    public String createRefreshToken(User user) {
        String rawToken = UUID.randomUUID().toString() + "-" + UUID.randomUUID().toString();
        String tokenHash = hashToken(rawToken);

        LocalDateTime expiryDate = LocalDateTime.now().plusSeconds(refreshTokenExpirationMs / 1000);

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .tokenHash(tokenHash)
                .expiryDate(expiryDate)
                .isRevoked(false)
                .createdAt(LocalDateTime.now())
                .build();

        refreshTokenRepository.save(refreshToken);
        return rawToken;
    }

    /**
     * Validates raw token, ensures it exists in DB, is not revoked, and has not expired.
     */
    @Transactional(readOnly = true)
    public RefreshToken verifyRefreshToken(String rawToken) {
        String tokenHash = hashToken(rawToken);
        Optional<RefreshToken> tokenOpt = refreshTokenRepository.findByTokenHash(tokenHash);

        if (tokenOpt.isEmpty()) {
            throw new IllegalArgumentException("Refresh token khong hop le");
        }

        RefreshToken refreshToken = tokenOpt.get();

        if (Boolean.TRUE.equals(refreshToken.getIsRevoked())) {
            throw new IllegalArgumentException("Refresh token da bi thu hoi (revoked)");
        }

        if (refreshToken.getExpiryDate().isBefore(LocalDateTime.now())) {
            throw new IllegalArgumentException("Refresh token da het han");
        }

        return refreshToken;
    }

    /**
     * Rotates refresh token: revokes old token and generates a new one for the user.
     */
    @Transactional
    public String rotateRefreshToken(RefreshToken oldRefreshToken) {
        oldRefreshToken.setIsRevoked(true);
        refreshTokenRepository.save(oldRefreshToken);

        return createRefreshToken(oldRefreshToken.getUser());
    }

    /**
     * Revokes a specific refresh token (for logout).
     */
    @Transactional
    public void revokeRefreshToken(String rawToken) {
        String tokenHash = hashToken(rawToken);
        refreshTokenRepository.findByTokenHash(tokenHash).ifPresent(token -> {
            token.setIsRevoked(true);
            refreshTokenRepository.save(token);
        });
    }

    /**
     * Revokes all refresh tokens for a user.
     */
    @Transactional
    public void revokeAllUserTokens(Integer userId) {
        refreshTokenRepository.revokeAllByUserId(userId);
    }
}
