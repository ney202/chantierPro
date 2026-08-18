package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.dto.TacheRequest;
import com.medplatform.chantiermanagement.dto.TacheResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.entity.Tache;
import com.medplatform.chantiermanagement.entity.TacheHistorique;
import com.medplatform.chantiermanagement.exception.ChantierNotFoundException;
import com.medplatform.chantiermanagement.exception.TacheNotFoundException;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.repository.TacheHistoriqueRepository;
import com.medplatform.chantiermanagement.repository.TacheRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TacheService {

    private final TacheRepository tacheRepository;
    private final ChantierRepository chantierRepository;
    private final ChantierService chantierService;
    private final TacheHistoriqueService historiqueService;
    private final TacheHistoriqueRepository tacheHistoriqueRepository;

    @Transactional
    public TacheResponse create(TacheRequest request) {
        Chantier chantier = resolveChantier(request.getChantierId());

        Tache tache = Tache.builder()
                .titre(request.getTitre())
                .description(request.getDescription())
                .dateDebut(request.getDateDebut())
                .dateFin(request.getDateFin())
                .dateDebutReelle(null)
                .dateFinReelle(null)
                .avancement(0)
                .priorite(request.getPriorite() != null ? request.getPriorite().toLowerCase() : "normale")
                .categorie(request.getCategorie() != null ? request.getCategorie().toLowerCase() : null)
                .statut("planifie")
                .chantier(chantier)
                .suspendu(false)
                .build();

        Tache saved = tacheRepository.save(tache);
        chantierService.recalculerStatutEtAvancement(chantier.getId());

        historiqueService.enregistrer(saved.getId(), "CREATION", null, saved.getTitre(), "Système");

        return toResponse(saved);
    }

    public List<TacheResponse> getAll() {
        return tacheRepository.findAll()
                .stream()
                .map(this::verifierEtMettreAJourStatut)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Page<TacheResponse> getAllPaged(Pageable pageable) {
        return tacheRepository.findAll(pageable)
                .map(this::verifierEtMettreAJourStatut)
                .map(this::toResponse);
    }

    public List<TacheResponse> search(String statut, Long chantierId) {
        return tacheRepository.search(statut, chantierId)
                .stream()
                .map(this::verifierEtMettreAJourStatut)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public List<TacheResponse> getByChantier(Long chantierId) {
        return tacheRepository.findByChantierId(chantierId)
                .stream()
                .map(this::verifierEtMettreAJourStatut)
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public TacheResponse getById(Long id) {
        Tache tache = findOrThrow(id);
        tache = verifierEtMettreAJourStatut(tache);
        return toResponse(tache);
    }

    private Tache verifierEtMettreAJourStatut(Tache tache) {
        if ("termine".equals(tache.getStatut()) || Boolean.TRUE.equals(tache.getSuspendu())) {
            return tache;
        }
        
        String nouveauStatut = calculerStatut(
                tache.getDateDebutReelle(),
                tache.getDateDebut(),
                tache.getDateFin(),
                tache.getAvancement()
        );
        
        if (!nouveauStatut.equals(tache.getStatut())) {
            tache.setStatut(nouveauStatut);
            tache = tacheRepository.save(tache);
        }
        return tache;
    }

    @Transactional
    public TacheResponse update(Long id, TacheRequest request) {
        Tache tache = findOrThrow(id);
        Chantier chantier = resolveChantier(request.getChantierId());

        String oldValue = tache.getTitre();
        tache.setTitre(request.getTitre());
        tache.setDescription(request.getDescription());
        tache.setDateDebut(request.getDateDebut());
        tache.setDateFin(request.getDateFin());
        tache.setPriorite(request.getPriorite() != null ? request.getPriorite().toLowerCase() : tache.getPriorite());
        tache.setCategorie(request.getCategorie() != null ? request.getCategorie().toLowerCase() : tache.getCategorie());
        tache.setChantier(chantier);
        
        if (!Boolean.TRUE.equals(tache.getSuspendu()) && !"termine".equals(tache.getStatut())) {
            tache.setStatut(calculerStatut(tache.getDateDebutReelle(), tache.getDateDebut(), tache.getDateFin(), tache.getAvancement()));
        }
        
        Tache saved = tacheRepository.save(tache);
        chantierService.recalculerStatutEtAvancement(chantier.getId());
        
        historiqueService.enregistrer(saved.getId(), "MODIFICATION", oldValue, saved.getTitre(), "Système");
        
        return toResponse(saved);
    }

    @Transactional
    public TacheResponse demarrer(Long id) {
        Tache tache = findOrThrow(id);
        if (Boolean.TRUE.equals(tache.getSuspendu())) {
            throw new RuntimeException("Impossible de démarrer une tâche suspendue");
        }
        if ("termine".equals(tache.getStatut())) {
            throw new RuntimeException("La tâche est déjà terminée");
        }

        tache.setDateDebutReelle(LocalDate.now());
        tache.setAvancement(0);
        tache.setStatut("en_cours");
        tache.setSuspendu(false);
        
        Tache saved = tacheRepository.save(tache);
        chantierService.recalculerStatutEtAvancement(tache.getChantier().getId());
        
        historiqueService.enregistrer(saved.getId(), "DEMARRAGE", null, 
                saved.getDateDebutReelle().toString(), "Système");
        
        return toResponse(saved);
    }

    @Transactional
    public TacheResponse mettreAJourAvancement(Long id, Integer avancement) {
        Tache tache = findOrThrow(id);
        if (Boolean.TRUE.equals(tache.getSuspendu())) {
            throw new RuntimeException("Impossible de modifier l'avancement d'une tâche suspendue");
        }
        if ("termine".equals(tache.getStatut())) {
            throw new RuntimeException("Impossible de modifier l'avancement d'une tâche terminée");
        }

        int oldAvancement = tache.getAvancement() != null ? tache.getAvancement() : 0;
        int newAvancement = Math.max(0, Math.min(100, avancement));
        tache.setAvancement(newAvancement);
        
        if (newAvancement >= 100) {
            tache.setDateFinReelle(LocalDate.now());
            tache.setStatut("termine");
        } else {
            tache.setStatut(calculerStatut(tache.getDateDebutReelle(), tache.getDateDebut(), tache.getDateFin(), tache.getAvancement()));
        }
        
        Tache saved = tacheRepository.save(tache);
        chantierService.recalculerStatutEtAvancement(tache.getChantier().getId());
        
        historiqueService.enregistrer(saved.getId(), "AVANCEMENT", 
                oldAvancement + "%", saved.getAvancement() + "%", "Système");
        
        return toResponse(saved);
    }

    @Transactional
    public TacheResponse terminer(Long id) {
        Tache tache = findOrThrow(id);
        if (Boolean.TRUE.equals(tache.getSuspendu())) {
            throw new RuntimeException("Impossible de terminer une tâche suspendue");
        }
        if ("termine".equals(tache.getStatut())) {
            throw new RuntimeException("La tâche est déjà terminée");
        }

        tache.setDateFinReelle(LocalDate.now());
        tache.setAvancement(100);
        tache.setStatut("termine");
        tache.setSuspendu(false);
        
        Tache saved = tacheRepository.save(tache);
        chantierService.recalculerStatutEtAvancement(tache.getChantier().getId());
        
        historiqueService.enregistrer(saved.getId(), "TERMINAISON", null, 
                saved.getDateFinReelle().toString(), "Système");
        
        return toResponse(saved);
    }

    @Transactional
    public TacheResponse suspendre(Long id) {
        Tache tache = findOrThrow(id);
        if ("termine".equals(tache.getStatut())) {
            throw new RuntimeException("Impossible de suspendre une tâche terminée");
        }
        if (Boolean.TRUE.equals(tache.getSuspendu())) {
            throw new RuntimeException("La tâche est déjà suspendue");
        }

        tache.setSuspendu(true);
        
        Tache saved = tacheRepository.save(tache);
        chantierService.recalculerStatutEtAvancement(tache.getChantier().getId());
        
        historiqueService.enregistrer(saved.getId(), "SUSPENSION", "actif", "suspendu", "Système");
        
        return toResponse(saved);
    }

    @Transactional
    public TacheResponse reprendre(Long id) {
        Tache tache = findOrThrow(id);
        if (!Boolean.TRUE.equals(tache.getSuspendu())) {
            throw new RuntimeException("La tâche n'est pas suspendue");
        }

        tache.setSuspendu(false);
        tache.setStatut(calculerStatut(tache.getDateDebutReelle(), tache.getDateDebut(), tache.getDateFin(), tache.getAvancement()));
        
        Tache saved = tacheRepository.save(tache);
        chantierService.recalculerStatutEtAvancement(tache.getChantier().getId());
        
        historiqueService.enregistrer(saved.getId(), "REPRISE", "suspendu", saved.getStatut(), "Système");
        
        return toResponse(saved);
    }

    public List<TacheHistorique> getHistorique(Long tacheId) {
        findOrThrow(tacheId);
        return historiqueService.getByTacheId(tacheId);
    }

    @Transactional
    public void delete(Long id) {
        Tache tache = findOrThrow(id);
        Long chantierId = tache.getChantier() != null ? tache.getChantier().getId() : null;
        
        // Supprimer d'abord l'historique lié
        tacheHistoriqueRepository.deleteByTacheId(id);
        
        // Puis supprimer la tâche
        tacheRepository.deleteById(id);
        
        if (chantierId != null) {
            chantierService.recalculerStatutEtAvancement(chantierId);
        }
    }

    public static String calculerStatut(LocalDate dateDebutReelle, LocalDate dateDebut, LocalDate dateFin, Integer avancement) {
        int av = avancement != null ? avancement : 0;
        LocalDate today = LocalDate.now();

        if (av >= 100) {
            return "termine";
        }

        if (dateFin != null && today.isAfter(dateFin) && av < 100) {
            return "retard";
        }

        boolean aCommenceReellement = dateDebutReelle != null;

        if (aCommenceReellement) {
            if (dateFin != null && !today.isAfter(dateFin)) {
                long daysUntil = ChronoUnit.DAYS.between(today, dateFin);
                if (daysUntil >= 0 && daysUntil <= 3 && av < 100) {
                    return "attention";
                }
            }
            return "en_cours";
        }

        return "planifie";
    }

    private Tache findOrThrow(Long id) {
        return tacheRepository.findById(id)
                .orElseThrow(() -> new TacheNotFoundException(id));
    }

    private Chantier resolveChantier(Long chantierId) {
        return chantierRepository.findById(chantierId)
                .orElseThrow(() -> new ChantierNotFoundException(chantierId));
    }

    private TacheResponse toResponse(Tache tache) {
        boolean isSuspendue = Boolean.TRUE.equals(tache.getSuspendu());
        boolean isTerminee = "termine".equals(tache.getStatut());
        boolean isPlanifiee = "planifie".equals(tache.getStatut());
        boolean hasStarted = tache.getDateDebutReelle() != null || 
                (tache.getDateDebut() != null && !LocalDate.now().isBefore(tache.getDateDebut()));

        return TacheResponse.builder()
                .id(tache.getId())
                .titre(tache.getTitre())
                .description(tache.getDescription())
                .dateDebut(tache.getDateDebut())
                .dateFin(tache.getDateFin())
                .dateDebutReelle(tache.getDateDebutReelle())
                .dateFinReelle(tache.getDateFinReelle())
                .statut(tache.getStatut())
                .avancement(tache.getAvancement())
                .priorite(tache.getPriorite())
                .categorie(tache.getCategorie())
                .chantierId(tache.getChantier() != null ? tache.getChantier().getId() : null)
                .chantierNom(tache.getChantier() != null ? tache.getChantier().getNom() : null)
                .suspendu(tache.getSuspendu())
                .canDemarrer(isPlanifiee && !isSuspendue && tache.getDateDebutReelle() == null)
                .canTerminer(hasStarted && !isTerminee && !isSuspendue)
                .canUpdateAvancement((hasStarted || "en_cours".equals(tache.getStatut()) || "attention".equals(tache.getStatut()) || "retard".equals(tache.getStatut())) && !isTerminee && !isSuspendue)
                .isEnRetard("retard".equals(tache.getStatut()))
                .isAttention("attention".equals(tache.getStatut()))
                .build();
    }
}