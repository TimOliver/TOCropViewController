//
//  TOImageFrame.h
//  TOCropViewControllerExample
//
//  Created by Neal Manaktola on 8/5/21.
//  Copyright © 2021 Tim Oliver. All rights reserved.
//

#ifndef TOImageFrame_h
#define TOImageFrame_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 This class is used to represent a frame in an animated image. Note, this class was borrowed from SDWebImage
 
 */
@interface TOImageFrame : NSObject

/**
 The image of current frame. You should not set an animated image.
 */
@property (nonatomic, strong, readonly, nonnull) UIImage *image;
/**
 The duration of current frame to be displayed. The number is seconds but not milliseconds. You should not set this to zero.
 */
@property (nonatomic, readonly, assign) NSTimeInterval duration;

/**
 Create a frame instance with specify image and duration
 @param image current frame's image
 @param duration current frame's duration
 @return frame instance
 */
+ (nonnull instancetype)frameWithImage:(nonnull UIImage *)image duration:(NSTimeInterval)duration;

@end

#endif /* TOImageFrame_h */
