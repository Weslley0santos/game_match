package com.gamematch.backend.migration;

import com.gamematch.backend.model.User;
import com.gamematch.backend.config.PasswordEncoderConfig;
import com.gamematch.backend.repository.UserRepository;
import com.gamematch.backend.service.PasswordMigrationRunner;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.persistence.autoconfigure.EntityScan;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

import java.util.Arrays;

@SpringBootConfiguration
@EnableAutoConfiguration
@EntityScan(basePackageClasses = User.class)
@EnableJpaRepositories(basePackageClasses = UserRepository.class)
@Import({PasswordMigrationRunner.class, PasswordEncoderConfig.class})
public class PasswordMigrationApplication {
    public static void main(String[] args) {
        if (Arrays.stream(args).noneMatch("--confirm-password-migration"::equals)) {
            throw new IllegalArgumentException("Pass --confirm-password-migration after creating a database backup");
        }

        try (ConfigurableApplicationContext context = new SpringApplicationBuilder(PasswordMigrationApplication.class)
                .web(WebApplicationType.NONE)
                .run(args)) {
            int converted = context.getBean(PasswordMigrationRunner.class).migratePlaintextPasswords();
            System.out.printf("Converted %d legacy password(s).%n", converted);
        }
    }
}
