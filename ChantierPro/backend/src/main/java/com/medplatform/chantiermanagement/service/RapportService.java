package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.dto.RapportRequest;
import com.medplatform.chantiermanagement.dto.RapportResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.entity.Rapport;
import com.medplatform.chantiermanagement.entity.Utilisateur;
import com.medplatform.chantiermanagement.exception.ChantierNotFoundException;
import com.medplatform.chantiermanagement.exception.RapportNotFoundException;
import com.medplatform.chantiermanagement.exception.UtilisateurNotFoundException;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.repository.PhotoRepository;
import com.medplatform.chantiermanagement.repository.RapportRepository;
import com.medplatform.chantiermanagement.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RapportService {

    private final RapportRepository rapportRepository;
    private final ChantierRepository chantierRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final PhotoRepository photoRepository;

    @Transactional
    public RapportResponse create(RapportRequest request) {
        Rapport rapport = Rapport.builder()
                .contenu(request.getContenu())
                .dateRapport(request.getDateRapport())
                .chantier(resolveChantier(request.getChantierId()))
                .auteur(resolveAuteur(request.getAuteurId()))
                .build();

        return toResponse(rapportRepository.save(rapport));
    }

    public List<RapportResponse> getAll() {
        return rapportRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Page<RapportResponse> getAllPaged(Pageable pageable) {
        return rapportRepository.findAll(pageable).map(this::toResponse);
    }

    public List<RapportResponse> search(Long chantierId, Long auteurId) {
        return rapportRepository.search(chantierId, auteurId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public RapportResponse getById(Long id) {
        return toResponse(findOrThrow(id));
    }

    @Transactional
    public RapportResponse update(Long id, RapportRequest request) {
        Rapport rapport = findOrThrow(id);

        rapport.setContenu(request.getContenu());
        rapport.setDateRapport(request.getDateRapport());
        rapport.setChantier(resolveChantier(request.getChantierId()));
        rapport.setAuteur(resolveAuteur(request.getAuteurId()));

        return toResponse(rapportRepository.save(rapport));
    }

    @Transactional
    public void delete(Long id) {
        findOrThrow(id);
        
        // Supprimer d'abord les photos liées
        photoRepository.deleteByRapportId(id);
        
        // Puis supprimer le rapport
        rapportRepository.deleteById(id);
    }

    private Rapport findOrThrow(Long id) {
        return rapportRepository.findById(id)
                .orElseThrow(() -> new RapportNotFoundException(id));
    }

    private Chantier resolveChantier(Long chantierId) {
        return chantierRepository.findById(chantierId)
                .orElseThrow(() -> new ChantierNotFoundException(chantierId));
    }

    private Utilisateur resolveAuteur(Long auteurId) {
        return utilisateurRepository.findById(auteurId)
                .orElseThrow(() -> new UtilisateurNotFoundException(auteurId));
    }

    private RapportResponse toResponse(Rapport rapport) {
        return RapportResponse.builder()
                .id(rapport.getId())
                .contenu(rapport.getContenu())
                .dateRapport(rapport.getDateRapport())
                .chantierId(rapport.getChantier() != null ? rapport.getChantier().getId() : null)
                .auteurId(rapport.getAuteur() != null ? rapport.getAuteur().getId() : null)
                .build();
    }
}