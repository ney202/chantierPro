package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.Affectation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AffectationRepository extends JpaRepository<Affectation, Long> {

    @Query("SELECT a FROM Affectation a WHERE " +
           "(:utilisateurId IS NULL OR a.utilisateur.id = :utilisateurId) AND " +
           "(:chantierId IS NULL OR a.chantier.id = :chantierId)")
    List<Affectation> search(@Param("utilisateurId") Long utilisateurId, @Param("chantierId") Long chantierId);

    @Modifying
    @Query("DELETE FROM Affectation a WHERE a.chantier.id = :chantierId")
    void deleteByChantierId(@Param("chantierId") Long chantierId);
}