# TOCropViewController

<p align="center">
<img src="https://github.com/TimOliver/TOCropViewController/raw/master/Images/screenshot.jpg" width="900" style="margin:0 auto" />
</p>

[![Build status](https://badge.buildkite.com/f2e7dda942eae2aadb2c456f1f8a9fba97c8feb378ad8638df.svg)](https://buildkite.com/xd-ci/tocropviewcontroller-run-ci)
[![Version](https://img.shields.io/cocoapods/v/TOCropViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/TOCropViewController/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/TOCropViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)
[![Beerpay](https://beerpay.io/TimOliver/TOCropViewController/badge.svg?style=flat)](https://beerpay.io/TimOliver/TOCropViewController)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M4RKULAVKV7K8)
[![Twitch](https://img.shields.io/badge/twitch-timXD-6441a5.svg)](http://twitch.tv/timXD)


`TOCropViewController` is an open-source `UIViewController` subclass to crop out sections of `UIImage` objects, as well as perform basic rotations. It is excellent for things like editing profile pictures, or sharing parts of a photo online. It has been designed with the iOS Photos app editor in mind, and as such, behaves in a way that should already feel familiar to users of iOS.

For Swift developers, `CropViewController` is a Swift wrapper that completely encapsulates `TOCropViewController` and provides a much more native, Swiftier interface.

#### Proudly powering apps by

<p align="center">
<img src="https://github.com/TimOliver/TOCropViewController/raw/master/Images/users.png" width="900" style="margin:0 auto" />
</p>

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
iOS 8.0 or above

## Installation

#### As a CocoaPods Dependency

##### Objective-C

Add the following to your Podfile:
``` ruby
pod 'TOCropViewController'
```

##### Swift

Add the following to your Podfile:
``` ruby
pod 'CropViewController'
```


#### As a Carthage Dependency

Add the following to your Cartfile:
``` 
github "TimOliver/TOCropViewController"
```

#### Manual Installation

All of the necessary source and resource files for `TOCropViewController` are in `Objective-C/TOCropViewController`, and all of the necessary Swift files are in `Swift/CropViewController`.

For Objective-C projects, copy just the `TOCropViewController` directory to your Xcode project. For Swift projects, copy both `TOCropViewController` and `CropViewController` to your project.

## Examples
Using `TOCropViewController` is very straightforward. Simply create a new instance passing the `UIImage` object you wish to crop, and then present it modally on the screen.

While `TOCropViewController` prefers to be presented modally, it can also be pushed to a `UINavigationController` stack.

For a complete working example, check out the sample apps included in this repo.

### Basic Implementation

#### Swift
```swift
func presentCropViewController {
  let image: UIImage = ... //Load an image
  
  let cropViewController = TOCropViewController(image: image)
  cropViewController.delegate = self
  present(cropViewController, animated: true, completion: nil)
}

func cropViewController(_ cropViewController: TOCropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
    // 'image' is the newly cropped version of the original image
}
```

#### Objective-C
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

iOS Device mockups used in the screenshot created by [Pixeden](http://www.pixeden.com).

## License
TOCropViewController is licensed under the MIT License, please see the [LICENSE](LICENSE) file. ![analytics](https://ga-beacon.appspot.com/UA-5643664-16/TOCropViewController/README.md?pixel)
