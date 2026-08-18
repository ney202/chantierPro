package com.medplatform.chantiermanagement.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class DepenseRequest {

    @NotNull(message = "Le montant est obligatoire")
    private BigDecimal montant;

    private String description;

    private LocalDate dateDepense;

    @NotNull(message = "Le chantier est obligatoire")
    private Long chantierId;
}
