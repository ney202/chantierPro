package com.medplatform.chantiermanagement.repository;

import com.medplatform.chantiermanagement.entity.Photo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PhotoRepository extends JpaRepository<Photo, Long> {

    @Query("SELECT p FROM Photo p WHERE " +
           "(:rapportId IS NULL OR p.rapport.id = :rapportId)")
    List<Photo> search(@Param("rapportId") Long rapportId);
    
    void deleteByRapportId(Long rapportId);
}