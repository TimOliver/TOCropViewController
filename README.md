# TOCropViewController

<p align="center">
<img src="https://github.com/TimOliver/TOCropViewController/blob/master/screenshot.jpg" width="890" style="margin:0 auto" />
</p>

[![CI Status](http://img.shields.io/travis/TimOliver/TOCropViewController.svg?style=flat)](http://api.travis-ci.org/TimOliver/TOCropViewController.svg)
[![CocoaPods](https://img.shields.io/cocoapods/dt/TOCropViewController.svg?maxAge=3600)](https://cocoapods.org/pods/TOCropViewController)
[![Version](https://img.shields.io/cocoapods/v/TOCropViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/TOCropViewController/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/TOCropViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)

TOCropViewController is an open-source `UIViewController` subclass built to allow users to perform basic manipulation on `UIImage` objects; specifically cropping and some basic rotations. It has been designed with the iOS 8 Photos app in mind, and as such, behaves in an already familiar way.

## Features
* Crop images by dragging the edges of a grid overlay.
* Optionally, crop circular copies of images.
* Rotate images in 90-degree segments.
* Clamp the crop box to a specific aspect ratio.
* A reset button to completely undo all changes.
* iOS 7/8 translucency to make it easier to view the cropped region.
* The choice of having the controller return the cropped image to a delegate, or immediately pass it to a `UIActivityViewController`.
* A custom animation and layout when the device is rotated to landscape mode.
* Custom 'opening' and 'dismissal' animations.
* Localized in 18 languages.

## System Requirements
iOS 7.0 or above

## Installation

#### As a CocoaPods Dependency

Add the following to your Podfile:
``` ruby
pod 'TOCropViewController'
```

#### As a Carthage Dependency

Add the following to your Cartfile:
``` 
github "https://github.com/TimOliver/TOCropViewController"
```

#### Manual Installation

Download this project from GitHub, move the subfolder named 'TOCropViewController' over to your project folder, and drag it into your Xcode project.

## Examples
`TOCropViewController` operates around a very strict modal implemention. It cannot be pushed to a `UINavigationController` stack, and must be presented as a full-screen dialog on an existing view controller.

### Basic Implementation
```objc
- (void)presentCropViewController
{
  UIImage *image = ...; //Load an image
  
  TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:image];
  cropViewController.delegate = self;
  [self presentViewController:cropViewController animated:YES completion:nil];
}

- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
  // 'image' is the newly cropped version of the original image
}
```

### Making a Circular Cropped Image
```objc
- (void)presentCropViewController
{
UIImage *image = ...; //Load an image

TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithCroppingStyle:TOCropViewCroppingStyleCircular image:image];
cropViewController.delegate = self;
[self presentViewController:cropViewController animated:YES completion:nil];
}

- (void)cropViewController:(TOCropViewController *)cropViewController didCropToCircularImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
// 'image' is the newly cropped, circular version of the original image
}
```

### Sharing Cropped Images Via a Share Sheet
```objc
- (void)presentCropViewController
{
  UIImage *image = ...; //Load an image
  
  TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:image];
  cropViewController.showActivitySheetOnDone = YES;
  [self presentViewController:cropViewController animated:YES completion:nil];
}
```

### Presenting With a Custom Animation
Optionally, `TOCropViewController` also supports a custom presentation animation where an already-visible copy of the image will zoom in to fill the screen.

```objc
- (void)presentViewController
{
  UIImage *image = ...;
  UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
  CGRect frame = [self.view convertRect:imageView.frame toView:self.view];
  
  TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:image];
  cropViewController.delegate = self;
  [self presentViewController:cropViewController animated:YES completion:nil];
  [cropViewController presentAnimatedFromParentViewController:self fromFrame:frame completion:nil];
}
```

## Architecture of `TOCropViewController`
While traditional cropping UI implementations will usually just have a dimming view with a square hole cut out of the middle, `TOCropViewController` goes about its implementation a little differently.

<p align="center">
<img src="https://raw.githubusercontent.com/TimOliver/TOCropViewController/master/breakdown.jpg" width="702" style="margin:0 auto" />
</p>

Since there are two views that are overlaid over the image (A dimming view and a translucency view), trying to cut a hole open in both of them would be rather complex. Instead, an image view is placed in a scroll view in the background, and a copy of the image view is placed on top, inside a container view that is clipped to the designated cropping size. The size and position of the foreground image is then made to match the background view, creating the illusion that there is a hole in the dimming views, and minimising the number of views onscreen.

## Credits
`TOCropViewController` was originally created by [Tim Oliver](http://twitter.com/TimOliverAU) as a component for [iComics](http://icomics.co), a comic reader app for iOS.

Thanks also goes to `TOCropViewController`'s growing list of [contributors](https://github.com/TimOliver/TOCropViewController/graphs/contributors)!

iOS Device mockups used in the screenshot created by [Robbie Pearce](http://robbiepearce.com/devices).

## License
TOCropViewController is licensed under the MIT License, please see the [LICENSE](LICENSE) file.
