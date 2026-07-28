//
//  CropViewController.h
//
//  Copyright 2017-2026 Timothy Oliver. All rights reserved.
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

#import <UIKit/UIKit.h>

// The Objective-C headers ship in both the TOCropViewController and CropViewController
// frameworks, so they can only use framework-relative imports here, where the framework
// name is unambiguous. The shared headers themselves keep quoted imports, with the
// module verifier's quoted-include diagnostic disabled on the framework targets.
#if __has_include(<CropViewController/TOCropViewController.h>)
#import <CropViewController/TOCropToolbar.h>
#import <CropViewController/TOCropView.h>
#import <CropViewController/TOCropViewConstants.h>
#import <CropViewController/TOCropViewController.h>
#import <CropViewController/TOCropViewControllerAspectRatioPreset.h>
#import <CropViewController/UIImage+CropRotate.h>
#else
#import "TOCropToolbar.h"
#import "TOCropView.h"
#import "TOCropViewConstants.h"
#import "TOCropViewController.h"
#import "TOCropViewControllerAspectRatioPreset.h"
#import "UIImage+CropRotate.h"
#endif

FOUNDATION_EXPORT double CropViewControllerVersionNumber;
FOUNDATION_EXPORT const unsigned char CropViewControllerVersionString[];
