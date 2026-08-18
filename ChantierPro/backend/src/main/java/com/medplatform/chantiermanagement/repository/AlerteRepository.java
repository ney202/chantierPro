package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.Alerte;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlerteRepository extends JpaRepository<Alerte, Long> {

    @Query("SELECT a FROM Alerte a WHERE " +
           "(:statut IS NULL OR a.statut = :statut) AND " +
           "(:chantierId IS NULL OR a.chantier.id = :chantierId)")
    List<Alerte> search(@Param("statut") String statut, @Param("chantierId") Long chantierId);

    List<Alerte> findByLuFalseOrderByDateCreationDesc();

    long countByLuFalse();
    
    List<Alerte> findByChantierId(Long chantierId);
    
    void deleteByChantierId(Long chantierId);
}