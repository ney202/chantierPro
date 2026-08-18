package com.medplatform.chantiermanagement.service;

import com.medplatform.chantiermanagement.dto.PhotoRequest;
import com.medplatform.chantiermanagement.dto.PhotoResponse;
import com.medplatform.chantiermanagement.entity.Photo;
import com.medplatform.chantiermanagement.entity.Rapport;
import com.medplatform.chantiermanagement.exception.PhotoNotFoundException;
import com.medplatform.chantiermanagement.exception.RapportNotFoundException;
import com.medplatform.chantiermanagement.repository.PhotoRepository;
import com.medplatform.chantiermanagement.repository.RapportRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PhotoService {

    private static final Set<String> ALLOWED_TYPES = Set.of(
            "image/jpeg", "image/jpg", "image/png", "image/webp"
    );
    private static final long MAX_SIZE_BYTES = 5L * 1024 * 1024;

    private final PhotoRepository photoRepository;
    private final RapportRepository rapportRepository;

    @Value("${file.upload-dir}")
    private String uploadDir;

    public PhotoResponse uploadPhoto(MultipartFile file, Long rapportId) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File must not be empty.");
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_TYPES.contains(contentType.toLowerCase())) {
            throw new IllegalArgumentException(
                    "Unsupported file type: " + contentType + ". Allowed types: image/jpeg, image/jpg, image/png, image/webp."
            );
        }

        if (file.getSize() > MAX_SIZE_BYTES) {
            throw new IllegalArgumentException("File size exceeds the maximum allowed size of 5MB.");
        }

        Rapport rapport = resolveRapport(rapportId);

        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String filename = UUID.randomUUID() + extension;

        try {
            Path uploadPath = Paths.get(uploadDir);
            Files.createDirectories(uploadPath);
            Files.copy(file.getInputStream(), uploadPath.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException("Failed to store file. Please try again.", e);
        }

        Photo photo = Photo.builder()
                .urlPhoto("/uploads/photos/" + filename)
                .dateUpload(LocalDate.now())
                .rapport(rapport)
                .build();

        return toResponse(photoRepository.save(photo));
    }

    public PhotoResponse create(PhotoRequest request) {
        Photo photo = Photo.builder()
                .urlPhoto(request.getUrlPhoto())
                .dateUpload(request.getDateUpload())
                .rapport(resolveRapport(request.getRapportId()))
                .build();

        return toResponse(photoRepository.save(photo));
    }

    public List<PhotoResponse> getAll() {
        return photoRepository.findAll()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Page<PhotoResponse> getAllPaged(Pageable pageable) {
        return photoRepository.findAll(pageable).map(this::toResponse);
    }

    public List<PhotoResponse> search(Long rapportId) {
        return photoRepository.search(rapportId)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public PhotoResponse getById(Long id) {
        return toResponse(findOrThrow(id));
    }

    public PhotoResponse update(Long id, PhotoRequest request) {
        Photo photo = findOrThrow(id);

        photo.setUrlPhoto(request.getUrlPhoto());
        photo.setDateUpload(request.getDateUpload());
        photo.setRapport(resolveRapport(request.getRapportId()));

        return toResponse(photoRepository.save(photo));
    }

    public void delete(Long id) {
        findOrThrow(id);
        photoRepository.deleteById(id);
    }

    private Photo findOrThrow(Long id) {
        return photoRepository.findById(id)
                .orElseThrow(() -> new PhotoNotFoundException(id));
    }

    private Rapport resolveRapport(Long rapportId) {
        return rapportRepository.findById(rapportId)
                .orElseThrow(() -> new RapportNotFoundException(rapportId));
    }

    private PhotoResponse toResponse(Photo photo) {
        return PhotoResponse.builder()
                .id(photo.getId())
                .urlPhoto(photo.getUrlPhoto())
                .dateUpload(photo.getDateUpload())
                .rapportId(photo.getRapport() != null ? photo.getRapport().getId() : null)
                .build();
    }
}
