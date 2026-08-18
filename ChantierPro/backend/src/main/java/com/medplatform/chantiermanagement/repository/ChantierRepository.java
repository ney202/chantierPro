package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.Chantier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChantierRepository extends JpaRepository<Chantier, Long> {

    @Query("SELECT c FROM Chantier c WHERE " +
           "(:nom IS NULL OR LOWER(c.nom) LIKE LOWER(CONCAT('%', :nom, '%'))) AND " +
           "(:statut IS NULL OR c.statut = :statut)")
    List<Chantier> search(@Param("nom") String nom, @Param("statut") String statut);

    List<Chantier> findByChefId(Long chefId);
}