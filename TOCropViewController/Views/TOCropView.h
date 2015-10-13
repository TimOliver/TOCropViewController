//
//  TOCropView.h
//
//  Copyright 2015 Timothy Oliver. All rights reserved.
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

@class TOCropView;

@protocol TOCropViewDelegate <NSObject>

- (void)cropViewDidBecomeResettable:(TOCropView *)cropView;
- (void)cropViewDidBecomeNonResettable:(TOCropView *)cropView;
- (CGSize)cropViewFixedAspectRatio;

@end

@interface TOCropView : UIView

/**
 The image that the crop view is displaying. This cannot be changed once the crop view is instantiated.
 */
@property (nonatomic, strong, readonly) UIImage *image;

/**
 A delegate object that receives notifications from the crop view
 */
@property (nonatomic, weak) id<TOCropViewDelegate> delegate;

/**
 Whether the user has manipulated the crop view to the point where it can be reset
 */
@property (nonatomic, readonly) BOOL canReset;

/** 
 The frame of the cropping box on the crop view
 */
@property (nonatomic, readonly) CGRect cropBoxFrame;

@property (nonatomic, assign) CGSize originalCropBoxSize; /* Save the original crop box size so we can tell when the content has been edited */

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
@property (nonatomic, assign) BOOL simpleMode;

/**
 When the cropping box is locked to its current size
 */
@property (nonatomic, assign) BOOL aspectLockEnabled;

/**
 True when the height of the crop box is bigger than the width
 */
@property (nonatomic, readonly) BOOL cropBoxAspectRatioIsPortrait;

/**
 The rotation angle of the crop view (Will always be negative as it rotates in a counter-clockwise direction)
 */
@property (nonatomic, assign, readonly) NSInteger angle;

/**
 Hide all of the crop elements for transition animations 
 */
@property (nonatomic, assign) BOOL croppingViewsHidden;

/**
 In relation to the coordinate space of the image, the frame that the crop view is focussing on
 */
@property (nonatomic, readonly) CGRect croppedImageFrame;

/**
 Set the grid overlay graphic to be hidden
 */
@property (nonatomic, assign) BOOL gridOverlayHidden;

/**
 Create a new instance of the crop view with the supplied image
 */
- (instancetype)initWithImage:(UIImage *)image;

/**
 When performing large size transitions (eg, orientation rotation),
 set simple mode to YES to temporarily graphically heavy effects like translucency.
 
 @param simpleMode Whether simple mode is enabled or not
 
 */
- (void)setSimpleMode:(BOOL)simpleMode animated:(BOOL)animated;

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
 Enables an aspect ratio lock where the crop box will always scale at a specific ratio.
 
 @param aspectRatio The aspect ratio (For example 16:9 is 16.0f/9.0f). Specify 0.0f to lock to the image's original aspect ratio
 @param animated Whether the locking effect is animated
 */
- (void)setAspectLockEnabledWithAspectRatio:(CGSize)aspectRatio animated:(BOOL)animated;

/**
 Rotates the entire canvas to a 90-degree angle
 
 @param angle The angle in which to rotate (May be 0, 90, 180, 270)
 @param animated Whether the transition is animated
 */
- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated;

/**
 Animate the grid overlay graphic to be visible
 */
- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden animated:(BOOL)animated;

/**
 Animate the cropping component views to become visible
 */
- (void)setCroppingViewsHidden:(BOOL)hidden animated:(BOOL)animated;


@end
