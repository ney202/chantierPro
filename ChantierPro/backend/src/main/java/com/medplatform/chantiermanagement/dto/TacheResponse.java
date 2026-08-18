package com.medplatform.chantiermanagement.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@Data
@Builder
public class TacheResponse {

    private Long id;
    private String titre;
    private String description;
    private LocalDate dateDebut;
    private LocalDate dateFin;
    private LocalDate dateDebutReelle;
    private LocalDate dateFinReelle;
    private String statut;
    private Integer avancement;
    private String priorite;
    private String categorie;
    private Long chantierId;
    private String chantierNom;
    private Boolean suspendu;
    private Long joursRetard;
    private Boolean alerteEcheance;
    
    // Flags calculés pour le frontend
    private Boolean canDemarrer;
    private Boolean canTerminer;
    private Boolean canUpdateAvancement;
    private Boolean isEnRetard;
    private Boolean isAttention;

    public Long getJoursRetard() {
        if ("retard".equals(statut) && dateFin != null) {
            return ChronoUnit.DAYS.between(dateFin, LocalDate.now());
        }
        return 0L;
    }

    public Boolean getAlerteEcheance() {
        if (dateFin == null || "termine".equals(statut) || "retard".equals(statut)) return false;
        long daysUntil = ChronoUnit.DAYS.between(LocalDate.now(), dateFin);
        return daysUntil >= 0 && daysUntil <= 3;
    }
}