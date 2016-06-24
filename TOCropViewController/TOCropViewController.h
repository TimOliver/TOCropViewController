//
//  TOCropViewController.h
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

#import "TOCropView.h"
#import "TOCropToolbar.h"

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
 Called when the user has committed the crop action, and provides 
 just the cropping rectangle.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didCropImageToRect:(CGRect)cropRect angle:(NSInteger)angle;

/**
 Called when the user has committed the crop action, and provides 
 both the original image with crop co-ordinates.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle;

/**
 If the cropping style is set to circular, implementing this delegate will return a circle-cropped version of the selected
 image, as well as it's cropping co-ordinates
 
 @param image The newly cropped image, clipped to a circle shape
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToCircularImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle;

/**
 If implemented, when the user hits cancel, or completes a 
 UIActivityViewController operation, this delegate will be called,
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
 The view controller's delegate that will return the resulting
 cropped image, as well as crop information
 */
@property (nonatomic, weak) id<TOCropViewControllerDelegate> delegate;

/**
 If true, when the user hits 'Done', a UIActivityController will appear
 before the view controller ends.
 */
@property (nonatomic, assign) BOOL showActivitySheetOnDone;

/**
  If true, controller force hides status bar.
 Use this property when need hidden status bar when in info.plist
 UIViewControllerBasedStatusBarAppearance = NO.
 */
@property (nonatomic, assign) BOOL forceHideStatusBar;

/**
 The crop view managed by this view controller.
 */
@property (nonatomic, strong, readonly) TOCropView *cropView;

/** 
 In the coordinate space of the image itself, the region that is currently
 being highlighted by the crop box.
 
 This property can be set before the controller is presented to have
 the image 'restored' to a previous cropping layout.
 */
@property (nonatomic, assign) CGRect imageCropFrame;

/**
 The angle in which the image is rotated in the crop view.
 This can only be in 90 degree increments (eg, 0, 90, 180, 270).
 
 This property can be set before the controller is presented to have 
 the image 'restored' to a previous cropping layout.
 */
@property (nonatomic, assign) NSInteger angle;

/**
 The toolbar view managed by this view controller.
 */
@property (nonatomic, strong, readonly) TOCropToolbar *toolbar;

/**
 The cropping style of this particular crop view controller
 */
@property (nonatomic, readonly) TOCropViewCroppingStyle croppingStyle;

/**
 A choice from one of the pre-defined aspect ratio presets
 */
@property (nonatomic, assign) TOCropViewControllerAspectRatioPreset aspectRatioPreset;

/**
 A CGSize value representing a custom aspect ratio, not listed in the presets.
 E.g. A ratio of 4:3 would be represented as (CGSize){4.0f, 3.0f}
 
 NOTE: You will need to set `aspectRatioPreset` to 'Custom' for this to be applied
 */
@property (nonatomic, assign) CGSize customAspectRatio;

/**
 If true, while it can still be resized, the crop box will be locked to its current aspect ratio.
 
 If this is set to YES, and `resetAspectRatioEnabled` is set to NO, then the aspect ratio
 button will automatically be hidden from the toolbar.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioLockEnabled;

/** 
 If true, tapping the reset button will also reset the aspect ratio back to the image
 default ratio. Otherwise, the reset will just zoom out to the current aspect ratio.
 
 If this is set to NO, and `aspectRatioLockEnabled` is set to YES, then the aspect ratio
 button will automatically be hidden from the toolbar.
 
 Default is YES
 */
@property (nonatomic, assign) BOOL resetAspectRatioEnabled;

/**
 The position of the Toolbar the default value is `TOCropViewControllerToolbarPositionBottom`.
 */
@property (nonatomic, assign) TOCropViewControllerToolbarPosition toolbarPosition;

/**
 When disabled, an additional rotation button that rotates the canvas in 
 90-degree segments in a clockwise direction is shown in the toolbar.
 
 Default is YES.
 */
@property (nonatomic, assign) BOOL rotateClockwiseButtonHidden;

