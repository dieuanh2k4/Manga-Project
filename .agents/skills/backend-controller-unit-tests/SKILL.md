---
name: backend-controller-unit-tests
description: Generate or update xUnit unit tests for ASP.NET Core controllers in ProjectManga backend. Use this whenever the user asks to create tests for controller(s), add missing tests in backend.Tests/Controllers, improve controller coverage, or says "tao unit test cho controller" / "tao test backend". Prefer using this skill even for a single controller so test style stays consistent with ControllerTestHelper, Moq, and ApiControllerBase exception handling.
---

# Backend Controller Unit Tests (ProjectManga)

## Goal

Create and maintain controller unit tests so every concrete controller in backend/src/Controllers has a corresponding test class in backend.Tests/Controllers.

Exclude ApiControllerBase from test generation.

## Project conventions to preserve

- Use xUnit and Moq.
- Use in-memory DbContext from ControllerTestHelper.CreateDbContext().
- Use ControllerTestHelper.CreateLogger<TController>() for logger dependencies.
- Use ControllerTestHelper.CreateFormFile(...) for upload scenarios.
- For anonymous response objects, read fields with ControllerTestHelper.GetAnonymousProperty<T>(...).
- Keep existing Vietnamese response-message assertions when actions return message fields.

## Use this skill when

- User asks to generate unit tests for backend controllers.
- User asks to fill missing tests under backend.Tests/Controllers.
- User asks to improve controller-level test coverage after API changes.

## Do not use this skill for

- Integration tests, end-to-end tests, or API test collections.
- Service-layer or repository-layer tests.
- Flutter/web frontend tests.

## Required output

- Create or update only controller test files in backend.Tests/Controllers.
- Ensure one test class per controller: <ControllerName>Tests.
- Keep test method names readable with pattern Action_ExpectedBehavior.
- Provide a short final summary listing created and updated test files.

## Constraints

- Do not create eval artifacts.
- Do not create any workspace folder for benchmark/review.
- Do not create evals/evals.json.
- Do not run eval-viewer workflows.

## Workflow

1. Discover controllers in backend/src/Controllers/\*Controller.cs.
2. Ignore ApiControllerBase.cs.
3. Discover existing tests in backend.Tests/Controllers/\*ControllerTests.cs.
4. Build a missing-controller list and a needs-update list.
5. For each target controller, inspect constructor dependencies and action methods.
6. Generate or update tests using existing conventions.
7. Run tests and fix compile/runtime issues.
8. Report what was generated and what still needs manual decisions.

## Controller test design rules

For each public action method, aim to cover:

- A success path that verifies response type and payload.
- At least one failure path when exceptions are handled by ReturnException(...).

When creating failure tests, prefer meaningful domain exceptions:

- backend.src.Exceptions.Result -> expect 400 with ExceptionBody.
- KeyNotFoundException -> expect 404 with ExceptionBody.
- UnauthorizedAccessException -> expect 401 with ExceptionBody.
- Unexpected Exception -> expect 500 with generic message.

## Claims-aware endpoints

For actions that use GetCurrentUserId(), set HttpContext user claims on the controller before invoking action methods.

Use this pattern:

- Set ControllerContext with DefaultHttpContext.
- Assign HttpContext.User with ClaimsPrincipal containing ClaimTypes.NameIdentifier.

Also include at least one missing-claim scenario that returns 401 through ReturnException.

## File and form-data endpoints

When an action takes IFormFile or List<IFormFile>:

- Build file(s) using ControllerTestHelper.CreateFormFile(...).
- Verify the expected upload/service call is invoked with Moq Verify.
- Assert returned message/data payload.

## Data access endpoints

When a controller action directly uses ApplicationDbContext:

- Seed only the minimal entities required for test execution.
- Save changes before action invocation.
- Keep entities minimal but valid for required fields.

## Quality checklist before finishing

- New test files compile.
- No duplicate test names in a class.
- All updated tests pass via dotnet test backend.Tests/backend.Tests.csproj.
- Assertions are specific (status code, payload type, key fields).
- Tests remain deterministic and independent.

## Suggested execution commands

Run from solution root:

- dotnet test backend.Tests/backend.Tests.csproj

If needed, run filtered tests while iterating:

- dotnet test backend.Tests/backend.Tests.csproj --filter FullyQualifiedName~ControllerName

## Final response format

Return:

1. Created test files.
2. Updated test files.
3. Controllers now covered.
4. Any remaining blockers (if a controller requires unclear business assumptions).
