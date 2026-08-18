package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.dto.DepenseRequest;
import com.medplatform.chantiermanagement.dto.DepenseResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.entity.Depense;
import com.medplatform.chantiermanagement.exception.ChantierNotFoundException;
import com.medplatform.chantiermanagement.exception.DepenseNotFoundException;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.repository.DepenseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DepenseService {

    private final DepenseRepository depenseRepository;
    private final ChantierRepository chantierRepository;

    public DepenseResponse create(DepenseRequest request) {
        Depense depense = Depense.builder()
                .montant(request.getMontant())
                .description(request.getDescription())
                .dateDepense(request.getDateDepense())
                .chantier(resolveChantier(request.getChantierId()))
                .build();

        return toResponse(depenseRepository.save(depense));
    }

    public List<DepenseResponse> getAll() {
        return depenseRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Page<DepenseResponse> getAllPaged(Pageable pageable) {
        return depenseRepository.findAll(pageable).map(this::toResponse);
    }

    public List<DepenseResponse> search(Long chantierId) {
        return depenseRepository.search(chantierId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public DepenseResponse getById(Long id) {
        return toResponse(findOrThrow(id));
    }

    public DepenseResponse update(Long id, DepenseRequest request) {
        Depense depense = findOrThrow(id);

        depense.setMontant(request.getMontant());
        depense.setDescription(request.getDescription());
        depense.setDateDepense(request.getDateDepense());
        depense.setChantier(resolveChantier(request.getChantierId()));

        return toResponse(depenseRepository.save(depense));
    }

    public void delete(Long id) {
        findOrThrow(id);
        depenseRepository.deleteById(id);
    }

    private Depense findOrThrow(Long id) {
        return depenseRepository.findById(id)
                .orElseThrow(() -> new DepenseNotFoundException(id));
    }

    private Chantier resolveChantier(Long chantierId) {
        return chantierRepository.findById(chantierId)
                .orElseThrow(() -> new ChantierNotFoundException(chantierId));
    }

    private DepenseResponse toResponse(Depense depense) {
        return DepenseResponse.builder()
                .id(depense.getId())
                .montant(depense.getMontant())
                .description(depense.getDescription())
                .dateDepense(depense.getDateDepense())
                .chantierId(depense.getChantier() != null ? depense.getChantier().getId() : null)
                .build();
    }
}
