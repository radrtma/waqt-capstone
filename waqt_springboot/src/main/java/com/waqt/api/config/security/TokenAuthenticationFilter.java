package com.waqt.api.config.security;

import com.waqt.api.entity.User;
import com.waqt.api.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Optional;

@Component
public class TokenAuthenticationFilter extends OncePerRequestFilter {

    @Autowired
    private UserRepository userRepository;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) throws ServletException {
        String path = request.getRequestURI();
        String method = request.getMethod();

        // Only filter /api/* paths
        if (!path.startsWith("/api/")) {
            return true;
        }

        // Public endpoints to exclude:
        if (path.equals("/api/auth/register") || path.equals("/api/auth/login")) {
            return true;
        }

        // GET /api/posts, GET /api/posts/{id}, GET /api/posts/{id}/comments
        if ("GET".equalsIgnoreCase(method)) {
            if (path.equals("/api/posts") || path.matches("^/api/posts/\\d+$") || path.matches("^/api/posts/\\d+/comments$")) {
                return true;
            }
        }

        // POST /api/posts/{id}/react
        if ("POST".equalsIgnoreCase(method) && path.matches("^/api/posts/\\d+/react$")) {
            return true;
        }

        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            sendUnauthorizedError(response, "No authorization token provided or invalid format");
            return;
        }

        String token = authHeader.substring(7).trim();
        Optional<User> userOpt = userRepository.findBySessionToken(token);

        if (userOpt.isEmpty()) {
            sendUnauthorizedError(response, "Invalid session token");
            return;
        }

        User user = userOpt.get();

        // Wrap request to inject authentication headers
        HeaderMapRequestWrapper wrappedRequest = new HeaderMapRequestWrapper(request);
        wrappedRequest.addHeader("X-User-ID", String.valueOf(user.getId()));
        wrappedRequest.addHeader("X-User-Username", user.getUsername());

        filterChain.doFilter(wrappedRequest, response);
    }

    private void sendUnauthorizedError(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(String.format("{\"status\":\"error\",\"message\":\"%s\"}", message));
    }
}
