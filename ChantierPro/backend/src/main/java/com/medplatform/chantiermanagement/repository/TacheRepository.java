package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.Tache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TacheRepository extends JpaRepository<Tache, Long> {
    List<Tache> findByChantierId(Long chantierId);
    
    @Query("SELECT t FROM Tache t WHERE " +
           "(:statut IS NULL OR t.statut = :statut) AND " +
           "(:chantierId IS NULL OR t.chantier.id = :chantierId)")
    List<Tache> search(@Param("statut") String statut, @Param("chantierId") Long chantierId);
    
    void deleteByChantierId(Long chantierId);
}