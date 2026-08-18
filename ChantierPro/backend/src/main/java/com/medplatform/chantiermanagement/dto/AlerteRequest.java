package com.medplatform.chantiermanagement.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AlerteRequest {

    @NotBlank(message = "Le message est obligatoire")
    private String message;

    private LocalDateTime dateCreation;

    private String statut;

    private Boolean lu;

    @NotNull(message = "Le chantier est obligatoire")
    private Long chantierId;
}