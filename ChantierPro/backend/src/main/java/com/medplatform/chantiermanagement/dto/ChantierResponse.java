package com.medplatform.chantiermanagement.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChantierResponse {

    private Long id;
    private String nom;
    private String localisation;
    private String description;
    private String client;
    private String devise;
    private LocalDate dateDebut;
    private LocalDate dateFinPrevue;
    private LocalDate dateDebutReelle;
    private LocalDate dateFinReelle;
    private BigDecimal budget;
    private String statut;
    private Integer avancement;
    private Boolean suspendu;
    private Long chefId;
    private String chefNom;

    // === NOUVEAUX CHAMPS GÉOLOCALISATION V2 ===
    private Double latitude;
    private Double longitude;
    private String adresseComplete;
    // ===========================================

    // Stats tâches
    private Long nbTachesTotal;
    private Long nbTachesTerminees;
    private Long nbTachesEnCours;
    private Long nbTachesPlanifiees;
    private Long nbTachesRetard;

    // Flags frontend
    private Boolean canDemarrer;
    private Boolean canTerminer;
    private Boolean isEnRetard;
    private Long joursRetard;
    private Boolean isAttention;

    public Long getJoursRetard() {
        if ("retard".equals(statut) && dateFinPrevue != null) {
            return ChronoUnit.DAYS.between(dateFinPrevue, LocalDate.now());
        }
        return 0L;
    }

    public Boolean getIsAttention() {
        if ("termine".equals(statut) || "retard".equals(statut) || Boolean.TRUE.equals(suspendu)) return false;
        if (dateFinPrevue == null) return false;
        long days = ChronoUnit.DAYS.between(LocalDate.now(), dateFinPrevue);
        return days >= 0 && days <= 3;
    }
}