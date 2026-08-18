package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.TacheHistorique;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TacheHistoriqueRepository extends JpaRepository<TacheHistorique, Long> {
    List<TacheHistorique> findByTacheIdOrderByDateActionDesc(Long tacheId);

    void deleteByUtilisateurId(Long utilisateurId);
    
    void deleteByTacheId(Long tacheId);
    
    void deleteByTacheIdIn(List<Long> tacheIds);
}