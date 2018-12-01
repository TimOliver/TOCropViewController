# CHANGELOG
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

## 2.4.0 - 2018-12-01

### Added
- Swift 4.2 Support
- Romanian and Hungarian localizations
- The ability to show only certain aspect ratios
- A setting to allow confirmation before cancelling a crop

### Fixed
- Fixed layout issue on the new iPad Pro
- Fixed issues with the aspect ratio settings when zooming out
- Fixed an issue when rotating images would sometimes break
- A bug where the completion handler of the cropping operation wouldn't fire

### Removed
- iOS 7 Support

## 2.3.8 - 2018-08-15

### Added
- Image does not invert when 'Smart Invert Colors' is enabled.

### Fixed
- A Core Animation crash when the image size is initially NaN.
- The image being positioned slightly higher than it should be on iPhone X.
- An imprecision issue where the reported cropping frame was out of bounds.

## 2.3.7 - 2018-07-24

### Added
- `minimumAspectRatio` to set a minimum shape that the cropping box can be scaled to.
- `cropViewPadding` to specifically control how much padding from the edge the crop box gives.
- `cropAdjustingDelay` to specifically control how long the timer waits until animating the crop transition.
- `aspectRatioLockDimensionSwapEnabled` as a stopgap to locking the aspect ratio when rotating the image.


### Fixed
- More thorough sanitation of the final frame calculation.
- A bug where sometimes the square aspect ratio would stop being square.
- A memory cycle leak in the Swift wrapper.
- A broken animation when rotating the device orientation 180 degrees.
- A broken animation if you hit 'reset' right after resizing the crop box.
- Danish and Malaysian localisations weren't being imported properly.

## 2.3.6 - 2018-01-02

### Added
- `aspectRatioLockDimensionSwapEnabled` to enable or disable the crop view controller aspect ratio dimensions to swap when the aspect ratio is locked.

### Changed
- Moved all Objective-C code into `CropViewController` framework to avoid needing importing `TOCropViewController` framework.

### Fixed
- Size calculation for one of the tool bar buttons was incorrect.
- Optimized toolbar layout code to be more efficient.
- Title label was being clipped by the sensour housing on iPhone X.

## 2.3.5 - 2017-12-09

### Fixed
- Init methods in `CropViewController` weren't public.
- Simplified the handling of making rotation buttons visible and hidden.
- Tool bar icon misalignment error on iOS 10 and below.

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
