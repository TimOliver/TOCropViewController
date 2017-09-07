# CHANGELOG
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased

## 2.1.0 - 2017-09-07
### Added
- Added a CHANGELOG. (Yay!)
- `TOCropViewController.title` property will display a title label above the crop view box.
- Added more thorough checks to ensure both all delegate and completion block handlers execute in the right order.


### Changed
- Fixed scroll view insets to work properly with new iOS 11 assumptions.
- Fixed crop box frame resizing to properly clamp when it touches an outer boundary.
