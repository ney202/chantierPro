package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.dto.AffectationRequest;
import com.medplatform.chantiermanagement.dto.AffectationResponse;
import com.medplatform.chantiermanagement.entity.Affectation;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.entity.Utilisateur;
import com.medplatform.chantiermanagement.exception.AffectationNotFoundException;
import com.medplatform.chantiermanagement.exception.ChantierNotFoundException;
import com.medplatform.chantiermanagement.exception.UtilisateurNotFoundException;
import com.medplatform.chantiermanagement.repository.AffectationRepository;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AffectationService {

    private final AffectationRepository affectationRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final ChantierRepository chantierRepository;

    @Transactional
    public AffectationResponse create(AffectationRequest request) {
        Utilisateur utilisateur = resolveUtilisateur(request.getUtilisateurId());
        Chantier chantier = resolveChantier(request.getChantierId());

        // ← CORRECTION : assigner le chef au chantier
        chantier.setChef(utilisateur);
        chantierRepository.save(chantier);

        Affectation affectation = Affectation.builder()
                .utilisateur(utilisateur)
                .chantier(chantier)
                .dateAffectation(request.getDateAffectation())
                .build();

        return toResponse(affectationRepository.save(affectation));
    }

    public List<AffectationResponse> getAll() {
        return affectationRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Page<AffectationResponse> getAllPaged(Pageable pageable) {
        return affectationRepository.findAll(pageable).map(this::toResponse);
    }

    public List<AffectationResponse> search(Long utilisateurId, Long chantierId) {
        return affectationRepository.search(utilisateurId, chantierId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public AffectationResponse getById(Long id) {
        return toResponse(findOrThrow(id));
    }

    @Transactional
    public AffectationResponse update(Long id, AffectationRequest request) {
        Affectation affectation = findOrThrow(id);
        Utilisateur utilisateur = resolveUtilisateur(request.getUtilisateurId());
        Chantier chantier = resolveChantier(request.getChantierId());

        // ← CORRECTION : si le chantier change, retirer le chef de l'ancien
        Chantier oldChantier = affectation.getChantier();
        if (oldChantier != null && !oldChantier.getId().equals(chantier.getId())) {
            oldChantier.setChef(null);
            chantierRepository.save(oldChantier);
        }

        // ← CORRECTION : assigner le chef au nouveau chantier
        chantier.setChef(utilisateur);
        chantierRepository.save(chantier);

        affectation.setUtilisateur(utilisateur);
        affectation.setChantier(chantier);
        affectation.setDateAffectation(request.getDateAffectation());

        return toResponse(affectationRepository.save(affectation));
    }

    @Transactional
    public void delete(Long id) {
        Affectation affectation = findOrThrow(id);

        // ← CORRECTION : retirer le chef du chantier à la suppression
        Chantier chantier = affectation.getChantier();
        if (chantier != null) {
            chantier.setChef(null);
            chantierRepository.save(chantier);
        }

        affectationRepository.deleteById(id);
    }

    private Affectation findOrThrow(Long id) {
        return affectationRepository.findById(id)
                .orElseThrow(() -> new AffectationNotFoundException(id));
    }

    private Utilisateur resolveUtilisateur(Long utilisateurId) {
        return utilisateurRepository.findById(utilisateurId)
                .orElseThrow(() -> new UtilisateurNotFoundException(utilisateurId));
    }

    private Chantier resolveChantier(Long chantierId) {
        return chantierRepository.findById(chantierId)
                .orElseThrow(() -> new ChantierNotFoundException(chantierId));
    }

    private AffectationResponse toResponse(Affectation affectation) {
        return AffectationResponse.builder()
                .id(affectation.getId())
                .utilisateurId(affectation.getUtilisateur() != null ? affectation.getUtilisateur().getId() : null)
                .chantierId(affectation.getChantier() != null ? affectation.getChantier().getId() : null)
                .dateAffectation(affectation.getDateAffectation())
                .build();
    }
}