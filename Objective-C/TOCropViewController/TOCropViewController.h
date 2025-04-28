//
//  TOCropViewController.h
//
//  Copyright 2015-2024 Timothy Oliver. All rights reserved.
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

#if !__has_include(<TOCropViewController/TOCropViewConstants.h>)
#import "TOCropViewConstants.h"
#import "TOCropViewControllerAspectRatioPreset.h"
#import "TOCropView.h"
#import "TOCropToolbar.h"
#else
#import <TOCropViewController/TOCropViewConstants.h>
#import <TOCropViewController/TOCropViewControllerAspectRatioPreset.h>
#import <TOCropViewController/TOCropView.h>
#import <TOCropViewController/TOCropToolbar.h>
#endif

@class TOCropViewController;

///------------------------------------------------
/// @name Delegate
///------------------------------------------------

@protocol TOCropViewControllerDelegate <NSObject>
@optional

/**
 Called when the user has committed the crop action, and provides 
 just the cropping rectangle.

 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(nonnull TOCropViewController *)cropViewController
        didCropImageToRect:(CGRect)cropRect
                     angle:(NSInteger)angle;

/**
 Called when the user has committed the crop action, and provides 
 both the original image with crop co-ordinates.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(nonnull TOCropViewController *)cropViewController
            didCropToImage:(nonnull UIImage *)image withRect:(CGRect)cropRect
                     angle:(NSInteger)angle;

/**
 If the cropping style is set to circular, implementing this delegate will return a circle-cropped version of the selected
 image, as well as it's cropping co-ordinates
 
 @param image The newly cropped image, clipped to a circle shape
 @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
- (void)cropViewController:(nonnull TOCropViewController *)cropViewController
    didCropToCircularImage:(nonnull UIImage *)image withRect:(CGRect)cropRect
                     angle:(NSInteger)angle;

/**
 If implemented, when the user hits cancel, or completes a 
 UIActivityViewController operation, this delegate will be called,
 giving you a chance to manually dismiss the view controller

 @param cancelled Whether a cropping action was actually performed, or if the user explicitly hit 'Cancel'
 
 */
- (void)cropViewController:(nonnull TOCropViewController *)cropViewController
        didFinishCancelled:(BOOL)cancelled;

@end

@interface TOCropViewController : UIViewController

/**
 The original, uncropped image that was passed to this controller.
 */
@property (nonnull, nonatomic, readonly) UIImage *image;

/**
 The minimum croping aspect ratio. If set, user is prevented from
 setting cropping rectangle to lower aspect ratio than defined by the parameter.
 */
@property (nonatomic, assign) CGFloat minimumAspectRatio;

/**
 The view controller's delegate that will receive the resulting
 cropped image, as well as crop information.
 */
@property (nullable, nonatomic, weak) id<TOCropViewControllerDelegate> delegate;

/**
 If true, when the user hits 'Done', a UIActivityController will appear
 before the view controller ends.
 */
@property (nonatomic, assign) BOOL showActivitySheetOnDone;

/**
 The crop view managed by this view controller.
 */
@property (nonnull, nonatomic, strong, readonly) TOCropView *cropView;

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
@property (nonnull, nonatomic, strong, readonly) TOCropToolbar *toolbar;

/**
 The cropping style of this particular crop view controller
 */
@property (nonatomic, readonly) TOCropViewCroppingStyle croppingStyle;

/**
 A choice from one of the pre-defined aspect ratio presets
 */
@property (nonatomic, assign) CGSize aspectRatioPreset;

/**
 Title label which can be used to show instruction on the top of the crop view controller
 */
@property (nullable, nonatomic, readonly) UILabel *titleLabel;

/**
 Title for the 'Done' button.
 Setting this will override the Default which is a localized string for "Done".
 */
@property (nullable, nonatomic, copy) NSString *doneButtonTitle;

/**
 Title for the 'Cancel' button.
 Setting this will override the Default which is a localized string for "Cancel".
 */
@property (nullable, nonatomic, copy) NSString *cancelButtonTitle;

/**
 If true, button icons are visible in portairt instead button text.

 Default is NO.
 */
@property (nonatomic, assign) BOOL showOnlyIcons;

/**
 Color for the 'Done' button.
 Setting this will override the default color.
 */
@property (null_resettable, nonatomic, copy) UIColor *doneButtonColor;

