package com.gamematch.backend.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

final class LoginAttemptRateLimitFilter extends OncePerRequestFilter {
    private static final int MAX_ATTEMPTS = 10;
    private static final long WINDOW_MILLIS = Duration.ofMinutes(15).toMillis();
    private static final long CLEANUP_INTERVAL = 256;

    // shortcut: limite local ao processo; use armazenamento compartilhado antes de operar com varias instancias.
    private final ConcurrentHashMap<String, AttemptWindow> attemptsByIp = new ConcurrentHashMap<>();
    private final AtomicLong requests = new AtomicLong();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !"POST".equalsIgnoreCase(request.getMethod())
                || !"/users/login".equals(request.getServletPath());
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        long now = System.currentTimeMillis();
        String ipAddress = request.getRemoteAddr();
        AtomicBoolean allowed = new AtomicBoolean();

        attemptsByIp.compute(ipAddress, (ip, window) -> {
            if (window == null || now - window.startedAt >= WINDOW_MILLIS) {
                window = new AttemptWindow(now);
            }
            if (window.count < MAX_ATTEMPTS) {
                window.count++;
                allowed.set(true);
            }
            return window;
        });

        if (!allowed.get()) {
            AttemptWindow window = attemptsByIp.get(ipAddress);
            long remainingMillis = window == null ? WINDOW_MILLIS : WINDOW_MILLIS - (now - window.startedAt);
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setHeader("Retry-After", Long.toString(Math.max(1, (remainingMillis + 999) / 1000)));
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write("{\"message\":\"Limite de tentativas atingido. Aguarde o fim do bloqueio.\"}");
            return;
        }

        filterChain.doFilter(request, response);

        if (response.getStatus() >= 200 && response.getStatus() < 300) {
            attemptsByIp.remove(ipAddress);
        }
        if (requests.incrementAndGet() % CLEANUP_INTERVAL == 0) {
            long cleanupTime = System.currentTimeMillis();
            attemptsByIp.entrySet().removeIf(entry -> cleanupTime - entry.getValue().startedAt >= WINDOW_MILLIS);
        }
    }

    private static final class AttemptWindow {
        private final long startedAt;
        private int count;

        private AttemptWindow(long startedAt) {
            this.startedAt = startedAt;
        }
    }
}
