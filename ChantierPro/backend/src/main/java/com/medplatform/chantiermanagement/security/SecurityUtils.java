package com.medplatform.chantiermanagement.security;

import com.medplatform.chantiermanagement.entity.Utilisateur;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class SecurityUtils {

    public Utilisateur getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        
        if (auth == null || !auth.isAuthenticated() || "anonymousUser".equals(auth.getPrincipal())) {
            return null;
        }

        if (auth.getPrincipal() instanceof Utilisateur) {
            return (Utilisateur) auth.getPrincipal();
        }

        log.error("SecurityUtils: principal n'est pas un Utilisateur, type={}", 
                auth.getPrincipal() != null ? auth.getPrincipal().getClass().getName() : "null");
        return null;
    }

    public Long getCurrentUserId() {
        Utilisateur user = getCurrentUser();
        return user != null ? user.getId() : null;
    }

    public String getCurrentUserRole() {
        Utilisateur user = getCurrentUser();
        return user != null && user.getRole() != null ? user.getRole().name() : null;
    }

    public boolean isAdmin() {
        return "ADMIN".equals(getCurrentUserRole());
    }

    public boolean isChefChantier() {
        return "CHEF_CHANTIER".equals(getCurrentUserRole());
    }
}