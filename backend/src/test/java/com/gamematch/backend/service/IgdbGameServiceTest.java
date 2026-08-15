package com.gamematch.backend.service;

import com.gamematch.backend.config.IgdbProperties;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class IgdbGameServiceTest {

    @Test
    void mainGameSearchFiltersCategoryAndGameVersionsAtTheSource() {
        IgdbGameService service = new IgdbGameService(
                new IgdbProperties(),
                mock(IgdbAuthService.class)
        );

        String searchBody = service.buildSearchBody("Hollow Knight", true);

        assertThat(searchBody)
                .contains("where game_type = 0 & version_parent = null;");
    }
}
