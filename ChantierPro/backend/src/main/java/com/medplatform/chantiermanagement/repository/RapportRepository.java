package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.Rapport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RapportRepository extends JpaRepository<Rapport, Long> {

    @Query("SELECT r FROM Rapport r WHERE " +
           "(:chantierId IS NULL OR r.chantier.id = :chantierId) AND " +
           "(:auteurId IS NULL OR r.auteur.id = :auteurId)")
    List<Rapport> search(@Param("chantierId") Long chantierId, @Param("auteurId") Long auteurId);

    List<Rapport> findByAuteurId(Long auteurId);
    
    List<Rapport> findByChantierId(Long chantierId);
    
    void deleteByChantierId(Long chantierId);
}