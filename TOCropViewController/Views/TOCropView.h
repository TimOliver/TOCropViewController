//
//  TOCropView.h
//
//  Copyright 2015-2016 Timothy Oliver. All rights reserved.
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
#import "TOCropOverlayView.h"

typedef NS_ENUM(NSInteger, TOCropViewCroppingStyle) {
    TOCropViewCroppingStyleDefault,     // The regular, rectangular crop box
    TOCropViewCroppingStyleCircular     // A fixed, circular crop box
};

@class TOCropView;

@protocol TOCropViewDelegate <NSObject>

- (void)cropViewDidBecomeResettable:(TOCropView *)cropView;
- (void)cropViewDidBecomeNonResettable:(TOCropView *)cropView;

@end

@interface TOCropView : UIView

/**
 The image that the crop view is displaying. This cannot be changed once the crop view is instantiated.
 */
@property (nonatomic, strong, readonly) UIImage *image;

/**
 The cropping style of the crop view (eg, rectangular or circular)
 */
@property (nonatomic, assign, readonly) TOCropViewCroppingStyle croppingStyle;

/**
 A grid view overlaid on top of the foreground image view's container.
 */
@property (nonatomic, strong, readonly) TOCropOverlayView *gridOverlayView;

/**
 A delegate object that receives notifications from the crop view
 */
@property (nonatomic, weak) id<TOCropViewDelegate> delegate;

/**
 If false, the user cannot resize the crop box frame using a pan gesture from a corner.
 Default vaue is YES.
 */
@property (nonatomic, assign) BOOL cropBoxResizeEnabled;

/**
 Whether the user has manipulated the crop view to the point where it can be reset
 */
@property (nonatomic, readonly) BOOL canBeReset;

/** 
 The frame of the cropping box in the coordinate space of the crop view
 */
@property (nonatomic, readonly) CGRect cropBoxFrame;

/**
 The frame of the entire image in the backing scroll view
 */
@property (nonatomic, readonly) CGRect imageViewFrame;

/**
 Inset the workable region of the crop view in case in order to make space for accessory views
 */
@property (nonatomic, assign) UIEdgeInsets cropRegionInsets;

/**
 Disable the dynamic translucency in order to smoothly relayout the view
 */
@property (nonatomic, assign) BOOL simpleRenderMode;

/**
 A width x height ratio that the crop box will be rescaled to (eg 4:3 is {4.0f, 3.0f})
 Setting it to CGSizeZero will reset the aspect ratio to the image's own ratio.
 */
@property (nonatomic, assign) CGSize aspectRatio;

/**
 When the cropping box is locked to its current aspect ratio (But can still be resized)
 */
@property (nonatomic, assign) BOOL aspectRatioLockEnabled;

/**
 When the user taps 'reset', whether the aspect ratio will also be reset as well
 Default is YES
 */
@property (nonatomic, assign) BOOL resetAspectRatioEnabled;

/**
 True when the height of the crop box is bigger than the width
 */
@property (nonatomic, readonly) BOOL cropBoxAspectRatioIsPortrait;

/**
 The rotation angle of the crop view (Will always be negative as it rotates in a counter-clockwise direction)
 */
@property (nonatomic, assign) NSInteger angle;

/**
 Hide all of the crop elements for transition animations 
 */
@property (nonatomic, assign) BOOL croppingViewsHidden;

/**
 In relation to the coordinate space of the image, the frame that the crop view is focusing on
 */
@property (nonatomic, assign) CGRect imageCropFrame;

/**
 Set the grid overlay graphic to be hidden
 */
@property (nonatomic, assign) BOOL gridOverlayHidden;

/**
 Create a default instance of the crop view with the supplied image
 */
- (instancetype)initWithImage:(UIImage *)image;

/**
 Create a new instance of the crop view with the specified image and cropping
 */
- (instancetype)initWithCroppingStyle:(TOCropViewCroppingStyle)style image:(UIImage *)image;

/**
 When performing large size transitions (eg, orientation rotation),
 set simple mode to YES to temporarily graphically heavy effects like translucency.
 
 @param simpleMode Whether simple mode is enabled or not
 
 */
- (void)setSimpleRenderMode:(BOOL)simpleMode animated:(BOOL)animated;

/**
 When performing a screen rotation that will change the size of the scroll view, this takes 
 a snapshot of all of the scroll view data before it gets manipulated by iOS.
 Please call this in your view controller, before the rotation animation block is committed.
 */
- (void)prepareforRotation;

/**
 Performs the realignment of the crop view while the screen is rotating.
 Please call this inside your view controller's screen rotation animation block.
 */
- (void)performRelayoutForRotation;

/**
 Reset the crop box and zoom scale back to the initial layout
 
 @param animated The reset is animated
 */
- (void)resetLayoutToDefaultAnimated:(BOOL)animated;

/**
 Changes the aspect ratio of the crop box to match the one specified
 
 @param aspectRatio The aspect ratio (For example 16:9 is 16.0f/9.0f). 'CGSizeZero' will reset it to the image's own ratio
 @param animated Whether the locking effect is animated
 */
- (void)setAspectRatio:(CGSize)aspectRatio animated:(BOOL)animated;

/**
 Rotates the entire canvas to a 90-degree angle. The default rotation is counterclockwise.
 
 @param animated Whether the transition is animated
 */
- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated;

/**
 Rotates the entire canvas to a 90-degree angle
 
 @param animated Whether the transition is animated
 @param clockwise Whether the rotation is clockwise. Passing 'NO' means counterclockwise
 */
- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated clockwise:(BOOL)clockwise;

/**
 Animate the grid overlay graphic to be visible
 */
- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden animated:(BOOL)animated;

/**
 Animate the cropping component views to become visible
 */
- (void)setCroppingViewsHidden:(BOOL)hidden animated:(BOOL)animated;

/**
 Animate the background image view to become visible
 */
- (void)setBackgroundImageViewHidden:(BOOL)hidden animated:(BOOL)animated;

/**
 When triggered, the crop view will perform a relayout to ensure the crop box
 fills the entire crop view region
 */
- (void)moveCroppedContentToCenterAnimated:(BOOL)animated;

@end