/**
 Color for the 'Cancel' button.
 Setting this will override the default color.
 */
@property (nullable, nonatomic, copy) UIColor *cancelButtonColor;

/**
 Shows a confirmation dialog when the user hits 'Cancel' and there are pending changes.
 (Default is NO)
 */
@property (nonatomic, assign) BOOL showCancelConfirmationDialog;

/**
 If true, a custom aspect ratio is set, and the aspectRatioLockEnabled is set to YES, the crop box
 will swap it's dimensions depending on portrait or landscape sized images.
 This value also controls whether the dimensions can swap when the image is rotated.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioLockDimensionSwapEnabled;

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
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL rotateClockwiseButtonHidden;

/*
 If this controller is embedded in UINavigationController its navigation bar
 is hidden by default. Set this property to false to show the navigation bar.
 This must be set before this controller is presented.
 */
@property (nonatomic, assign) BOOL hidesNavigationBar;

/**
 When enabled, hides the rotation button, as well as the alternative rotation 
 button visible when `showClockwiseRotationButton` is set to YES.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL rotateButtonsHidden;

/**
 When enabled, hides the 'Reset' button on the toolbar.

 Default is NO.
 */
@property (nonatomic, assign) BOOL resetButtonHidden;
/**
 When enabled, hides the 'Aspect Ratio Picker' button on the toolbar.
 
 Default is NO.
 */
@property (nonatomic, assign) BOOL aspectRatioPickerButtonHidden;

/**
 When enabled, hides the 'Done' button on the toolbar.

 Default is NO.
 */
@property (nonatomic, assign) BOOL doneButtonHidden;

/**
 When enabled, hides the 'Cancel' button on the toolbar.

 Default is NO.
 */
@property (nonatomic, assign) BOOL cancelButtonHidden;

/**
 When enabled, the toolbar is displayed in RTL layout.

 Default is NO.
 */
@property (nonatomic, assign) BOOL reverseContentLayout
;

/** 
 If `showActivitySheetOnDone` is true, then these activity items will 
 be supplied to that UIActivityViewController in addition to the 
 `TOActivityCroppedImageProvider` object.
 */
@property (nullable, nonatomic, strong) NSArray *activityItems;

/**
 If `showActivitySheetOnDone` is true, then you may specify any 
 custom activities your app implements in this array. If your activity requires 
 access to the cropping information, it can be accessed in the supplied 
 `TOActivityCroppedImageProvider` object
 */
@property (nullable, nonatomic, strong) NSArray<UIActivity *> *applicationActivities;

/**
 If `showActivitySheetOnDone` is true, then you may expliclty 
 set activities that won't appear in the share sheet here.
 */
@property (nullable, nonatomic, strong) NSArray<UIActivityType> *excludedActivityTypes;

/**
 An array of `TOCropViewControllerAspectRatioPreset` enum values denoting which
 aspect ratios the crop view controller may display (Default is nil. All are shown)
 */
@property (nullable, nonatomic, strong) NSArray<TOCropViewControllerAspectRatioPreset *> *allowedAspectRatios;

/**
 When the user hits cancel, or completes a
 UIActivityViewController operation, this block will be called,
 giving you a chance to manually dismiss the view controller
 */
@property (nullable, nonatomic, strong) void (^onDidFinishCancelled)(BOOL isFinished);

/**
 Called when the user has committed the crop action, and provides
 just the cropping rectangle.
 
 @param cropRect A rectangle indicating the crop region of the image the user chose
                    (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
@property (nullable, nonatomic, strong) void (^onDidCropImageToRect)(CGRect cropRect, NSInteger angle);

/**
 Called when the user has committed the crop action, and provides
 both the cropped image with crop co-ordinates.
 
 @param image The newly cropped image.
 @param cropRect A rectangle indicating the crop region of the image the user chose
                    (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
@property (nullable, nonatomic, strong) void (^onDidCropToRect)(UIImage* _Nonnull image, CGRect cropRect, NSInteger angle);

/**
 If the cropping style is set to circular, this block will return a circle-cropped version of the selected
 image, as well as it's cropping co-ordinates
 
 @param image The newly cropped image, clipped to a circle shape
 @param cropRect A rectangle indicating the crop region of the image the user chose
                    (In the original image's local co-ordinate space)
 @param angle The angle of the image when it was cropped
 */
