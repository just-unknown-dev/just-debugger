## 0.1.0

### Breaking

- `EcsDebuggerOverlay` → `DebuggerOverlay` (it shows the ECS, performance, memory and log tabs; file `debugger_overlay.dart`).
- The `JustDebuggerSourceBinding` extension and its `bindToSources(...)` are removed: call `JustDebuggerController.bind(...)`, which takes the same arguments.
- `lib/src` is laid out by feature (`snapshots/`, `controller/`, `widgets/`); import `package:just_debugger/just_debugger.dart`, not `src/` files.

### Added

- `JustDebuggerController.isCleaningMemory`, and `JustDebuggerController.maxLogEntries` (200).
- Dartdoc on every public declaration, including the keys each `fromStats` reads.
- `example/main.dart`.
- `topics` in the pubspec.
- Tests mirrored to `lib/src`, and `test/library_layout_test.dart`, which checks the barrels, `@internal` helpers, import loops and the layer order (`snapshots` → `controller` → `widgets`).

### Changed

- The overlay and the memory panel name no engine package: "Engine + Game Footprint" is "App Footprint", and the memory and cleanup lines speak of "the app", "pooled memory" and "the attached cleanup action".
- Free Up RAM is disabled while a cleanup runs.
- `DebuggerHealth` has its own file.
- The flutter constraint is `>=3.41.0`, the Flutter that `sdk: ^3.11.0` already needs (it was `>=1.17.0`).

### Fixed

- A stats provider that throws no longer escapes the poll timer on every tick. A refresh is all or nothing: on an error every snapshot keeps its last value, the error is logged once (`DebuggerLogLevel.error`, category `debugger`), and polling goes on quietly until a refresh succeeds. A throwing provider no longer throws out of `bind` either.
- A memory cleanup that ends after the controller is disposed no longer throws out of the button handler; `log` does nothing once disposed. A second cleanup request while one runs joins it instead of running two at once.
- A non-finite stat (an `fps` of `Infinity`) reads as missing instead of throwing `UnsupportedError`; a stat map that is not a map (`systemTimesMs`, `counters`) reads as empty instead of throwing a cast error, and a `systemMemory` map with non-string keys is read.

## 0.0.1

Initial release of **just_debugger**.

### Added

- debugger controller for managing runtime snapshots, logs, and overlay state
- ECS snapshot support for entity, system, archetype, and component visibility
- performance and memory snapshot models
- reusable Flutter widgets for overlay, inspector, performance, memory, and log panels
- simple integration API for binding debugger views to runtime stats providers
- package documentation (README)
