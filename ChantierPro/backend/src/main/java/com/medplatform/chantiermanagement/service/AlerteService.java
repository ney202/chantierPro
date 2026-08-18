package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.dto.AlerteRequest;
import com.medplatform.chantiermanagement.dto.AlerteResponse;
import com.medplatform.chantiermanagement.entity.Alerte;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.exception.AlerteNotFoundException;
import com.medplatform.chantiermanagement.exception.ChantierNotFoundException;
import com.medplatform.chantiermanagement.repository.AlerteRepository;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AlerteService {

    private final AlerteRepository alerteRepository;
    private final ChantierRepository chantierRepository;

    public AlerteResponse create(AlerteRequest request) {
        Chantier chantier = resolveChantier(request.getChantierId());

        Alerte alerte = Alerte.builder()
                .message(request.getMessage())
                .dateCreation(request.getDateCreation() != null ? request.getDateCreation() : LocalDateTime.now())
                .statut(request.getStatut() != null ? request.getStatut() : "non_lue")
                .lu(request.getLu() != null ? request.getLu() : false)
                .chantier(chantier)
                .build();

        return toResponse(alerteRepository.save(alerte));
    }

    public List<AlerteResponse> getAll() {
        return alerteRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Page<AlerteResponse> getAllPaged(Pageable pageable) {
        return alerteRepository.findAll(pageable).map(this::toResponse);
    }

    public List<AlerteResponse> search(String statut, Long chantierId) {
        return alerteRepository.search(statut, chantierId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public AlerteResponse getById(Long id) {
        return toResponse(findOrThrow(id));
    }

    public AlerteResponse update(Long id, AlerteRequest request) {
        Alerte alerte = findOrThrow(id);
        Chantier chantier = resolveChantier(request.getChantierId());

        alerte.setMessage(request.getMessage());
        alerte.setDateCreation(request.getDateCreation());
        alerte.setStatut(request.getStatut());
        alerte.setLu(request.getLu() != null ? request.getLu() : alerte.getLu());
        alerte.setChantier(chantier);

        return toResponse(alerteRepository.save(alerte));
    }

    public void delete(Long id) {
        findOrThrow(id);
        alerteRepository.deleteById(id);
    }

    @Transactional
    public void markAsRead(Long id) {
        Alerte alerte = findOrThrow(id);
        alerte.setLu(true);
        alerteRepository.save(alerte);
    }

    @Transactional
    public void markAllAsRead() {
        List<Alerte> nonLues = alerteRepository.findByLuFalseOrderByDateCreationDesc();
        for (Alerte a : nonLues) {
            a.setLu(true);
        }
        alerteRepository.saveAll(nonLues);
    }

    public long countUnread() {
        return alerteRepository.countByLuFalse();
    }

    private Alerte findOrThrow(Long id) {
        return alerteRepository.findById(id)
                .orElseThrow(() -> new AlerteNotFoundException(id));
    }

    private Chantier resolveChantier(Long chantierId) {
        return chantierRepository.findById(chantierId)
                .orElseThrow(() -> new ChantierNotFoundException(chantierId));
    }

    private AlerteResponse toResponse(Alerte alerte) {
        return AlerteResponse.builder()
                .id(alerte.getId())
                .message(alerte.getMessage())
                .dateCreation(alerte.getDateCreation())
                .statut(alerte.getStatut())
                .lu(alerte.getLu())
                .chantierId(alerte.getChantier() != null ? alerte.getChantier().getId() : null)
                .build();
    }
}