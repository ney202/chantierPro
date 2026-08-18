package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.dto.RapportRequest;
import com.medplatform.chantiermanagement.dto.RapportResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.service.RapportService;
import com.medplatform.chantiermanagement.security.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/rapports")
@RequiredArgsConstructor
public class RapportController {

    private final RapportService rapportService;
    private final ChantierRepository chantierRepository;
    private final SecurityUtils securityUtils;

    private Set<Long> getMyChantierIds() {
        Long chefId = securityUtils.getCurrentUserId();
        if (chefId == null) return Set.of();
        return chantierRepository.findByChefId(chefId).stream()
                .map(Chantier::getId)
                .collect(Collectors.toSet());
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<List<RapportResponse>> search(
            @RequestParam(required = false) Long chantierId,
            @RequestParam(required = false) Long auteurId) {

        if (securityUtils.isChefChantier() && chantierId != null) {
            if (!getMyChantierIds().contains(chantierId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }

        List<RapportResponse> results = rapportService.search(chantierId, auteurId);

        if (securityUtils.isChefChantier()) {
            Set<Long> myChantiers = getMyChantierIds();
            results = results.stream()
                    .filter(r -> r.getChantierId() != null && myChantiers.contains(r.getChantierId()))
                    .collect(Collectors.toList());
        }
        return ResponseEntity.ok(results);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<RapportResponse> create(@Valid @RequestBody RapportRequest request) {
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(rapportService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String direction) {

        if (securityUtils.isChefChantier()) {
            List<RapportResponse> all = rapportService.getAll();
            Set<Long> myChantiers = getMyChantierIds();
            List<RapportResponse> filtered = all.stream()
                    .filter(r -> r.getChantierId() != null && myChantiers.contains(r.getChantierId()))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(filtered);
        }

        if (page != null && size != null) {
            Sort sort = direction.equalsIgnoreCase("desc")
                    ? Sort.by(sortBy).descending()
                    : Sort.by(sortBy).ascending();
            return ResponseEntity.ok(rapportService.getAllPaged(PageRequest.of(page, size, sort)));
        }
        return ResponseEntity.ok(rapportService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<RapportResponse> getById(@PathVariable Long id) {
        RapportResponse response = rapportService.getById(id);
        if (securityUtils.isChefChantier() &&
                (response.getChantierId() == null || !getMyChantierIds().contains(response.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<RapportResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody RapportRequest request) {
        RapportResponse existing = rapportService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.ok(rapportService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        rapportService.delete(id);
        return ResponseEntity.noContent().build();
    }
}