package com.waqt.api.controller;

import com.waqt.api.entity.User;
import com.waqt.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        String password = request.get("password");

        if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Username and password required");
            return ResponseEntity.badRequest().body(response);
        }

        username = username.trim();
        password = password.trim();

        if (userRepository.findByUsername(username).isPresent()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Username already exists");
            return ResponseEntity.badRequest().body(response);
        }

        String passwordHash = passwordEncoder.encode(password);
        String sessionToken = UUID.randomUUID().toString().replace("-", "");

        User user = User.builder()
                .username(username)
                .passwordHash(passwordHash)
                .sessionToken(sessionToken)
                .build();

        userRepository.save(user);

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("token", sessionToken);
        response.put("username", username);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> request) {
        String username = request.get("username");
        String password = request.get("password");

        if (username == null || username.trim().isEmpty() || password == null || password.trim().isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Username and password required");
            return ResponseEntity.badRequest().body(response);
        }

        username = username.trim();
        password = password.trim();

        Optional<User> userOpt = userRepository.findByUsername(username);

        if (userOpt.isEmpty() || !passwordEncoder.matches(password, userOpt.get().getPasswordHash())) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Invalid credentials");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }

        User user = userOpt.get();
        String sessionToken = UUID.randomUUID().toString().replace("-", "");
        user.setSessionToken(sessionToken);
        userRepository.save(user);

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("token", sessionToken);
        response.put("username", username);

        return ResponseEntity.ok(response);
    }

    @RequestMapping(value = "/update", method = {RequestMethod.POST, RequestMethod.PUT})
    public ResponseEntity<Map<String, Object>> updateProfile(
            @RequestHeader(value = "X-User-ID", required = false) String userIdHeader,
            @RequestBody Map<String, String> request) {

        if (userIdHeader == null) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Unauthorized");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(response);
        }

        Long userId = Long.parseLong(userIdHeader);
        String username = request.get("username");
        String password = request.get("password");

        if ((username == null || username.trim().isEmpty()) && (password == null || password.trim().isEmpty())) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "Username or password required to update");
            return ResponseEntity.badRequest().body(response);
        }

        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            Map<String, Object> response = new HashMap<>();
            response.put("status", "error");
            response.put("message", "User not found");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        User user = userOpt.get();

        if (username != null && !username.trim().isEmpty()) {
            username = username.trim();
            Optional<User> existing = userRepository.findByUsername(username);
            if (existing.isPresent() && !existing.get().getId().equals(userId)) {
                Map<String, Object> response = new HashMap<>();
                response.put("status", "error");
                response.put("message", "Username already exists");
                return ResponseEntity.badRequest().body(response);
            }
            user.setUsername(username);
        }

        if (password != null && !password.trim().isEmpty()) {
            user.setPasswordHash(passwordEncoder.encode(password.trim()));
        }

        userRepository.save(user);

        Map<String, Object> response = new HashMap<>();
        response.put("status", "success");
        response.put("message", "Profile updated successfully");
        response.put("username", user.getUsername());

        return ResponseEntity.ok(response);
    }
}
