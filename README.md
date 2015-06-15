# TOCropViewController

![TOCropViewController](screenshot.jpg)

[![CI Status](http://img.shields.io/travis/TimOliver/TOCropViewController.svg?style=flat)](http://api.travis-ci.org/TimOliver/TOCropViewController.svg)
[![Version](https://img.shields.io/cocoapods/v/TOCropViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)
[![License](https://img.shields.io/cocoapods/l/TOCropViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)
[![Platform](https://img.shields.io/cocoapods/p/TOCropViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)

TOCropViewController is an open-source `UIViewController` subclass built to allow users to perform basic manipulation on UIImage objects; specifically cropping and some basic rotations. It has been designed with the iOS 8 Photos app in mind, and as such, behaves in an already familiar way.

## Features
* Crop images by dragging the edges of a grid overlay.
* Rotate images in 90-degree segments.
* Clamp the crop box to a specific aspect ratio.
* A reset button to completely undo all changes.
* iOS 7/8 translucency to make it easier to view the cropped region.
* The choice of having the controller return the cropped image to a delegate, or immediately pass it to a `UIActivityViewController`.
* A custom animation and layout when the device is rotated to landscape mode.
* Custom 'opening' and 'dismissal' animations.

## Technical Requirements
iOS 7.0 or above.

## License
TOCropViewController is licensed under the MIT License, please see the LICENSE file.