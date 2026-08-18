package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.dto.ChantierRequest;
import com.medplatform.chantiermanagement.dto.ChantierResponse;
import com.medplatform.chantiermanagement.entity.Utilisateur;
import com.medplatform.chantiermanagement.service.ChantierService;
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
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/chantiers")
@RequiredArgsConstructor
public class ChantierController {

    private final ChantierService chantierService;
    private final SecurityUtils securityUtils;

    @GetMapping("/debug/me")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<Map<String, Object>> debugMe() {
        Map<String, Object> map = new java.util.HashMap<>();
        map.put("userId", securityUtils.getCurrentUserId());
        map.put("role", securityUtils.getCurrentUserRole());
        map.put("isAdmin", securityUtils.isAdmin());
        map.put("isChef", securityUtils.isChefChantier());
        Utilisateur u = securityUtils.getCurrentUser();
        map.put("email", u != null ? u.getEmail() : null);
        map.put("nom", u != null ? u.getNom() : null);
        return ResponseEntity.ok(map);
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<List<ChantierResponse>> search(
            @RequestParam(required = false) String nom,
            @RequestParam(required = false) String statut) {
        List<ChantierResponse> results = chantierService.search(nom, statut);
        if (securityUtils.isChefChantier()) {
            Long userId = securityUtils.getCurrentUserId();
            results = results.stream()
                    .filter(c -> c.getChefId() != null && c.getChefId().equals(userId))
                    .collect(Collectors.toList());
        }
        return ResponseEntity.ok(results);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ChantierResponse> create(@Valid @RequestBody ChantierRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(chantierService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String direction) {

        if (securityUtils.isChefChantier()) {
            List<ChantierResponse> all = chantierService.getAll();
            Long userId = securityUtils.getCurrentUserId();
            List<ChantierResponse> filtered = all.stream()
                    .filter(c -> c.getChefId() != null && c.getChefId().equals(userId))
                    .collect(Collectors.toList());
            return ResponseEntity.ok(filtered);
        }

        if (page != null && size != null) {
            Sort sort = direction.equalsIgnoreCase("desc")
                    ? Sort.by(sortBy).descending()
                    : Sort.by(sortBy).ascending();
            return ResponseEntity.ok(chantierService.getAllPaged(PageRequest.of(page, size, sort)));
        }
        return ResponseEntity.ok(chantierService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<ChantierResponse> getById(@PathVariable Long id) {
        ChantierResponse response = chantierService.getById(id);
        if (securityUtils.isChefChantier() &&
                (response.getChefId() == null || !response.getChefId().equals(securityUtils.getCurrentUserId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<ChantierResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody ChantierRequest request) {
        ChantierResponse existing = chantierService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChefId() == null || !existing.getChefId().equals(securityUtils.getCurrentUserId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(chantierService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        chantierService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/demarrer")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<ChantierResponse> demarrer(@PathVariable Long id) {
        ChantierResponse existing = chantierService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChefId() == null || !existing.getChefId().equals(securityUtils.getCurrentUserId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(chantierService.demarrer(id));
    }

    @PostMapping("/{id}/terminer")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<ChantierResponse> terminer(@PathVariable Long id) {
        ChantierResponse existing = chantierService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChefId() == null || !existing.getChefId().equals(securityUtils.getCurrentUserId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(chantierService.terminer(id));
    }

    @PostMapping("/{id}/suspendre")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<ChantierResponse> suspendre(@PathVariable Long id) {
        ChantierResponse existing = chantierService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChefId() == null || !existing.getChefId().equals(securityUtils.getCurrentUserId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(chantierService.suspendre(id));
    }

    @PostMapping("/{id}/reprendre")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<ChantierResponse> reprendre(@PathVariable Long id) {
        ChantierResponse existing = chantierService.getById(id);
        if (securityUtils.isChefChantier() &&
                (existing.getChefId() == null || !existing.getChefId().equals(securityUtils.getCurrentUserId()))) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(chantierService.reprendre(id));
    }
}