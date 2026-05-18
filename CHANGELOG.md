# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0]

### Changed
- Introduces "Stackable", a declarative UIStackView builder for iOS that utilizes result builders to streamline layout construction. Key features include smart spacing, hairlines, visibility binding, and SwiftUI-style convenience builders (VStack, HStack, Spacer). 
- The library has also been updated to Swift 6.0 with extensive @mainactor annotations for concurrency safety. Reviewers pointed out critical technical issues with Objective-C associated objects, specifically the inability to store closures directly and the incorrect use of struct metatypes as keys. 
- Additional feedback suggests removing redundant result builder methods, deleting commented-out code, and replacing deprecated system colors.
- Raised minimum supported platforms to iOS 13, macOS 10.15, tvOS 13, and watchOS 6.
- Replaced internal KVO observations with Combine publishers for visibility and margin binding.

### Fixed
- Fixed Swift 6 concurrency diagnostics in visibility and alignment observation code.

## [0.0.2]

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
