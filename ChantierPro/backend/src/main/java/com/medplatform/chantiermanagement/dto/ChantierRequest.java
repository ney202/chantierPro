package com.medplatform.chantiermanagement.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class ChantierRequest {

    @NotBlank(message = "Le nom est obligatoire")
    private String nom;

    @NotBlank(message = "La localisation est obligatoire")
    private String localisation;

    private String description;
    private String client;
    private String devise;

    private LocalDate dateDebut;
    private LocalDate dateFinPrevue;

    @NotNull(message = "Le budget est obligatoire")
    @DecimalMin(value = "0.0", inclusive = false, message = "Le budget doit être supérieur à 0")
    private BigDecimal budget;

    private Long chefId;

    // === NOUVEAUX CHAMPS GÉOLOCALISATION V2 ===
    private Double latitude;
    private Double longitude;
    private String adresseComplete;
    // ===========================================
}