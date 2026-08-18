package com.medplatform.chantiermanagement.dto;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
public class DepenseResponse {

    private Long id;
    private BigDecimal montant;
    private String description;
    private LocalDate dateDepense;
    private Long chantierId;
}
