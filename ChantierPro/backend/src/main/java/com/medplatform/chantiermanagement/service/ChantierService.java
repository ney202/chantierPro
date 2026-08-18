package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.dto.ChantierRequest;
import com.medplatform.chantiermanagement.dto.ChantierResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.entity.Rapport;
import com.medplatform.chantiermanagement.entity.Tache;
import com.medplatform.chantiermanagement.entity.Utilisateur;
import com.medplatform.chantiermanagement.exception.ChantierNotFoundException;
import com.medplatform.chantiermanagement.repository.AffectationRepository;
import com.medplatform.chantiermanagement.repository.AlerteRepository;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.repository.DepenseRepository;
import com.medplatform.chantiermanagement.repository.PhotoRepository;
import com.medplatform.chantiermanagement.repository.RapportRepository;
import com.medplatform.chantiermanagement.repository.TacheHistoriqueRepository;
import com.medplatform.chantiermanagement.repository.TacheRepository;
import com.medplatform.chantiermanagement.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChantierService {

    private final ChantierRepository chantierRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final TacheRepository tacheRepository;
    private final DepenseRepository depenseRepository;
    private final RapportRepository rapportRepository;
    private final PhotoRepository photoRepository;
    private final TacheHistoriqueRepository tacheHistoriqueRepository;
    private final AlerteRepository alerteRepository;
    private final AffectationRepository affectationRepository;

    @Transactional
    public ChantierResponse create(ChantierRequest request) {
        Utilisateur chef = request.getChefId() != null ? resolveChef(request.getChefId()) : null;

        Chantier chantier = Chantier.builder()
                .nom(request.getNom())
                .localisation(request.getLocalisation())
                .description(request.getDescription())
                .client(request.getClient())
                .devise(request.getDevise())
                .dateDebut(request.getDateDebut())
                .dateFinPrevue(request.getDateFinPrevue())
                .dateDebutReelle(null)
                .dateFinReelle(null)
                .budget(request.getBudget())
                .statut("planifie")
                .avancement(0)
                .suspendu(false)
                .chef(chef)
                // === NOUVEAUX CHAMPS GÉOLOCALISATION V2 ===
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .adresseComplete(request.getAdresseComplete())
                // ===========================================
                .build();

        return toResponse(chantierRepository.save(chantier));
    }

    public List<ChantierResponse> getAll() {
        return chantierRepository.findAll().stream()
                .map(this::verifierEtRecalculer)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Page<ChantierResponse> getAllPaged(Pageable pageable) {
        return chantierRepository.findAll(pageable)
                .map(this::verifierEtRecalculer)
                .map(this::toResponse);
    }

    public List<ChantierResponse> search(String nom, String statut) {
        return chantierRepository.search(nom, statut).stream()
                .map(this::verifierEtRecalculer)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public ChantierResponse getById(Long id) {
        return toResponse(verifierEtRecalculer(findOrThrow(id)));
    }

    private Chantier verifierEtRecalculer(Chantier chantier) {
        recalculerStatutEtAvancement(chantier.getId());
        return findOrThrow(chantier.getId());
    }

    @Transactional
    public ChantierResponse update(Long id, ChantierRequest request) {
        Chantier chantier = findOrThrow(id);
        Utilisateur chef = request.getChefId() != null ? resolveChef(request.getChefId()) : null;

        chantier.setNom(request.getNom());
        chantier.setLocalisation(request.getLocalisation());
        chantier.setDescription(request.getDescription());
        chantier.setClient(request.getClient());
        chantier.setDevise(request.getDevise());
        chantier.setDateDebut(request.getDateDebut());
        chantier.setDateFinPrevue(request.getDateFinPrevue());
        chantier.setBudget(request.getBudget());
        chantier.setChef(chef);
        // === NOUVEAUX CHAMPS GÉOLOCALISATION V2 ===
        chantier.setLatitude(request.getLatitude());
        chantier.setLongitude(request.getLongitude());
        chantier.setAdresseComplete(request.getAdresseComplete());
        // ===========================================

        return toResponse(chantierRepository.save(chantier));
    }

    @Transactional
    public ChantierResponse demarrer(Long id) {
        Chantier chantier = findOrThrow(id);
        if (Boolean.TRUE.equals(chantier.getSuspendu())) {
            throw new RuntimeException("Impossible de démarrer un chantier suspendu");
        }
        if ("termine".equals(chantier.getStatut())) {
            throw new RuntimeException("Le chantier est déjà terminé");
        }

        chantier.setDateDebutReelle(LocalDate.now());
        chantier.setStatut("en_cours");
        chantier.setSuspendu(false);
        return toResponse(chantierRepository.save(chantier));
    }

    @Transactional
    public ChantierResponse terminer(Long id) {
        Chantier chantier = findOrThrow(id);
        if (Boolean.TRUE.equals(chantier.getSuspendu())) {
            throw new RuntimeException("Impossible de terminer un chantier suspendu");
        }
        if ("termine".equals(chantier.getStatut())) {
            throw new RuntimeException("Le chantier est déjà terminé");
        }

        chantier.setDateFinReelle(LocalDate.now());
        chantier.setAvancement(100);
        chantier.setStatut("termine");
        chantier.setSuspendu(false);
        return toResponse(chantierRepository.save(chantier));
    }

    @Transactional
    public ChantierResponse suspendre(Long id) {
        Chantier chantier = findOrThrow(id);
        if ("termine".equals(chantier.getStatut())) {
            throw new RuntimeException("Impossible de suspendre un chantier terminé");
        }
        if (Boolean.TRUE.equals(chantier.getSuspendu())) {
            throw new RuntimeException("Le chantier est déjà suspendu");
        }
        chantier.setSuspendu(true);
        return toResponse(chantierRepository.save(chantier));
    }

    @Transactional
    public ChantierResponse reprendre(Long id) {
        Chantier chantier = findOrThrow(id);
        if (!Boolean.TRUE.equals(chantier.getSuspendu())) {
            throw new RuntimeException("Le chantier n'est pas suspendu");
        }
        chantier.setSuspendu(false);
        recalculerStatutEtAvancement(id);
        return toResponse(findOrThrow(id));
    }

    @Transactional
    public void recalculerStatutEtAvancement(Long chantierId) {
        Chantier chantier = findOrThrow(chantierId);
        List<Tache> taches = tacheRepository.findByChantierId(chantierId);

        if (taches.isEmpty()) {
            if ("termine".equals(chantier.getStatut()) || Boolean.TRUE.equals(chantier.getSuspendu())) {
                chantierRepository.save(chantier);
                return;
            }

            if (chantier.getDateDebutReelle() != null && chantier.getDateFinPrevue() != null
                    && LocalDate.now().isAfter(chantier.getDateFinPrevue())) {
                chantier.setStatut("retard");
            } else if (chantier.getDateDebutReelle() != null) {
                chantier.setStatut("en_cours");
            } else {
                chantier.setStatut("planifie");
            }
            chantier.setAvancement(0);
            chantierRepository.save(chantier);
            return;
        }

        int total = taches.size();
        int terminees = (int) taches.stream()
                .filter(t -> "termine".equals(t.getStatut())).count();
        int enRetard = (int) taches.stream()
                .filter(t -> "retard".equals(t.getStatut()) && !Boolean.TRUE.equals(t.getSuspendu())).count();
        int enCours = (int) taches.stream()
                .filter(t -> "en_cours".equals(t.getStatut()) && !Boolean.TRUE.equals(t.getSuspendu())).count();
        int enAttention = (int) taches.stream()
                .filter(t -> "attention".equals(t.getStatut()) && !Boolean.TRUE.equals(t.getSuspendu())).count();

        int avancementTotal = taches.stream()
                .mapToInt(t -> t.getAvancement() != null ? t.getAvancement() : 0)
                .sum();
        chantier.setAvancement(avancementTotal / total);

        if (terminees == total) {
            chantier.setStatut("termine");
            if (chantier.getDateFinReelle() == null) {
                chantier.setDateFinReelle(LocalDate.now());
            }
        } else if (enRetard > 0) {
            chantier.setStatut("retard");
        } else if (enCours > 0) {
            chantier.setStatut("en_cours");
        } else if (enAttention > 0) {
            chantier.setStatut("attention");
        } else if (chantier.getDateDebutReelle() != null) {
            chantier.setStatut("en_cours");
        } else {
            chantier.setStatut("planifie");
        }

        if (chantier.getDateFinPrevue() != null
                && LocalDate.now().isAfter(chantier.getDateFinPrevue())
                && !"termine".equals(chantier.getStatut())) {
            chantier.setStatut("retard");
        }

        chantierRepository.save(chantier);
    }

    @Transactional
    public void delete(Long id) {
        Chantier chantier = findOrThrow(id);

        // 1. Supprimer les affectations liées (utilisateurs assignés au chantier)
        affectationRepository.deleteByChantierId(id);

        // 2. Supprimer les dépenses liées
        depenseRepository.deleteByChantierId(id);

        // 3. Supprimer les alertes liées
        alerteRepository.deleteByChantierId(id);

        // 4. Supprimer les rapports liés (et leurs photos)
        List<Rapport> rapports = rapportRepository.findByChantierId(id);
        for (Rapport rapport : rapports) {
            photoRepository.deleteByRapportId(rapport.getId());
        }
        rapportRepository.deleteByChantierId(id);

        // 5. Supprimer les tâches liées (et leur historique)
        List<Tache> taches = tacheRepository.findByChantierId(id);
        for (Tache tache : taches) {
            tacheHistoriqueRepository.deleteByTacheId(tache.getId());
        }
        tacheRepository.deleteByChantierId(id);

        // 6. Supprimer le chantier
        chantierRepository.deleteById(id);
    }

    private Chantier findOrThrow(Long id) {
        return chantierRepository.findById(id)
                .orElseThrow(() -> new ChantierNotFoundException(id));
    }

    private Utilisateur resolveChef(Long chefId) {
        return utilisateurRepository.findById(chefId)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé avec l'id : " + chefId));
    }

    private ChantierResponse toResponse(Chantier chantier) {
        List<Tache> taches = tacheRepository.findByChantierId(chantier.getId());
        long total = taches.size();
        long terminees = taches.stream().filter(t -> "termine".equals(t.getStatut())).count();
        long enCours = taches.stream().filter(t -> "en_cours".equals(t.getStatut())).count();
        long planifiees = taches.stream().filter(t -> "planifie".equals(t.getStatut())).count();
        long retards = taches.stream().filter(t -> "retard".equals(t.getStatut())).count();

        boolean isTermine = "termine".equals(chantier.getStatut());
        boolean isSuspendu = Boolean.TRUE.equals(chantier.getSuspendu());
        boolean hasStarted = chantier.getDateDebutReelle() != null;

        return ChantierResponse.builder()
                .id(chantier.getId())
                .nom(chantier.getNom())
                .localisation(chantier.getLocalisation())
                .description(chantier.getDescription())
                .client(chantier.getClient())
                .devise(chantier.getDevise())
                .dateDebut(chantier.getDateDebut())
                .dateFinPrevue(chantier.getDateFinPrevue())
                .dateDebutReelle(chantier.getDateDebutReelle())
                .dateFinReelle(chantier.getDateFinReelle())
                .budget(chantier.getBudget())
                .statut(chantier.getStatut())
                .avancement(chantier.getAvancement())
                .suspendu(chantier.getSuspendu())
                .chefId(chantier.getChef() != null ? chantier.getChef().getId() : null)
                .chefNom(chantier.getChef() != null ? chantier.getChef().getNom() : null)
                // === NOUVEAUX CHAMPS GÉOLOCALISATION V2 ===
                .latitude(chantier.getLatitude())
                .longitude(chantier.getLongitude())
                .adresseComplete(chantier.getAdresseComplete())
                // ===========================================
                .nbTachesTotal(total)
                .nbTachesTerminees(terminees)
                .nbTachesEnCours(enCours)
                .nbTachesPlanifiees(planifiees)
                .nbTachesRetard(retards)
                .canDemarrer("planifie".equals(chantier.getStatut()) && !isSuspendu && !hasStarted)
                .canTerminer(hasStarted && !isTermine && !isSuspendu && total > 0 && terminees == total)
                .isEnRetard("retard".equals(chantier.getStatut()))
                .joursRetard("retard".equals(chantier.getStatut()) && chantier.getDateFinPrevue() != null
                        ? ChronoUnit.DAYS.between(chantier.getDateFinPrevue(), LocalDate.now()) : 0L)
                .isAttention("attention".equals(chantier.getStatut()))
                .build();
    }
}