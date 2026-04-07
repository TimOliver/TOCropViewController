//
//  TOCropViewControllerAspectRatioPreset.h
//
//  Copyright 2015-2025 Timothy Oliver. All rights reserved.
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
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOCropViewControllerAspectRatioPreset : NSObject

@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) NSString *title;

/// The original aspect ratio of the image (CGSizeZero)
@property (class, nonatomic, readonly) CGSize original;

/// A square aspect ratio (1:1)
@property (class, nonatomic, readonly) CGSize square;

/// A 3:2 aspect ratio
@property (class, nonatomic, readonly) CGSize ratio3x2;

/// A 5:3 aspect ratio
@property (class, nonatomic, readonly) CGSize ratio5x3;

/// A 4:3 aspect ratio
@property (class, nonatomic, readonly) CGSize ratio4x3;

/// A 5:4 aspect ratio
@property (class, nonatomic, readonly) CGSize ratio5x4;

/// A 7:5 aspect ratio
@property (class, nonatomic, readonly) CGSize ratio7x5;

/// A 16:9 aspect ratio
@property (class, nonatomic, readonly) CGSize ratio16x9;

+ (NSArray<TOCropViewControllerAspectRatioPreset *> *)portraitPresets;
+ (NSArray<TOCropViewControllerAspectRatioPreset *> *)landscapePresets;

- (nonnull instancetype)initWithSize:(CGSize)size title:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
