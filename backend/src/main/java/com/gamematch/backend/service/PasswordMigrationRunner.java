package com.gamematch.backend.service;

import com.gamematch.backend.model.User;
import com.gamematch.backend.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.regex.Pattern;

@Service
public class PasswordMigrationRunner {
    private static final Pattern BCRYPT_HASH = Pattern.compile("^\\$2[aby]\\$\\d{2}\\$[./A-Za-z0-9]{53}$");

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public PasswordMigrationRunner(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public int migratePlaintextPasswords() {
        List<User> users = userRepository.findAll();
        int converted = 0;

        for (User user : users) {
            String password = user.getPassword();
            if (password != null && !BCRYPT_HASH.matcher(password).matches()) {
                user.setPassword(passwordEncoder.encode(password));
                converted++;
            }
        }

        userRepository.saveAll(users);
        return converted;
    }
}