/**
 When enabled, hides the rotation button, as well as the alternative rotation 
 button visible when `showClockwiseRotationButton` is set to YES.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL rotateButtonsHidden;

/**
 When enabled, hides the 'Aspect Ratio Picker' button on the toolbar.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioPickerButtonHidden;

/** 
 If `showActivitySheetOnDone` is true, then these activity items will 
 be supplied to that UIActivityViewController in addition to the 
 `TOActivityCroppedImageProvider` object.
 */
@property (nonatomic, strong) NSArray *activityItems;

/**
 If `showActivitySheetOnDone` is true, then you may specify any 
 custom activities your app implements in this array. If your activity requires 
 access to the cropping information, it can be accessed in the supplied 
 `TOActivityCroppedImageProvider` object
 */
@property (nonatomic, strong) NSArray *applicationActivities;

/**
 If `showActivitySheetOnDone` is true, then you may expliclty 
 set activities that won't appear in the share sheet here.
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
 Creates a new instance of a crop view controller with the supplied image and cropping style
 
 @param style The cropping style that will be used with this view controller (eg, rectangular, or circular)
 @param image The image that will be cropped
 */
- (instancetype)initWithCroppingStyle:(TOCropViewCroppingStyle)style image:(UIImage *)image;

/**
 Resets object of TOCropViewController class as if user pressed reset button in the bottom bar themself
 */
- (void)resetCropViewLayout;

/** 
 Set the aspect ratio to be one of the available preset options. These presets have specific behaviour
 such as swapping their dimensions depending on portrait or landscape sized images.
 
 @param aspectRatioPreset The aspect ratio preset
 @param animated Whether the transition to the aspect ratio is animated
 */
- (void)setAspectRatioPreset:(TOCropViewControllerAspectRatioPreset)aspectRatioPreset animated:(BOOL)animated;

/**
 Play a custom animation of the target image zooming to its position in
 the crop controller while the background fades in. 
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param fromView A view that's frame will be used as the origin for this animation. Optional if `fromFrame` has a value.
 @param fromFrame In the screen's coordinate space, the frame from which the image should animate from. Optional if `fromView` has a value.
 @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)presentAnimatedFromParentViewController:(UIViewController *)viewController
                                       fromView:(UIView *)fromView
                                      fromFrame:(CGRect)fromFrame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion;

/**
 Play a custom animation of the target image zooming to its position in
 the crop controller while the background fades in. Additionally, if you're 
 'restoring' to a previous crop setup, this method lets you provide a previously
 cropped copy of the image, and the previous crop settings to transition back to
 where the user would have left off.
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param fromImage The previously cropped image that can be used in the transition animation.
 @param fromView A view that's frame will be used as the origin for this animation
 @param fromFrame In the screen's coordinate space, the frame from which the image should animate from.
 @param angle The rotation angle in which the image was rotated when it was originally cropped.
 @param toImageFrame In the image's coordinate space, the previous crop frame that created the previous crop
 @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)presentAnimatedFromParentViewController:(UIViewController *)viewController
                                      fromImage:(UIImage *)image
                                       fromView:(UIView *)fromView
                                      fromFrame:(CGRect)fromFrame
                                          angle:(NSInteger)angle
                                   toImageFrame:(CGRect)toFrame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion;

/**
 Play a custom animation of the supplied cropped image zooming out from
 the cropped frame to the specified frame as the rest of the content fades out.
 If any view configurations need to be done before the animation starts,
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param image The image that will be played in the transition. If nil, the cropper's image will be used.
 @param toView A view who's frame will be used to establish the destination frame
 @param frame The target frame that the image will animate to
 @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController
                                         toView:(UIView *)toView
                                        toFrame:(CGRect)frame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion;

/**
 Play a custom animation of the supplied cropped image zooming out from
 the cropped frame to the specified frame as the rest of the content fades out.
 If any view configurations need to be done before the animation starts,
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param image The resulting 'cropped' image. If supplied, will animate out of the crop box zone. If nil, the default image will entirely zoom out
 @param toView A view who's frame will be used to establish the destination frame
 @param frame The target frame that the image will animate to
 @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController
                               withCroppedImage:(UIImage *)image
                                         toView:(UIView *)toView
                                        toFrame:(CGRect)frame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion;

@end

