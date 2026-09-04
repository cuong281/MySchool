package com.jetbrains.grade.repository;

import com.jetbrains.grade.model.UserDeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserDeviceTokenRepository extends JpaRepository<UserDeviceToken, Integer> {

    List<UserDeviceToken> findByUserId(Integer userId);

    Optional<UserDeviceToken> findByUserIdAndDeviceToken(Integer userId, String deviceToken);

    void deleteByDeviceToken(String deviceToken);

    void deleteByUserIdAndDeviceToken(Integer userId, String deviceToken);
}
