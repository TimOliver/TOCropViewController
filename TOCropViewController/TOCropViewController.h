//
//  TOCropViewController.h
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

#import "TOCropView.h"
#import "TOCropToolbar.h"

typedef NS_ENUM(NSInteger, TOCropViewControllerAspectRatio) {
    TOCropViewControllerAspectRatioOriginal,
    TOCropViewControllerAspectRatioSquare,
    TOCropViewControllerAspectRatio3x2,
    TOCropViewControllerAspectRatio5x3,
    TOCropViewControllerAspectRatio4x3,
    TOCropViewControllerAspectRatio5x4,
    TOCropViewControllerAspectRatio7x5,
    TOCropViewControllerAspectRatio16x9
};

typedef NS_ENUM(NSInteger, TOCropViewControllerToolbarPosition) {
    TOCropViewControllerToolbarPositionTop,
    TOCropViewControllerToolbarPositionBottom
};

@class TOCropViewController;


///------------------------------------------------
/// @name Delegate
///------------------------------------------------

@protocol TOCropViewControllerDelegate <NSObject>
@optional

/**
 Called when the user has committed the crop action, and provides just the cropping rectangle
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didCropImageToRect:(CGRect)cropRect angle:(NSInteger)angle;

/**
 Called when the user has committed the crop action, and provides both the original image with crop co-ordinates.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle;

/**
 If implemented, when the user hits cancel, or completes a UIActivityViewController operation, this delegate will be called,
 giving you a chance to manually dismiss the view controller
 
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didFinishCancelled:(BOOL)cancelled;

@end

@interface TOCropViewController : UIViewController

/**
 The original, uncropped image that was passed to this controller.
 */
@property (nonatomic, readonly) UIImage *image;

/**
 The crop view managed by this view controller.
 */
@property (nonatomic, strong, readonly) TOCropView *cropView;

/**
 The toolbar view managed by this view controller.
 */
@property (nonatomic, strong, readonly) TOCropToolbar *toolbar;

/**
 The view controller's delegate that will return the resulting cropped image, as well as crop information
 */
@property (nonatomic, weak) id<TOCropViewControllerDelegate> delegate;

/**
 If true, when the user hits 'Done', a UIActivityController will appear before the view controller ends
 */
@property (nonatomic, assign) BOOL showActivitySheetOnDone;

/**
 The default aspect ratio for the crop view, the default value is TOCropViewControllerAspectRatioOriginal.
 */
@property (nonatomic, assign) TOCropViewControllerAspectRatio defaultAspectRatio;

/**
 The position of the Toolbar the default value is TOCropViewControllerToolbarPositionBottom.
 */
@property (nonatomic, assign) TOCropViewControllerToolbarPosition toolbarPosition;

/**
 If true, the aspect ratio will be locked to the defaultAspectRatio. And, the aspect ratio button won't appear on the toolbar.
 */
@property (nonatomic, assign) BOOL lockedAspectRatio;

/**
 If performing a transition animation, this block can be used to set up any view states just before the animation begins
 */
@property (nonatomic, copy) void (^prepareForTransitionHandler)(void);

/** 
 If `showActivitySheetOnDone` is true, then these activity items will be supplied to that UIActivityViewController 
 in addition to the `TOActivityCroppedImageProvider` object.
 */
@property (nonatomic, strong) NSArray *activityItems;

/**
 If `showActivitySheetOnDone` is true, then you may specify any custom activities your app implements in this array.
 If your activity requires access to the cropping information, it can be accessed in the supplied `TOActivityCroppedImageProvider` object
 */
@property (nonatomic, strong) NSArray *applicationActivities;

/**
 If `showActivitySheetOnDone` is true, then you may expliclty set activities that won't appear in the share sheet here.
 */
@property (nonatomic, strong) NSArray *excludedActivityTypes;

///------------------------------------------------
/// @name Object Creation
///------------------------------------------------

/**
 Creates a new instance of a crop view controller with the supplied image
 
 @param image The image that will be used to crop.
 */
- (instancetype)initWithImage:(UIImage *)image;

/**
 Play a custom animation of the target image zooming to its position in the crop controller while the background fades in.
 If any view configurations need to be done before the animation starts, please do them in `prepareForTransitionHandler`
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param frame In the screen's coordinate space, the frame from which the image should animate from.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)presentAnimatedFromParentViewController:(UIViewController *)viewController fromFrame:(CGRect)frame completion:(void (^)(void))completion;

/**
 Play a custom animation of the supplied cropped image zooming out from the cropped frame to the specified frame as the rest of the content fades out.
 If any view configurations need to be done before the animation starts, please do them in `prepareForTransitionHandler`
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param frame The target frame that the image will animate to
 @param completion A block that is called once the transition animation is completed.
 */
- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController withCroppedImage:(UIImage *)image toFrame:(CGRect)frame completion:(void (^)(void))completion;

/**
 Play a custom animation of the supplied cropped image zooming out from the cropped frame to the specified frame as the rest of the content fades out.
 If any view configurations need to be done before the animation starts, please do them in `prepareForTransitionHandler`
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param frame The target frame that the image will animate to
 @param completion A block that is called once the transition animation is completed.
 */
- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController toFrame:(CGRect)frame completion:(void (^)(void))completion;

@end

