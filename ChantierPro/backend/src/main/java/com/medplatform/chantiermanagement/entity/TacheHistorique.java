package com.medplatform.chantiermanagement.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "tache_historique")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TacheHistorique {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tache_id", nullable = false)
    private Long tacheId;

    @Column(name = "utilisateur_id")
    private Long utilisateurId;

    @Column(name = "action", nullable = false, length = 100)
    private String action;

    @Column(name = "ancienne_valeur", columnDefinition = "TEXT")
    private String ancienneValeur;

    @Column(name = "nouvelle_valeur", columnDefinition = "TEXT")
    private String nouvelleValeur;

    @Column(name = "auteur", length = 255)
    private String auteur;

    @Column(name = "date_action")
    private LocalDateTime dateAction;
}