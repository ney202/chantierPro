package com.medplatform.chantiermanagement.dto;

import lombok.Builder;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Builder
public class TacheHistoriqueResponse {
    private Long id;
    private Long tacheId;
    private LocalDateTime dateAction;
    private String action;
    private String ancienneValeur;
    private String nouvelleValeur;
    private String utilisateurNom;
}