---
name: app-manga-flutter-tests
description: Create and run fast Flutter unit and widget tests for app_manga, plus local integration tests and golden tests. Use this skill whenever the user asks to add, update, fix, or run Flutter tests in app_manga, especially widget tests, golden tests, UI snapshots, mocking network, or golden_toolkit usage.
---

# app-manga-flutter-tests

A skill for adding and running fast Flutter tests for app_manga, with strict local-only behavior and reusable helpers for golden setup and network mocking.

## Scope and expectations

- Target project root: app_manga/
- Test types: unit tests, widget tests, local integration tests (flutter test integration_test)
- Golden tests use golden_toolkit
- All network calls must be mocked
- All network images must be mocked via mockNetworkImagesFor

## Required conventions

- Unit and widget tests live in test/
- Integration tests live in integration_test/
- Shared helpers live in test/helpers/
- Golden output directory is test/goldens/
- Golden device config: Device name "Medium Phone", size 412x915 dp, pixelRatio 2.625

## Helper files

Always create or update these helper files and reuse them in tests:

- test/helpers/golden_config.dart
- test/helpers/mock_network.dart

## Golden configuration

Configure a single device for goldens:

- Device name: Medium Phone
- Size: 412x915 dp
- Pixel ratio: 2.625
- Output: test/goldens/

Prefer a shared helper that exposes:

- a function to load the device builder and register the device
- a wrapper that applies the golden config and fonts

## Network mocking

All tests must avoid real network calls:

- Use mockito or mocktail for API services
- For widgets that render images from network, wrap test body with mockNetworkImagesFor
- Provide a reusable helper in test/helpers/mock_network.dart so tests are concise

## Test commands

Default commands (local runs):

- All unit/widget tests: flutter test
- Single test file: flutter test test/<file>_test.dart
- Integration tests: flutter test integration_test

If the user asks for a single test, target the specific file first.

## Workflow

1. Identify the test type (unit, widget, integration, golden).
2. Ensure helpers exist and are reused.
3. Write tests using clear arrange/act/assert structure.
4. For goldens, wrap in the golden configuration and store goldens in test/goldens/.
5. Mock all API calls and images.
6. Offer to run tests when requested.

## Output expectations

When adding tests:

- Create or update helper files in test/helpers/.
- Add tests under test/ or integration_test/.
- Mention any required pubspec dev_dependencies (e.g., golden_toolkit, mocktail).

When running tests:

- Use flutter test or flutter test integration_test based on scope.
- Keep output concise and surface failing tests first.

## Example patterns

### Golden test skeleton

- Uses golden_toolkit.
- Uses the shared golden config.
- Uses mockNetworkImagesFor.

### Widget test skeleton

- Uses mocktail or mockito to mock API service.
- Uses the shared mock network helper.

### Integration test

- Runs via flutter test integration_test.
- Avoids real network calls by injecting mocks.

## Notes

- Keep tests fast; avoid sleeps and real IO.
- Prefer deterministic widget rendering (fixed size, fonts loaded via golden_toolkit).