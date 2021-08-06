//
//  UIImage+Animated.h
//  TOCropViewController
//
//  Created by Neal Manaktola on 8/5/21.
//  Copyright © 2021 Tim Oliver. All rights reserved.
//

#ifndef UIImage_Animated_h
#define UIImage_Animated_h

#import <UIKit/UIKit.h>

@class TOImageFrame;

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (TOAnimated)

/// Creates an animated image from NSData
/// @param data
+ (nullable UIImage *)animatedImageFromData:(nullable NSData *)data;


/// Creates an animated image from NSData
/// @param frames
+ (nullable UIImage *)animatedImageFromFrames:(nullable NSArray<TOImageFrame *> *)frames;


/// Creates an array of image frames from an animated UI
- (nullable NSArray<TOImageFrame *> *)frames;


@end

NS_ASSUME_NONNULL_END

#endif /* UIImage_Animated_h */
