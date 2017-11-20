# CHANGELOG
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

## 2.3.4 - 2017-11-20

### Fixed
- A bug where restoring a previous crop state with a different angle than 0 and then rotating the image would result in a distorted image.

## 2.3.3 - 2017-11-19

### Fixed
- Fixed a broken animation where restoring from a cropped image would animate higher than it needed on iPhone X.

## 2.3.2 - 2017-11-19

### Added
- A Swift wrapper library named `CropViewController`.
- Proper handling for when swiping near the Control Center and Notification Center edges on iOS 11.

### Fixed
- An animation distortion that occurred when restoring from a previous crop view frame.
- A crash that occurred when restoring to a rotated image.
- A bug where rotating images on iPhone X in landscape would result in images incorrectly being positioned.

## 2.1.1 - 2017-11-16

### Added
- Support for iPhone X.

### Changed
- Fixed missing semicolons in iOS 7 code brace.
- Fixed minor issue with certain `nullable` properties being marked as `nonnull`.
- Made the clockwise rotation button visible by default.

### Fixed
- Broken rotation animations in iOS 11.
- Incorrect inset of crop content when status bar is visible.
- General cleanup of the codebase

## 2.1.0 - 2017-09-07
### Added
- Added a CHANGELOG. (Yay!)
- `TOCropViewController.title` property will display a title label above the crop view box.
- Added more thorough checks to ensure both all delegate and completion block handlers execute in the right order.


### Changed
- Fixed scroll view insets to work properly with new iOS 11 assumptions.
- Fixed crop box frame resizing to properly clamp when it touches an outer boundary.
