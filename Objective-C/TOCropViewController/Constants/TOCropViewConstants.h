//
//  TOCropViewConstants.h
//
//  Copyright 2015-2022 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>

/**
 The shape of the cropping region of this crop view controller
 */
typedef NS_ENUM(NSInteger, TOCropViewCroppingStyle) {
    TOCropViewCroppingStyleDefault,     // The regular, rectangular crop box
    TOCropViewCroppingStyleCircular     // A fixed, circular crop box
};

/**
 Preset values of the most common aspect ratios that can be used to quickly configure
 the crop view controller.
 */
typedef NS_ENUM(NSInteger, TOCropViewControllerAspectRatioPreset) {
    TOCropViewControllerAspectRatioPresetOriginal,
    TOCropViewControllerAspectRatioPresetSquare,
    TOCropViewControllerAspectRatioPreset3x2,
    TOCropViewControllerAspectRatioPreset5x3,
    TOCropViewControllerAspectRatioPreset4x3,
    TOCropViewControllerAspectRatioPreset5x4,
    TOCropViewControllerAspectRatioPreset7x5,
    TOCropViewControllerAspectRatioPreset16x9,
    TOCropViewControllerAspectRatioPresetCustom
};

/**
 Whether the control toolbar is placed at the bottom or the top
 */
typedef NS_ENUM(NSInteger, TOCropViewControllerToolbarPosition) {
    TOCropViewControllerToolbarPositionBottom,  // Bar is placed along the bottom in portrait
    TOCropViewControllerToolbarPositionTop     // Bar is placed along the top in portrait (Respects the status bar)
};

static inline NSBundle *TO_CROP_VIEW_RESOURCE_BUNDLE_FOR_OBJECT(NSObject *object) {
#if SWIFT_PACKAGE
	// SPM is supposed to support the keyword SWIFTPM_MODULE_BUNDLE
	// but I can't figure out how to make it work, so doing it manually
   	NSString *bundleName = @"TOCropViewController_TOCropViewController";
#else
	NSString *bundleName = @"TOCropViewControllerBundle";
#endif
    NSBundle *resourceBundle = nil;
    NSBundle *classBundle = [NSBundle bundleForClass:object.class];
    NSURL *resourceBundleURL = [classBundle URLForResource:bundleName withExtension:@"bundle"];
    if (resourceBundleURL) {
        resourceBundle = [[NSBundle alloc] initWithURL:resourceBundleURL];
		#ifndef NDEBUG
		if (resourceBundle == nil) {
		    @throw [[NSException alloc] initWithName:@"BundleAccessor" reason:[NSString stringWithFormat:@"unable to find bundle named %@", bundleName] userInfo:nil];
		}
		#endif
    } else {
        resourceBundle = classBundle;
    }
    return resourceBundle;
}
