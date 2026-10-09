package com.gamematch.backend.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.UUID;

final class RequestLoggingFilter extends OncePerRequestFilter {
    private static final Logger logger = LoggerFactory.getLogger(RequestLoggingFilter.class);
    private static final String REQUEST_ID_HEADER = "X-Request-Id";
    private static final String REQUEST_ID_MDC_KEY = "requestId";

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        String requestId = UUID.randomUUID().toString();
        String previousRequestId = MDC.get(REQUEST_ID_MDC_KEY);
        long startedAt = System.nanoTime();
        int status = response.getStatus();

        response.setHeader(REQUEST_ID_HEADER, requestId);
        MDC.put(REQUEST_ID_MDC_KEY, requestId);

        try {
            filterChain.doFilter(request, response);
        } catch (IOException | ServletException | RuntimeException exception) {
            status = response.getStatus() >= HttpServletResponse.SC_BAD_REQUEST
                    ? response.getStatus()
                    : HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
            throw exception;
        } finally {
            if (response.getStatus() >= HttpServletResponse.SC_BAD_REQUEST
                    || status < HttpServletResponse.SC_BAD_REQUEST) {
                status = response.getStatus();
            }
            String path = request.getRequestURI().replace('\r', '_').replace('\n', '_');
            long durationMs = (System.nanoTime() - startedAt) / 1_000_000;
            logger.info(
                    "http_request requestId={} method={} path={} status={} durationMs={}",
                    requestId,
                    request.getMethod(),
                    path,
                    status,
                    durationMs
            );
            if (previousRequestId == null) {
                MDC.remove(REQUEST_ID_MDC_KEY);
            } else {
                MDC.put(REQUEST_ID_MDC_KEY, previousRequestId);
            }
        }
    }
}
