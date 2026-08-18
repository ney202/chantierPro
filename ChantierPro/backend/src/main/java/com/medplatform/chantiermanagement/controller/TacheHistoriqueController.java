package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.entity.Chantier;
import com.medplatform.chantiermanagement.entity.TacheHistorique;
import com.medplatform.chantiermanagement.repository.ChantierRepository;
import com.medplatform.chantiermanagement.repository.TacheRepository;
import com.medplatform.chantiermanagement.service.TacheHistoriqueService;
import com.medplatform.chantiermanagement.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/taches/{tacheId}/historique")
@RequiredArgsConstructor
public class TacheHistoriqueController {

    private final TacheHistoriqueService historiqueService;
    private final TacheRepository tacheRepository;
    private final ChantierRepository chantierRepository;
    private final SecurityUtils securityUtils;

    private Set<Long> getMyChantierIds() {
        Long chefId = securityUtils.getCurrentUserId();
        if (chefId == null) return Set.of();
        return chantierRepository.findByChefId(chefId).stream()
                .map(Chantier::getId)
                .collect(Collectors.toSet());
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<List<TacheHistorique>> getHistorique(@PathVariable Long tacheId) {
        if (securityUtils.isChefChantier()) {
            var tacheOpt = tacheRepository.findById(tacheId);
            if (tacheOpt.isEmpty()) {
                return ResponseEntity.notFound().build();
            }
            Long chantierId = tacheOpt.get().getChantier() != null ? tacheOpt.get().getChantier().getId() : null;
            if (chantierId == null || !getMyChantierIds().contains(chantierId)) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }
        return ResponseEntity.ok(historiqueService.getByTacheId(tacheId));
    }
}