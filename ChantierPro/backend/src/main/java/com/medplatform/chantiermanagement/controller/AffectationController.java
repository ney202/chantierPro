package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.dto.AffectationRequest;
import com.medplatform.chantiermanagement.dto.AffectationResponse;
import com.medplatform.chantiermanagement.service.AffectationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/affectations")
@RequiredArgsConstructor
public class AffectationController {

    private final AffectationService affectationService;

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<List<AffectationResponse>> search(
            @RequestParam(required = false) Long utilisateurId,
            @RequestParam(required = false) Long chantierId) {
        return ResponseEntity.ok(affectationService.search(utilisateurId, chantierId));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AffectationResponse> create(@Valid @RequestBody AffectationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(affectationService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String direction) {
        if (page != null && size != null) {
            Sort sort = direction.equalsIgnoreCase("desc")
                    ? Sort.by(sortBy).descending()
                    : Sort.by(sortBy).ascending();
            return ResponseEntity.ok(affectationService.getAllPaged(PageRequest.of(page, size, sort)));
        }
        return ResponseEntity.ok(affectationService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<AffectationResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(affectationService.getById(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AffectationResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody AffectationRequest request) {
        return ResponseEntity.ok(affectationService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        affectationService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
