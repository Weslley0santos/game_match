package com.gamematch.backend;

import com.gamematch.backend.integration.PostgresTestDatabaseGuard;
import org.junit.jupiter.api.Test;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
@ContextConfiguration(initializers = PostgresTestDatabaseGuard.class)
class BackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