@property (nullable, nonatomic, strong) void (^onDidCropToCircleImage)(UIImage* _Nonnull image, CGRect cropRect, NSInteger angle);


///------------------------------------------------
/// @name Object Creation
///------------------------------------------------

/**
 Creates a new instance of a crop view controller with the supplied image
 
 @param image The image that will be used to crop.
 */
- (nonnull instancetype)initWithImage:(nonnull UIImage *)image NS_SWIFT_NAME(init(image:));

/** 
 Creates a new instance of a crop view controller with the supplied image and cropping style
 
 @param style The cropping style that will be used with this view controller (eg, rectangular, or circular)
 @param image The image that will be cropped
 */
- (nonnull instancetype)initWithCroppingStyle:(TOCropViewCroppingStyle)style image:(nonnull UIImage *)image NS_SWIFT_NAME(init(croppingStyle:image:));

/**
 Commits the crop action as if user pressed done button in the bottom bar themself
 */
- (void)commitCurrentCrop;

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
- (void)setAspectRatioPreset:(CGSize)aspectRatioPreset animated:(BOOL)animated NS_SWIFT_NAME(setAspectRatioPreset(_:animated:));

/**
 Play a custom animation of the target image zooming to its position in
 the crop controller while the background fades in. 
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param fromView A view that's frame will be used as the origin for this animation. Optional if `fromFrame` has a value.
 @param fromFrame In the screen's coordinate space, the frame from which the image should animate from. Optional if `fromView` has a value.
 @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)presentAnimatedFromParentViewController:(nonnull UIViewController *)viewController
                                       fromView:(nullable UIView *)fromView
                                      fromFrame:(CGRect)fromFrame
                                          setup:(nullable void (^)(void))setup
                                     completion:(nullable void (^)(void))completion NS_SWIFT_NAME(presentAnimatedFrom(_:view:frame:setup:completion:));

/**
 Play a custom animation of the target image zooming to its position in
 the crop controller while the background fades in. Additionally, if you're 
 'restoring' to a previous crop setup, this method lets you provide a previously
 cropped copy of the image, and the previous crop settings to transition back to
 where the user would have left off.
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param image The previously cropped image that can be used in the transition animation.
 @param fromView A view that's frame will be used as the origin for this animation. Optional if `fromFrame` has a value.
 @param fromFrame In the screen's coordinate space, the frame from which the image should animate from.
 @param angle The rotation angle in which the image was rotated when it was originally cropped.
 @param toFrame In the image's coordinate space, the previous crop frame that created the previous crop
 @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)presentAnimatedFromParentViewController:(nonnull UIViewController *)viewController
                                      fromImage:(nullable UIImage *)image
                                       fromView:(nullable UIView *)fromView
                                      fromFrame:(CGRect)fromFrame
                                          angle:(NSInteger)angle
                                   toImageFrame:(CGRect)toFrame
                                          setup:(nullable void (^)(void))setup
                                     completion:(nullable void (^)(void))completion NS_SWIFT_NAME(presentAnimatedFrom(_:fromImage:fromView:fromFrame:angle:toFrame:setup:completion:));

/**
 Play a custom animation of the supplied cropped image zooming out from
 the cropped frame to the specified frame as the rest of the content fades out.
 If any view configurations need to be done before the animation starts,
 
 @param viewController The parent controller that this view controller would be presenting from.
 @param toView A view who's frame will be used to establish the destination frame
 @param frame The target frame that the image will animate to
 @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
 @param completion A block that is called once the transition animation is completed.
 */
- (void)dismissAnimatedFromParentViewController:(nonnull UIViewController *)viewController
                                         toView:(nullable UIView *)toView
                                        toFrame:(CGRect)frame
                                          setup:(nullable void (^)(void))setup
                                     completion:(nullable void (^)(void))completion NS_SWIFT_NAME(dismissAnimatedFrom(_:toView:toFrame:setup:completion:));

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
- (void)dismissAnimatedFromParentViewController:(nonnull UIViewController *)viewController
                               withCroppedImage:(nullable UIImage *)image
                                         toView:(nullable UIView *)toView
                                        toFrame:(CGRect)frame
                                          setup:(nullable void (^)(void))setup
                                     completion:(nullable void (^)(void))completion NS_SWIFT_NAME(dismissAnimatedFrom(_:croppedImage:toView:toFrame:setup:completion:));

@end

