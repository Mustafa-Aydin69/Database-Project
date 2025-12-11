package com.airportservices.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Entity
@Table(name = "GeneralCommon_Roles")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GeneralCommon_Roles {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "RoleID")
    private Integer roleID;

    @Column(name = "RoleName", nullable = false, length = 50)
    private String roleName;
}

