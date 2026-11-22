package com.gamematch.backend.controller;

import com.gamematch.backend.dto.RatingRequest;
import com.gamematch.backend.model.Rating;
import com.gamematch.backend.model.RatingType;
import com.gamematch.backend.repository.RatingRepository;
import com.gamematch.backend.service.CurrentUserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.postgresql.util.PSQLException;
import org.postgresql.util.ServerErrorMessage;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RatingControllerTest {

    @Test
    void createsRatingForAuthenticatedUserWhenGameHasNoRating() {
        RatingRepository repository = mock(RatingRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        RatingController controller = new RatingController(repository, currentUser);
        when(currentUser.requireUserId()).thenReturn(7L);
        when(repository.findAllByUserIdAndGameId(7L, 42L)).thenReturn(List.of());
        when(repository.save(any(Rating.class))).thenAnswer(invocation -> invocation.getArgument(0));

        Rating created = controller.create(new RatingRequest(42L, RatingType.FAVORITE));

        assertThat(created.getUserId()).isEqualTo(7L);
        assertThat(created.getGameId()).isEqualTo(42L);
        assertThat(created.getType()).isEqualTo(RatingType.FAVORITE);
        verify(repository).save(any(Rating.class));
    }

    @Test
    void changesExistingRatingInsteadOfCreatingAnotherRatingForSameGame() {
        RatingRepository repository = mock(RatingRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        RatingController controller = new RatingController(repository, currentUser);
        Rating first = new Rating(7L, 42L, RatingType.LIKE);
        Rating duplicate = new Rating(7L, 42L, RatingType.DISLIKE);
        when(currentUser.requireUserId()).thenReturn(7L);
        when(repository.findAllByUserIdAndGameId(7L, 42L)).thenReturn(List.of(first, duplicate));

        Rating result = controller.create(new RatingRequest(42L, RatingType.FAVORITE));

        assertThat(result).isSameAs(first);
        assertThat(first.getType()).isEqualTo(RatingType.FAVORITE);
        assertThat(duplicate.getType()).isEqualTo(RatingType.FAVORITE);
        verify(repository).saveAll(List.of(first, duplicate));
        verify(repository, never()).save(any(Rating.class));
    }

    @Test
    void rejectsRatingWithoutGameOrTypeBeforeAccessingRepositories() {
        RatingRepository repository = mock(RatingRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        RatingController controller = new RatingController(repository, currentUser);

        assertThatThrownBy(() -> controller.create(new RatingRequest(null, RatingType.LIKE)))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));
        assertThatThrownBy(() -> controller.create(new RatingRequest(42L, null)))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST));

        verify(currentUser, never()).requireUserId();
        verify(repository, never()).save(any(Rating.class));
    }

    @Test
    void refusesToDeleteAnotherUsersRating() {
        RatingRepository repository = mock(RatingRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        RatingController controller = new RatingController(repository, currentUser);
        when(repository.findById(9L)).thenReturn(Optional.of(new Rating(8L, 42L, RatingType.LIKE)));
        when(currentUser.requireUserId()).thenReturn(7L);

        assertThatThrownBy(() -> controller.delete(9L))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN));

        verify(repository, never()).delete(any(Rating.class));
    }

    @ParameterizedTest
    @CsvSource({"fk_ratings_game, NOT_FOUND", "fk_ratings_user, UNAUTHORIZED"})
    void mapsMissingRatingReferenceToHttpStatus(String constraint, HttpStatus status) {
        RatingController controller = controllerWithSaveFailure(foreignKeyFailure(constraint));

        assertThatThrownBy(() -> controller.create(new RatingRequest(42L, RatingType.LIKE)))
                .isInstanceOfSatisfying(ResponseStatusException.class, exception ->
                        assertThat(exception.getStatusCode()).isEqualTo(status));
    }

    @Test
    void propagatesUnrelatedIntegrityFailure() {
        DataIntegrityViolationException failure = foreignKeyFailure("other_constraint");
        RatingController controller = controllerWithSaveFailure(failure);

        assertThatThrownBy(() -> controller.create(new RatingRequest(42L, RatingType.LIKE)))
                .isSameAs(failure);
    }

    private RatingController controllerWithSaveFailure(DataIntegrityViolationException failure) {
        RatingRepository repository = mock(RatingRepository.class);
        CurrentUserService currentUser = mock(CurrentUserService.class);
        when(currentUser.requireUserId()).thenReturn(7L);
        when(repository.findAllByUserIdAndGameId(7L, 42L)).thenReturn(List.of());
        when(repository.save(any(Rating.class))).thenThrow(failure);
        return new RatingController(repository, currentUser);
    }

    private DataIntegrityViolationException foreignKeyFailure(String constraint) {
        PSQLException failure = mock(PSQLException.class);
        ServerErrorMessage serverError = mock(ServerErrorMessage.class);
        when(failure.getSQLState()).thenReturn("23503");
        when(failure.getServerErrorMessage()).thenReturn(serverError);
        when(serverError.getConstraint()).thenReturn(constraint);
        return new DataIntegrityViolationException("Rating insert failed", failure);
    }
}
