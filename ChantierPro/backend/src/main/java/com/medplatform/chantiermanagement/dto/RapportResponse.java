package com.medplatform.chantiermanagement.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class RapportResponse {

    private Long id;
    private String contenu;
    private LocalDate dateRapport;
    private Long chantierId;
    private Long auteurId;
}
