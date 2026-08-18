package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.Depense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DepenseRepository extends JpaRepository<Depense, Long> {

    @Query("SELECT d FROM Depense d WHERE " +
           "(:chantierId IS NULL OR d.chantier.id = :chantierId)")
    List<Depense> search(@Param("chantierId") Long chantierId);
    
    List<Depense> findByChantierId(Long chantierId);
    
    void deleteByChantierId(Long chantierId);
}