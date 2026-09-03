package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "Roles")
@Data
@EqualsAndHashCode(exclude = "users")
@NoArgsConstructor
@AllArgsConstructor
public class Role {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "RoleID")
    private Integer id;

    @Column(name = "RoleName", nullable = false, unique = true, length = 50)
    private String roleName; // E.g., "ROLE_ADMIN", "ROLE_STUDENT"

    @Column(name = "IsActive")
    private Boolean isActive = true;

    @ManyToMany(mappedBy = "roles")
    private Set<User> users = new HashSet<>();
}
