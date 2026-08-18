package com.medplatform.chantiermanagement.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Entity
@Table(name = "chantier")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Chantier {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nom", nullable = false, length = 100)
    private String nom;

    @Column(name = "localisation", nullable = false)
    private String localisation;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "client", length = 100)
    private String client;

    @Column(name = "devise", length = 10)
    private String devise;

    @Column(name = "date_debut")
    private LocalDate dateDebut;

    @Column(name = "date_fin_prevue")
    private LocalDate dateFinPrevue;

    @Column(name = "date_debut_reelle")
    private LocalDate dateDebutReelle;

    @Column(name = "date_fin_reelle")
    private LocalDate dateFinReelle;

    @Column(name = "budget", precision = 15, scale = 2)
    private BigDecimal budget;

    @Column(name = "statut", length = 50)
    @Builder.Default
    private String statut = "planifie";

    @Column(name = "avancement")
    @Builder.Default
    private Integer avancement = 0;

    @Column(name = "suspendu")
    @Builder.Default
    private Boolean suspendu = false;

    // === NOUVEAUX CHAMPS GÉOLOCALISATION V2 ===
    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "adresse_complete", length = 255)
    private String adresseComplete;
    // ===========================================

    @ToString.Exclude
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "chef_id")
    private Utilisateur chef;

    @ToString.Exclude
    @OneToMany(mappedBy = "chantier", fetch = FetchType.LAZY)
    private List<Tache> taches;
}