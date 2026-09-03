package com.jetbrains.grade.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "RewardDisciplineTypes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RewardDisciplineType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "TypeID")
    private Integer id;

    @Column(name = "TypeCode", nullable = false, length = 50)
    private String typeCode;

    @Column(name = "TypeName", nullable = false, length = 100)
    private String typeName;

    @Column(name = "GroupName", nullable = false, length = 50)
    private String groupName;
    
    @Column(name = "IsActive")
    private Boolean isActive = true;
}
