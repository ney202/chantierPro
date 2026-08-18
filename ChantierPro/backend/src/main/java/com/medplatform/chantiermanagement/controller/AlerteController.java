package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.dto.AlerteRequest;
import com.medplatform.chantiermanagement.dto.AlerteResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.service.AlerteService;
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
@RequestMapping("/api/alertes")
@RequiredArgsConstructor
public class AlerteController {

    private final AlerteService alerteService;
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
    public ResponseEntity<List<AlerteResponse>> search(
            @RequestParam(required = false) String statut,
            @RequestParam(required = false) Long chantierId) {

        if (securityUtils.isChefChantier() && chantierId != null) {
            if (!getMyChantierIds().contains(chantierId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }

        List<AlerteResponse> results = alerteService.search(statut, chantierId);

        if (securityUtils.isChefChantier()) {
            Set<Long> myChantiers = getMyChantierIds();
            results = results.stream()
                    .filter(a -> a.getChantierId() != null && myChantiers.contains(a.getChantierId()))
                    .collect(Collectors.toList());
        }
        return ResponseEntity.ok(results);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<AlerteResponse> create(@Valid @RequestBody AlerteRequest request) {
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(alerteService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String direction) {

        if (securityUtils.isChefChantier()) {
            List<AlerteResponse> all = alerteService.getAll();
            Set<Long> myChantiers = getMyChantierIds();
            List<AlerteResponse> filtered = all.stream()
                    .filter(a -> a.getChantierId() != null && myChantiers.contains(a.getChantierId()))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(filtered);
        }

        if (page != null && size != null) {
            Sort sort = direction.equalsIgnoreCase("desc")
                    ? Sort.by(sortBy).descending()
                    : Sort.by(sortBy).ascending();
            return ResponseEntity.ok(alerteService.getAllPaged(PageRequest.of(page, size, sort)));
        }
        return ResponseEntity.ok(alerteService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<AlerteResponse> getById(@PathVariable Long id) {
        AlerteResponse response = alerteService.getById(id);
        if (securityUtils.isChefChantier() &&
                (response.getChantierId() == null || !getMyChantierIds().contains(response.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<AlerteResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody AlerteRequest request) {
        AlerteResponse existing = alerteService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.ok(alerteService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        alerteService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/lu")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<Void> markAsRead(@PathVariable Long id) {
        AlerteResponse existing = alerteService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        alerteService.markAsRead(id);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/lu/all")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<Void> markAllAsRead() {
        if (securityUtils.isChefChantier()) {
            Set<Long> myChantiers = getMyChantierIds();
            List<AlerteResponse> myAlertes = alerteService.getAll().stream()
                    .filter(a -> a.getChantierId() != null && myChantiers.contains(a.getChantierId()))
                    .filter(a -> Boolean.FALSE.equals(a.getLu()))
                    .collect(Collectors.toList());
            for (AlerteResponse a : myAlertes) {
                alerteService.markAsRead(a.getId());
            }
            return ResponseEntity.noContent().build();
        }
        alerteService.markAllAsRead();
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/count/unread")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<Long> countUnread() {
        if (securityUtils.isChefChantier()) {
            Set<Long> myChantiers = getMyChantierIds();
            long count = alerteService.getAll().stream()
                    .filter(a -> a.getChantierId() != null && myChantiers.contains(a.getChantierId()))
                    .filter(a -> Boolean.FALSE.equals(a.getLu()))
                    .count();
            return ResponseEntity.ok(count);
        }
        return ResponseEntity.ok(alerteService.countUnread());
    }
}