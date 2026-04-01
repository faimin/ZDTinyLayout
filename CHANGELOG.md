# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Added `NSLayoutConstraint.tl.activate {}` / `deactivate {}` batch APIs with result-builder support.
- Added direct array-expression support in `tl.addComponents {}` (you can now place `[any ZDTLComponentsProtocol]` directly in the block).

### Changed
- Renamed `VisualLayoutNamespace` to `ZDTinyLayoutNamespace`.
- Renamed `VisualLayoutNamespaceCompatible` to `ZDTinyLayoutNamespaceCompatible`.
- Split Visual Layout API to avoid return-type ambiguity: `tl.layoutConstraints {}` returns `[NSLayoutConstraint]`.
- Split Visual Layout API to avoid return-type ambiguity: `tl.layout {}` returns `Base` for chaining.
- Updated README examples to the current `tl` namespace APIs.

### Fixed
- Fixed `ZDTinyLayoutConstraintBuilder` conditional branch handling so `if-else` branches containing multiple constraints compile correctly.
