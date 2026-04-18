# Contributing to just_debugger

Thank you for your interest in contributing to **just_debugger**.

This package provides visual ECS and runtime debugging tools for the Just Game Engine, with a focus on clear diagnostics, lightweight development overlays, and practical inspection workflows.

---

## Code of Conduct

By participating in this project, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

---

## Getting Started

1. Open the monorepo and move to the package directory:

   ```bash
   git clone https://github.com/just-unknown-dev/just-debugger.git
   cd just-debugger
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run checks before making changes:

   ```bash
   flutter analyze
   flutter test
   ```

---

## What to Contribute

Contributions are welcome for:

- debugger overlay improvements
- ECS inspection features
- performance and memory panels
- log filtering and runtime diagnostics
- test coverage
- documentation improvements

---

## Pull Request Guidelines

Before opening a pull request:

1. Keep changes focused and minimal.
2. Add or update tests for changed behavior.
3. Verify the package locally:

   ```bash
   flutter analyze
   flutter test
   ```

4. Use clear commit messages.

Example:

```text
feat(debugger): add runtime overlay controls
fix(debugger): correct log panel filtering
```

---

## Development Notes

This package is a **Flutter package**.

### Priorities

- clarity first
- low overhead in debug workflows
- practical runtime visibility
- no unnecessary complexity

### Guidelines

- Keep the public API small and easy to integrate.
- Prefer lightweight UI and low-friction setup.
- Document all public APIs and examples clearly.
- Avoid unnecessary allocations in frequently refreshed debugger views.
- Add tests when changing controller behavior, logs, or snapshot rendering.

---

## Reporting Issues

When reporting a bug, include:

- what you expected
- what happened instead
- a minimal reproduction
- Flutter and Dart version details
- screenshots or logs if the issue is visual or runtime-related

---

## License

By contributing, you agree that your contributions will be licensed under the repository license.
