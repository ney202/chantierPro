package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.dto.TacheRequest;
import com.medplatform.chantiermanagement.dto.TacheResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.service.TacheService;
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
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/taches")
@RequiredArgsConstructor
public class TacheController {

    private final TacheService tacheService;
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
    public ResponseEntity<List<TacheResponse>> search(
            @RequestParam(required = false) String statut,
            @RequestParam(required = false) Long chantierId) {

        if (securityUtils.isChefChantier() && chantierId != null) {
            if (!getMyChantierIds().contains(chantierId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }

        List<TacheResponse> results = tacheService.search(statut, chantierId);

        if (securityUtils.isChefChantier()) {
            Set<Long> myChantiers = getMyChantierIds();
            results = results.stream()
                    .filter(t -> t.getChantierId() != null && myChantiers.contains(t.getChantierId()))
                    .collect(Collectors.toList());
        }
        return ResponseEntity.ok(results);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> create(@Valid @RequestBody TacheRequest request) {
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(tacheService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String direction) {

        if (securityUtils.isChefChantier()) {
            List<TacheResponse> all = tacheService.getAll();
            Set<Long> myChantiers = getMyChantierIds();
            List<TacheResponse> filtered = all.stream()
                    .filter(t -> t.getChantierId() != null && myChantiers.contains(t.getChantierId()))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(filtered);
        }

        if (page != null && size != null) {
            Sort sort = direction.equalsIgnoreCase("desc")
                    ? Sort.by(sortBy).descending()
                    : Sort.by(sortBy).ascending();
            return ResponseEntity.ok(tacheService.getAllPaged(PageRequest.of(page, size, sort)));
        }
        return ResponseEntity.ok(tacheService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> getById(@PathVariable Long id) {
        TacheResponse response = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (response.getChantierId() == null || !getMyChantierIds().contains(response.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody TacheRequest request) {
        TacheResponse existing = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.ok(tacheService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        TacheResponse existing = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        tacheService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/demarrer")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> demarrer(@PathVariable Long id) {
        TacheResponse existing = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(tacheService.demarrer(id));
    }

    @PostMapping("/{id}/avancement")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> updateAvancement(
            @PathVariable Long id,
            @RequestBody Map<String, Integer> body) {
        TacheResponse existing = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(tacheService.mettreAJourAvancement(id, body.get("avancement")));
    }

    @PostMapping("/{id}/terminer")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> terminer(@PathVariable Long id) {
        TacheResponse existing = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(tacheService.terminer(id));
    }

    @PostMapping("/{id}/suspendre")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> suspendre(@PathVariable Long id) {
        TacheResponse existing = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(tacheService.suspendre(id));
    }

    @PostMapping("/{id}/reprendre")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<TacheResponse> reprendre(@PathVariable Long id) {
        TacheResponse existing = tacheService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(tacheService.reprendre(id));
    }
}