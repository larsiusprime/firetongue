# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.1.0 - 2022-01-17
This release marks the transition to [Eric Myllyoja](https://github.com/MasterEric) as the lead maintainer for the repository.
### New Contributors
- @MasterEric made his first contributions to the project.
- @DotWith made their first contribution in https://github.com/larsiusprime/firetongue/pull/45
### Added
- Added a new `FireTongue.initialize({})` command, which utilizes a parameter object for better handling of additional/optional parameters.
  - The old `FireTongue.init(...)` command is still available, but marked as deprecated and may be removed in the next major release.
### Changed
- Multiple finished callbacks can now be registered at once.
  - Call `addFinishedCallback` to add a callback, `removeFinishedCallback` to clear an already-registered callback, and `clearFinishedCallbacks` to clear all registered callbacks.
- The `FireTongue.directory` property is now public.
  - Note this value is read-only, and should be changed only by calling `FireTongue.initialize({ directory: ... })`.
- Reworked the changelog to a standardised format.
- Moved the TSV and CSV handlers to their own sub-package.
- Improved the documentation.
### Fixed
- Fixed a bug where calling `clear()` would clear any registered finished callbacks.


## [2.1.0] - 2020-02-13
This version was only available through the `develop` branch of the repository.
### Added
- Added the ability to override the string replacement method.
  - Defaults to `StringTools.replace()`.
### Changed
- Redirects are now fully recursive.
- Added hxformat to the project to standardize code style.
- Country flags are no longer recommended as icons.
  - It is instead recommended that you instead specify language names in your interface, in both the current and native language.
  - Handling for the `_flags` folder has been removed and replaced with the `_icons` folder.
  - Removed country flags from the sample project.
## Fixed
- Fixed several deprecation warnings.


## [2.0.0] - 2016-02-21
This rework moves loading logic into a Getter class and enables custom loading methods. It also removes all third-party dependencies.
### Added
- Added ability to do partial redirects with `<RE>[]` syntax
### Changed
- Removed all 3rd-party library dependencies
- Refactored loading logic into Getter.hx class
  - OpenFL, Lime, NME, and VanillaSys (haxe standard library for sys targets) loading methods supported by default
  - Custom loading methods can be provided by the user
- TSV/CSV files no longer have to end each line with a delimeter
- Updated documentation
- Updated example
  - uses TSV rather than CSV
  - demonstrate missing locale
### Fixed
- Fix clearIndex() functionality on neko
- Fix "find closest locale" to match closest alphabetical match
- Fix HTML5 and OpenFL next support
- Prevent crash when using non-existent locale
- Fixed bug where `<Q>` is not replaced correctly with '"'
- Fixed bug in flash target
- Cleanup TSV/CSV processing


## [1.0.0] - 2014-05-07
This change represents the initial haxelib release
