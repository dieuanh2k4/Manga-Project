---
name: projectmanga-mangacontroller-unit-tests
description: Generate and fix unit tests for backend/src/Controllers/MangaController.cs in ProjectManga using xUnit, Moq, and EF Core InMemory. Use this whenever the user asks to add, update, debug, or improve MangaController tests, including requests like "fix controller tests", "cover Manga endpoints", "viết unit test MangaController", or "sửa test MangaController" even if they do not mention xUnit explicitly.
compatibility: csharp xunit moq projectmanga backend
---

# ProjectManga MangaController Unit Tests

Use this skill to create or repair unit tests for `MangaController` in the backend test project.

## Goal

Produce reliable, compile-ready tests in `backend.Tests/Controllers/MangaControllerTests.cs` that match the current controller behavior and payload shape.

## Repository Context To Read First

Before writing tests, read these files in this order:

1. `backend/src/Controllers/MangaController.cs`
2. `backend/src/Controllers/ApiControllerBase.cs`
3. `backend/src/Services/Interface/IMangaService.cs`
4. `backend/src/Models/Manga.cs`
5. `backend.Tests/TestHelpers/ControllerTestHelper.cs`
6. `backend.Tests/Controllers/MangaControllerTests.cs` (if it exists)

This prevents stale-field mistakes (for example, using removed properties like `YearRelease` and `DatePublish`).

## Scope

- Target file: `backend.Tests/Controllers/MangaControllerTests.cs`
- Keep helper usage consistent with `ControllerTestHelper`.
- Use xUnit + Moq style already used in `backend.Tests`.
- Keep tests unit-level: mock `IMangaService`, use in-memory `ApplicationDbContext` only when needed for delete behavior.

## Response Shape Rules

`MangaController` has two response patterns. Test the correct one for each action:

1. Direct payload responses (`Ok(entity)` or `Ok(list)`):

- `GetAllManga`
- `GetMangaById`

2. Anonymous object payload responses (`Ok(new { message, data })`):

- `CreateManga`
- `UpdateManga`
- `DeleteManga`
- `Search`
- `SortByGenre`
- `MangaOngoing`
- `MangaComplete`

When payload is anonymous, do not cast `okResult.Value` directly to `Manga` or `List<Manga>`.
Use helper extraction:

```csharp
var okResult = Assert.IsType<OkObjectResult>(result);
var message = ControllerTestHelper.GetAnonymousProperty<string>(okResult.Value!, "message");
var data = ControllerTestHelper.GetAnonymousProperty<Manga>(okResult.Value!, "data");
```

For list endpoints:

```csharp
var data = ControllerTestHelper.GetAnonymousProperty<List<Manga>>(okResult.Value!, "data");
Assert.NotNull(data);
```

## Error Mapping Rules

`ApiControllerBase.ReturnException` maps exceptions to status codes. Add tests for at least representative failure paths:

- `Result` -> 400 with `ExceptionBody`
- `ArgumentException` -> 400 with `ExceptionBody`
- `KeyNotFoundException` -> 404 with `ExceptionBody`
- unexpected `Exception` -> 500 with message `An unexpected error occurred.`

Prefer asserting both status code and message.

## Coverage Expectations

Cover these behaviors at minimum:

1. `GetAllManga`: success list + one exception path.
2. `GetMangaById`: success + one exception path.
3. `CreateManga`: with file uploads once, without file skips upload, both return anonymous payload.
4. `UpdateManga`: with file uploads once, without file skips upload, return anonymous payload.
5. `DeleteManga`: success path removes entity from db context and returns anonymous payload.
6. `Search`: empty and non-empty list branches produce different messages.
7. `SortByGenre`: empty and non-empty list branches produce different messages.
8. `MangaOngoing`: empty and non-empty list branches produce different messages.
9. `MangaComplete`: empty and non-empty list branches produce different messages.

## Arrange/Act/Assert Pattern

- Arrange: create db context with `ControllerTestHelper.CreateDbContext()`, set up `Mock<IMangaService>`, create controller.
- Act: call exactly one controller action.
- Assert: verify action result type and payload values.
- Verify interactions where meaningful (`UploadImage` call counts, service method parameters).

For file-upload branches, use `ControllerTestHelper.CreateFormFile()` and verify:

```csharp
mangaService.Verify(x => x.UploadImage(It.IsAny<IFormFile>()), Times.Once);
```

For no-file branches:

```csharp
mangaService.Verify(x => x.UploadImage(It.IsAny<IFormFile>()), Times.Never);
```

## Data Setup Notes

When returning `Manga` in mocks, use fields that exist in current model (`ReleaseDate`, `EndDate`, `GenreIds`, etc.).
Do not use obsolete fields.

Recommended sample object:

```csharp
new Manga
{
    Id = 1,
    Title = "Manga",
    Status = "Ongoing",
    AuthorId = 1,
    GenreIds = new List<int> { 1, 2 },
    ReleaseDate = new DateOnly(2024, 1, 1),
    EndDate = new DateOnly(2024, 12, 31)
}
```

## Output Contract When This Skill Is Invoked

Return results in this order:

1. Brief test plan (which endpoints/branches are covered).
2. Exact files changed.
3. Final test code updates.
4. Validation outcome from running relevant tests (or clear note if execution was not possible).

## Completion Checklist

Before finishing:

1. Ensure tests assert the correct payload shape per endpoint.
2. Ensure anonymous payload tests use `GetAnonymousProperty`.
3. Ensure at least one error-path assertion checks `ExceptionBody` and status code.
4. Ensure no stale model fields appear in tests.
5. Ensure naming follows `MethodName_Condition_ExpectedResult`.
