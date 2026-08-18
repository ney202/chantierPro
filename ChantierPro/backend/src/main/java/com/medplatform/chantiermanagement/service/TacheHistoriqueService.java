package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.entity.TacheHistorique;
import com.medplatform.chantiermanagement.repository.TacheHistoriqueRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class TacheHistoriqueService {

    private final TacheHistoriqueRepository historiqueRepository;

    @Transactional
    public void enregistrer(Long tacheId, String action, String ancienneValeur, String nouvelleValeur, String auteur) {
        TacheHistorique h = TacheHistorique.builder()
                .tacheId(tacheId)
                .action(action)
                .ancienneValeur(ancienneValeur)
                .nouvelleValeur(nouvelleValeur)
                .auteur(auteur != null ? auteur : "Système")
                .dateAction(LocalDateTime.now())
                .build();
        historiqueRepository.save(h);
    }

    public List<TacheHistorique> getByTacheId(Long tacheId) {
        return historiqueRepository.findByTacheIdOrderByDateActionDesc(tacheId);
    }
}