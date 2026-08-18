package com.medplatform.chantiermanagement.controller;

import com.medplatform.chantiermanagement.dto.PhotoRequest;
import com.medplatform.chantiermanagement.dto.PhotoResponse;
import com.medplatform.chantiermanagement.service.PhotoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/photos")
@RequiredArgsConstructor
public class PhotoController {

    private final PhotoService photoService;

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<List<PhotoResponse>> search(
            @RequestParam(required = false) Long rapportId) {
        return ResponseEntity.ok(photoService.search(rapportId));
    }

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<PhotoResponse> upload(
            @RequestParam("file") MultipartFile file,
            @RequestParam("rapportId") Long rapportId) {
        return ResponseEntity.status(HttpStatus.CREATED).body(photoService.uploadPhoto(file, rapportId));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<PhotoResponse> create(@Valid @RequestBody PhotoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(photoService.create(request));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<?> getAll(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String direction) {
        if (page != null && size != null) {
            Sort sort = direction.equalsIgnoreCase("desc")
                    ? Sort.by(sortBy).descending()
                    : Sort.by(sortBy).ascending();
            return ResponseEntity.ok(photoService.getAllPaged(PageRequest.of(page, size, sort)));
        }
        return ResponseEntity.ok(photoService.getAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<PhotoResponse> getById(@PathVariable Long id) {
        return ResponseEntity.ok(photoService.getById(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'CHEF_CHANTIER')")
    public ResponseEntity<PhotoResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody PhotoRequest request) {
        return ResponseEntity.ok(photoService.update(id, request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        photoService.delete(id);
        return ResponseEntity.noContent().build();
    }
}