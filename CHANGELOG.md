x.y.z Release Notes (yyyy-MM-dd)
=============================================================

2.8.0 Release Notes (2025-09-23)
=============================================================

## Added

- Deprecated iOS 11 as it no longer supported in Xcode 26.

## Fixed

- A bug in iOS 26 where the toolbar buttons would appear misaligned.

2.7.4 Release Notes (2024-05-08)
=============================================================

## Fixed

* Another invalid configuration in the privacy manifest. ([#580](https://github.com/TimOliver/TOCropViewController/pull/580))

2.7.3 Release Notes (2024-04-20)
=============================================================

## Fixed

* An invalid configuration in the privacy manifest. ([#576](https://github.com/TimOliver/TOCropViewController/pull/576))
* Removed deprecated Core Graphics render APIs. ([#578](https://github.com/TimOliver/TOCropViewController/pull/578)) 

2.7.2 Release Notes (2024-04-08)
=============================================================

## Added

* Initial support for visionOS. ([#572](https://github.com/TimOliver/TOCropViewController/pull/572))

## Fixed

* A crash when tapping the aspect ratio button. ([#573](https://github.com/TimOliver/TOCropViewController/pull/573))

2.7.1 Release Notes (2024-04-06)
=============================================================

## Enhancements

* Added better support for Swift Concurrency. ([#563](https://github.com/TimOliver/TOCropViewController/pull/563))

2.7.0 Release Notes (2024-04-06)
=============================================================

## Added

* Set minimum version to iOS 11. ([#571](https://github.com/TimOliver/TOCropViewController/pull/571))
* A `PrivacyInfo.xcprivacy` file to the resource bundle in order to be compliant with Apple's new privacy requirements. ([#569](https://github.com/TimOliver/TOCropViewController/pull/569))
* A new aspect ratio setting of 16:6. ([#557](https://github.com/TimOliver/TOCropViewController/pull/557))
* Ukranian localization. ([#529](https://github.com/TimOliver/TOCropViewController/pull/529))

## Enhancements

* Updated project for Xcode 15. ([#571](https://github.com/TimOliver/TOCropViewController/pull/571))
* Exposed `reverseContentLayout` as an external property. ([#568](https://github.com/TimOliver/TOCropViewController/pull/568))
* Exposed `cropView` as an external property. ([#532](https://github.com/TimOliver/TOCropViewController/pull/532))
* Added a way to revert back to the original aspect ratio after selecting a custom ratio from the list. ([#543](https://github.com/TimOliver/TOCropViewController/pull/543))

## Fixed

* A deprecation warning when trying to detect the current device's idiom. (([#543](https://github.com/TimOliver/TOCropViewController/pull/543))
* Added in a variety of properties that were available in `TOCropViewController` but not `CropViewController`. (([#541](https://github.com/TimOliver/TOCropViewController/pull/541))


2.6.1 Release Notes (2022-01-23)
=============================================================

## Fixed

* Removed unneeded layout calculation. ([#485](https://github.com/TimOliver/TOCropViewController/pull/485))
* Incorrect accessibility label for the 'Reset' button. ([#487](https://github.com/TimOliver/TOCropViewController/pull/487))
* Improved Japanese localization. ([#502](https://github.com/TimOliver/TOCropViewController/pull/502))
* Fixed an API typo in the Swift interface. ([#504](https://github.com/TimOliver/TOCropViewController/pull/504))
* Fixed incorrect comment formatting producing HTML errors. ([#507](https://github.com/TimOliver/TOCropViewController/pull/507))

2.6.0 Release Notes (2020-12-30)
=============================================================

## Added

* Extremely basic support for Mac Catalyst, with an accompanying sample app. ([#464](https://github.com/TimOliver/TOCropViewController/pull/464))
* Switched to using system SF Symbol icons on iOS 13.0 and up. ([#455](https://github.com/TimOliver/TOCropViewController/pull/455))
* `doneButtonColor` and `cancelButtonColor` properties to control the color of the main call-to-action buttons in the toolbar. ([#436](https://github.com/TimOliver/TOCropViewController/pull/436))
* `showOnlyIcons` property to disable showing the "Cancel" and "Done" text labels. ([#438](https://github.com/TimOliver/TOCropViewController/pull/438))
* `commitCurrentCrop()` method to programmatically simulate tapping the 'Done' button. ([#441](https://github.com/TimOliver/TOCropViewController/pull/441))
* Added Catalan localization. ([#449](https://github.com/TimOliver/TOCropViewController/pull/449))

## Fixed
* Fixed an issue where visible snapping would occur during the presentation animation on iPad models with rounded corners. ([#461](https://github.com/TimOliver/TOCropViewController/pull/461))
* Improved logic for detecting whether the controller needs to be popped or dismissed from its current presentation context.  ([#443](https://github.com/TimOliver/TOCropViewController/pull/443))
* Fixed a CocoaPods installation issue where warnings would be displayed about importing the header references needed for SPM support. ([#445](https://github.com/TimOliver/TOCropViewController/pull/445))
* Added provisions for later versions of SPM no longer supporting iOS 8. ([#448](https://github.com/TimOliver/TOCropViewController/pull/448))
* Added `allowedAspectRatios` property to Swift layer. ([#453](https://github.com/TimOliver/TOCropViewController/pull/453))

## Enhancements
* Added back in resource support for SPM on Xcode 12. ([#466](https://github.com/TimOliver/TOCropViewController/pull/466))
* Fixed a potential performance slow-down by replacing a custom mask, with standard `CALAyer` rounded corners for circular crops. ([#462](https://github.com/TimOliver/TOCropViewController/pull/462))
* Rewrote how rotated regions of an image are extracted to not rely on Core Animation hackery. ([#463](https://github.com/TimOliver/TOCropViewController/pull/463))

2.5.5 Release Notes (2020-10-01)
=============================================================

## Fixed 

* Duplicate header build warnings when installing via CocoaPods. ([#432](https://github.com/TimOliver/TOCropViewController/pull/432))

2.5.4 Release Notes (2020-07-20)
=============================================================

## Fixed

* Various fixes and improvements to SPM support. ([#417](https://github.com/TimOliver/TOCropViewController/pull/417) [#422](https://github.com/TimOliver/TOCropViewController/pull/422))

2.5.3 Release Notes (2020-06-11)
=============================================================

## Added

* SPM Support. ([#413](https://github.com/TimOliver/TOCropViewController/pull/413))
* The ability to explicitly show and hide the 'Cancel' and 'Done' buttons in the toolbar. ([#392](https://github.com/TimOliver/TOCropViewController/pull/392))

## Fixed

* A memory crash caused by improper `self` usage in delegates between multiple instances of the Swift crop view controller. ([#409](https://github.com/TimOliver/TOCropViewController/pull/409))

2.5.2 Release Notes (2019-10-23)
=============================================================

## Added

* Brazilian Portuguese Language Support ([#380](https://github.com/TimOliver/TOCropViewController/issues/380))

## Fixed

* A visual glitch that would occur in iOS 13 because the Swift view controller wasn't explicitly marked as full screen. ([#385](https://github.com/TimOliver/TOCropViewController/issues/385))
* A visual glitch where the image would snap upwards during the presentation animation on non-Face ID devices. ([#387](https://github.com/TimOliver/TOCropViewController/issues/387))
* A bug where subclassing the class in Swift would fail because it wasn't using the desginated initializer. ([#379](https://github.com/TimOliver/TOCropViewController/issues/379))

2.5.1 Release Notes (2019-07-08)
=============================================================

## Added

* Finnish Language Support ([#360](https://github.com/TimOliver/TOCropViewController/pull/360))

## Enhancements

* Improved the UX of the cancellation dialog by changing the buttons from affirmative actions to explicit actions. ([#362](https://github.com/TimOliver/TOCropViewController/pull/362))

## Fixed
* A crash that would occur if the cancellation confirmation dialog was attempted to be displayed on iPad. ([#362](https://github.com/TimOliver/TOCropViewController/pull/362))

2.5.0 Release Notes (2019-04-21)
=============================================================

## Added
- Swift 5.0 Support ([#343](https://github.com/TimOliver/TOCropViewController/pull/343))
- Persian Language Support ([#337](https://github.com/TimOliver/TOCropViewController/pull/337))
- Added `customAspectRatioName` property to expose the custom aspect ratio as a selectable choice ([#344](https://github.com/TimOliver/TOCropViewController/pull/344))

## Fixed
- Made delegate in `CropViewController` weak. ([#338](https://github.com/TimOliver/TOCropViewController/pull/338))

2.4.0 Release Notes (2018-12-01)
=============================================================

## Added
- Swift 4.2 Support
- Romanian and Hungarian localizations.
- The ability to show only certain aspect ratios.
- A setting to allow confirmation before cancelling a crop.

## Fixed
- Fixed layout issue on the new iPad Pro
- Fixed issues with the aspect ratio settings when zooming out.
- Fixed an issue when rotating images would sometimes break.
- A bug where the completion handler of the cropping operation wouldn't fire.

## Removed
- iOS 7 Support

2.3.8 Release Notes (2018-08-15)
=============================================================

## Added
- Image does not invert when 'Smart Invert Colors' is enabled.

## Fixed
- A Core Animation crash when the image size is initially NaN.
- The image being positioned slightly higher than it should be on iPhone X.
- An imprecision issue where the reported cropping frame was out of bounds.

2.3.7 Release Notes (2018-07-24)
=============================================================

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

2.3.6 Release Notes (2018-01-02)
=============================================================

### Added
- `aspectRatioLockDimensionSwapEnabled` to enable or disable the crop view controller aspect ratio dimensions to swap when the aspect ratio is locked.

### Changed
- Moved all Objective-C code into `CropViewController` framework to avoid needing importing `TOCropViewController` framework.

### Fixed
- Size calculation for one of the tool bar buttons was incorrect.
- Optimized toolbar layout code to be more efficient.
- Title label was being clipped by the sensour housing on iPhone X.

2.3.5 Release Notes (2017-12-09)
=============================================================

## Fixed
- Init methods in `CropViewController` weren't public.
- Simplified the handling of making rotation buttons visible and hidden.
- Tool bar icon misalignment error on iOS 10 and below.

2.3.4 Release Notes (2017-11-20)
=============================================================

## Fixed
- A bug where restoring a previous crop state with a different angle than 0 and then rotating the image would result in a distorted image.

2.3.3 Release Notes (2017-11-19)
=============================================================

## Fixed
- Fixed a broken animation where restoring from a cropped image would animate higher than it needed on iPhone X.

2.3.2 Release Notes (2017-11-19)
=============================================================

## Added
- A Swift wrapper library named `CropViewController`.
- Proper handling for when swiping near the Control Center and Notification Center edges on iOS 11.

## Fixed
- An animation distortion that occurred when restoring from a previous crop view frame.
- A crash that occurred when restoring to a rotated image.
- A bug where rotating images on iPhone X in landscape would result in images incorrectly being positioned.

2.1.1 Release Notes (2017-11-16)
=============================================================

## Added
- Support for iPhone X.

## Changed
- Fixed missing semicolons in iOS 7 code brace.
- Fixed minor issue with certain `nullable` properties being marked as `nonnull`.
- Made the clockwise rotation button visible by default.

## Fixed
- Broken rotation animations in iOS 11.
- Incorrect inset of crop content when status bar is visible.
- General cleanup of the codebase

2.1.0 Release Notes (2017-09-07)
=============================================================

## Added
- Added a CHANGELOG. (Yay!)
- `TOCropViewController.title` property will display a title label above the crop view box.
- Added more thorough checks to ensure both all delegate and completion block handlers execute in the right order.
- 
## Changed
- Fixed scroll view insets to work properly with new iOS 11 assumptions.
- Fixed crop box frame resizing to properly clamp when it touches an outer boundary.
