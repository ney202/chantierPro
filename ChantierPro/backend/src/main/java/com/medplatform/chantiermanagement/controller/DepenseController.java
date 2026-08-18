package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.dto.DepenseRequest;
import com.medplatform.chantiermanagement.dto.DepenseResponse;
import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.service.DepenseService;
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
@RequestMapping("/api/depenses")
@RequiredArgsConstructor
public class DepenseController {

    private final DepenseService depenseService;
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
    public ResponseEntity<List<DepenseResponse>> search(
            @RequestParam(required = false) Long chantierId) {

        if (securityUtils.isChefChantier() && chantierId != null) {
            if (!getMyChantierIds().contains(chantierId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }

        List<DepenseResponse> results = depenseService.search(chantierId);

        if (securityUtils.isChefChantier()) {
            Set<Long> myChantiers = getMyChantierIds();
            results = results.stream()
                    .filter(d -> d.getChantierId() != null && myChantiers.contains(d.getChantierId()))
                    .collect(Collectors.toList());
        }
        return ResponseEntity.ok(results);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<DepenseResponse> create(@Valid @RequestBody DepenseRequest request) {
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(depenseService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String direction) {

        if (securityUtils.isChefChantier()) {
            List<DepenseResponse> all = depenseService.getAll();
            Set<Long> myChantiers = getMyChantierIds();
            List<DepenseResponse> filtered = all.stream()
                    .filter(d -> d.getChantierId() != null && myChantiers.contains(d.getChantierId()))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(filtered);
        }

        if (page != null && size != null) {
            Sort sort = direction.equalsIgnoreCase("desc")
                    ? Sort.by(sortBy).descending()
                    : Sort.by(sortBy).ascending();
            return ResponseEntity.ok(depenseService.getAllPaged(PageRequest.of(page, size, sort)));
        }
        return ResponseEntity.ok(depenseService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<DepenseResponse> getById(@PathVariable Long id) {
        DepenseResponse response = depenseService.getById(id);
        if (securityUtils.isChefChantier() &&
                (response.getChantierId() == null || !getMyChantierIds().contains(response.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<DepenseResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody DepenseRequest request) {
        DepenseResponse existing = depenseService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChantierId() == null || !getMyChantierIds().contains(existing.getChantierId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        if (securityUtils.isChefChantier() && request.getChantierId() != null) {
            if (!getMyChantierIds().contains(request.getChantierId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.ok(depenseService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        depenseService.delete(id);
        return ResponseEntity.noContent().build();
    }
}