//
//  TOCropViewController.h
//
//  Copyright 2015-2017 Timothy Oliver. All rights reserved.
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

#import "TOCropViewController.h"
#import "TOCropViewControllerTransitioning.h"
#import "TOActivityCroppedImageProvider.h"
#import "UIImage+CropRotate.h"
#import "TOCroppedImageAttributes.h"

@interface TOCropViewController () <UIActionSheetDelegate, UIViewControllerTransitioningDelegate, TOCropViewDelegate>

/* The target image */
@property (nonatomic, readwrite) UIImage *image;

/* The cropping style of the crop view */
@property (nonatomic, assign, readwrite) TOCropViewCroppingStyle croppingStyle;

/* Views */
@property (nonatomic, strong) TOCropToolbar *toolbar;
@property (nonatomic, strong, readwrite) TOCropView *cropView;
@property (nonatomic, strong) UIView *toolbarSnapshotView;

/* Transition animation controller */
@property (nonatomic, copy) void (^prepareForTransitionHandler)(void);
@property (nonatomic, strong) TOCropViewControllerTransitioning *transitionController;
@property (nonatomic, assign) BOOL inTransition;
@property (nonatomic, assign) BOOL initialLayout;

/* If pushed from a navigation controller, the visibility of that controller's bars. */
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, assign) BOOL toolbarHidden;

/* On iOS 7, the popover view controller that appears when tapping 'Done' */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UIPopoverController *activityPopoverController;
#pragma clang diagnostic pop

/* Button callback */
- (void)cancelButtonTapped;
- (void)doneButtonTapped;
- (void)showAspectRatioDialog;
- (void)resetCropViewLayout;
- (void)rotateCropViewClockwise;
- (void)rotateCropViewCounterclockwise;

/* View layout */
- (CGRect)frameForToolBarWithVerticalLayout:(BOOL)verticalLayout;
- (CGRect)frameForCropViewWithVerticalLayout:(BOOL)verticalLayout;

@end

@implementation TOCropViewController

- (instancetype)initWithCroppingStyle:(TOCropViewCroppingStyle)style image:(UIImage *)image
{
    NSParameterAssert(image);

    self = [super init];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        _transitionController = [[TOCropViewControllerTransitioning alloc] init];
        _image = image;
        _croppingStyle = style;
        
        _aspectRatioPreset = TOCropViewControllerAspectRatioPresetOriginal;
        _toolbarPosition = TOCropViewControllerToolbarPositionBottom;
        _rotateClockwiseButtonHidden = YES;
    }
    
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    return [self initWithCroppingStyle:TOCropViewCroppingStyleDefault image:image];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    BOOL circularMode = (self.croppingStyle == TOCropViewCroppingStyleCircular);

    self.cropView.frame = [self frameForCropViewWithVerticalLayout:CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)];
    [self.view addSubview:self.cropView];
    
    self.toolbar.frame = [self frameForToolBarWithVerticalLayout:CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)];
    [self.view addSubview:self.toolbar];
    
    __weak typeof(self) weakSelf = self;
    self.toolbar.doneButtonTapped =     ^{ [weakSelf doneButtonTapped]; };
    self.toolbar.cancelButtonTapped =   ^{ [weakSelf cancelButtonTapped]; };
    
    self.toolbar.resetButtonTapped =    ^{ [weakSelf resetCropViewLayout]; };
    self.toolbar.clampButtonTapped =    ^{ [weakSelf showAspectRatioDialog]; };
    
    self.toolbar.rotateCounterclockwiseButtonTapped = ^{ [weakSelf rotateCropViewCounterclockwise]; };
    self.toolbar.rotateClockwiseButtonTapped        = ^{ [weakSelf rotateCropViewClockwise]; };
    
    self.toolbar.clampButtonHidden = self.aspectRatioPickerButtonHidden || circularMode;
    self.toolbar.rotateClockwiseButtonHidden = self.rotateClockwiseButtonHidden && !circularMode;
    
    self.transitioningDelegate = self;
    self.view.backgroundColor = self.cropView.backgroundColor;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (animated) {
        self.inTransition = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    if (self.navigationController) {
        self.navigationBarHidden = self.navigationController.navigationBarHidden;
        self.toolbarHidden = self.navigationController.toolbarHidden;
        
        [self.navigationController setNavigationBarHidden:YES animated:animated];
        [self.navigationController setToolbarHidden:YES animated:animated];
        
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    else {
        [self.cropView setBackgroundImageViewHidden:YES animated:NO];
    }

    if (self.aspectRatioPreset != TOCropViewControllerAspectRatioPresetOriginal) {
        [self setAspectRatioPreset:self.aspectRatioPreset animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.inTransition = NO;
    self.cropView.simpleRenderMode = NO;
    if (animated && [UIApplication sharedApplication].statusBarHidden == NO) {
        [UIView animateWithDuration:0.3f animations:^{ [self setNeedsStatusBarAppearanceUpdate]; }];
        
        if (self.cropView.gridOverlayHidden) {
            [self.cropView setGridOverlayHidden:NO animated:YES];
        }
        
        if (self.navigationController == nil) {
            [self.cropView setBackgroundImageViewHidden:NO animated:YES];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.inTransition = YES;
    [UIView animateWithDuration:0.5f animations:^{ [self setNeedsStatusBarAppearanceUpdate]; }];
    
    if (self.navigationController) {
        [self.navigationController setNavigationBarHidden:self.navigationBarHidden animated:animated];
        [self.navigationController setToolbarHidden:self.toolbarHidden animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.inTransition = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Status Bar -
- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.navigationController) {
        return UIStatusBarStyleLightContent;
    }
    
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    //If we belong to a UINavigationController, defer to its own status bar style
    if (self.navigationController) {
        return self.navigationController.prefersStatusBarHidden;
    }
    
    //If our presenting controller has already hidden the status bar,
    //hide the status bar by default
    if (self.presentingViewController.prefersStatusBarHidden) {
        return YES;
    }
    
    BOOL hidden = YES;
    hidden = hidden && !(self.inTransition);          // Not currently in a presentation animation (Where removing the status bar would break the layout)
    hidden = hidden && !(self.view.superview == nil); // Not currently waiting to the added to a super view
    
    return hidden;
}

- (CGRect)frameForToolBarWithVerticalLayout:(BOOL)verticalLayout
{
    CGRect frame = CGRectZero;
    if (!verticalLayout) {
        frame.origin.x = 0.0f;
        frame.origin.y = 0.0f;
        frame.size.width = 44.0f;
        frame.size.height = CGRectGetHeight(self.view.frame);
    }
    else {
        frame.origin.x = 0.0f;
        
        if (self.toolbarPosition == TOCropViewControllerToolbarPositionBottom) {
            frame.origin.y = CGRectGetHeight(self.view.bounds) - 44.0f;
        } else {
            frame.origin.y = 0;
        }
        
        frame.size.width = CGRectGetWidth(self.view.bounds);
        frame.size.height = 44.0f;
        
        // If the bar is at the top of the screen and the status bar is visible, account for the status bar height
        if (self.toolbarPosition == TOCropViewControllerToolbarPositionTop && self.prefersStatusBarHidden == NO) {
            frame.size.height = 64.0f;
        }
    }
    
    return frame;
}

- (CGRect)frameForCropViewWithVerticalLayout:(BOOL)verticalLayout
{
    //On an iPad, if being presented in a modal view controller by a UINavigationController,
    //at the time we need it, the size of our view will be incorrect.
    //If this is the case, derive our view size from our parent view controller instead
    
    CGRect bounds = CGRectZero;
    if (self.parentViewController == nil) {
        bounds = self.view.bounds;
    }
    else {
        bounds = self.parentViewController.view.bounds;
    }
    
    CGRect frame = CGRectZero;
    if (!verticalLayout) {
        frame.origin.x = 44.0f;
        frame.origin.y = 0.0f;
        frame.size.width = CGRectGetWidth(bounds) - 44.0f;
        frame.size.height = CGRectGetHeight(bounds);
    }
    else {
        frame.origin.x = 0.0f;
        
        if (_toolbarPosition == TOCropViewControllerToolbarPositionBottom) {
            frame.origin.y = 0.0f;
        } else {
            frame.origin.y = 44.0f;
        }

        frame.size.width = CGRectGetWidth(bounds);
        frame.size.height = CGRectGetHeight(bounds) - 44.0f;
    }
    
    return frame;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    BOOL verticalLayout = CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds);
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:verticalLayout];
    [self.cropView moveCroppedContentToCenterAnimated:NO];
    
    [UIView performWithoutAnimation:^{
        self.toolbar.statusBarVisible = (self.toolbarPosition == TOCropViewControllerToolbarPositionTop && !self.prefersStatusBarHidden);
        self.toolbar.frame = [self frameForToolBarWithVerticalLayout:verticalLayout];
        [self.toolbar setNeedsLayout];
    }];
}

#pragma mark - Rotation Handling -

//TODO: Deprecate iOS 7 properly at the right time
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.toolbarSnapshotView = [self.toolbar snapshotViewAfterScreenUpdates:NO];
    self.toolbarSnapshotView.frame = self.toolbar.frame;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        self.toolbarSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    else
        self.toolbarSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    
    [self.view addSubview:self.toolbarSnapshotView];
    
    [UIView performWithoutAnimation:^{
        self.toolbar.frame = [self frameForToolBarWithVerticalLayout:UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
        [self.toolbar layoutIfNeeded];
        self.toolbar.alpha = 0.0f;
    }];
    
    [self.cropView prepareforRotation];
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:!UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
    self.cropView.simpleRenderMode = YES;
    self.cropView.internalLayoutDisabled = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //Remove all animations in the toolbar
    self.toolbar.frame = [self frameForToolBarWithVerticalLayout:!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    [self.toolbar.layer removeAllAnimations];
    for (CALayer *sublayer in self.toolbar.layer.sublayers) {
        [sublayer removeAllAnimations];
    }
    
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    [self.cropView performRelayoutForRotation];
    
    [UIView animateWithDuration:duration animations:^{
        self.toolbarSnapshotView.alpha = 0.0f;
        self.toolbar.alpha = 1.0f;
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.toolbarSnapshotView removeFromSuperview];
    self.toolbarSnapshotView = nil;
    
    [self.cropView setSimpleRenderMode:NO animated:YES];
    self.cropView.internalLayoutDisabled = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    CGSize currentSize = self.view.bounds.size;
    if (currentSize.width < size.width)
        orientation = UIInterfaceOrientationLandscapeLeft;
    
    [self willRotateToInterfaceOrientation:orientation duration:coordinator.transitionDuration];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self willAnimateRotationToInterfaceOrientation:orientation duration:coordinator.transitionDuration];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self didRotateFromInterfaceOrientation:orientation];
    }];
}
#pragma clang diagnostic pop

#pragma mark - Reset -
- (void)resetCropViewLayout
{
    BOOL animated = (self.cropView.angle == 0);
    
    if (self.resetAspectRatioEnabled) {
        self.aspectRatioLockEnabled = NO;
    }
    
    [self.cropView resetLayoutToDefaultAnimated:animated];
}

#pragma mark - Aspect Ratio Handling -
- (void)showAspectRatioDialog
{
    if (self.cropView.aspectRatioLockEnabled) {
        self.cropView.aspectRatioLockEnabled = NO;
        self.toolbar.clampButtonGlowing = NO;
        return;
    }
    
    //Depending on the shape of the image, work out if horizontal, or vertical options are required
    BOOL verticalCropBox = self.cropView.cropBoxAspectRatioIsPortrait;
    
    // In CocoaPods, strings are stored in a separate bundle from the main one
    NSBundle *resourceBundle = nil;
    NSBundle *classBundle = [NSBundle bundleForClass:[self class]];
    NSURL *resourceBundleURL = [classBundle URLForResource:@"TOCropViewControllerBundle" withExtension:@"bundle"];
    if (resourceBundleURL) {
        resourceBundle = [[NSBundle alloc] initWithURL:resourceBundleURL];
    }
    else {
        resourceBundle = classBundle;
    }
    
    //Prepare the localized options
    NSString *cancelButtonTitle = NSLocalizedStringFromTableInBundle(@"Cancel", @"TOCropViewControllerLocalizable", resourceBundle, nil);
    NSString *originalButtonTitle = NSLocalizedStringFromTableInBundle(@"Original", @"TOCropViewControllerLocalizable", resourceBundle, nil);
    NSString *squareButtonTitle = NSLocalizedStringFromTableInBundle(@"Square", @"TOCropViewControllerLocalizable", resourceBundle, nil);
    
    //Prepare the list that will be fed to the alert view/controller
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:originalButtonTitle];
    [items addObject:squareButtonTitle];
    if (verticalCropBox) {
        [items addObjectsFromArray:@[@"2:3", @"3:5", @"3:4", @"4:5", @"5:7", @"9:16"]];
    }
    else {
        [items addObjectsFromArray:@[@"3:2", @"5:3", @"4:3", @"5:4", @"7:5", @"16:9"]];
    }
    
    //Present via a UIAlertController if >= iOS 8
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
        
        //Add each item to the alert controller
        NSInteger i = 0;
        for (NSString *item in items) {
            UIAlertAction *action = [UIAlertAction actionWithTitle:item style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self setAspectRatioPreset:(TOCropViewControllerAspectRatioPreset)i animated:YES];
                self.aspectRatioLockEnabled = YES;
            }];
            [alertController addAction:action];
            
            i++;
        }
        
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *presentationController = [alertController popoverPresentationController];
        presentationController.sourceView = self.toolbar;
        presentationController.sourceRect = self.toolbar.clampButtonFrame;
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else {
    //TODO: Completely overhaul this once iOS 7 support is dropped
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:cancelButtonTitle
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        
        for (NSString *item in items) {
            [actionSheet addButtonWithTitle:item];
        }
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [actionSheet showFromRect:self.toolbar.clampButtonFrame inView:self.toolbar animated:YES];
        else
            [actionSheet showInView:self.view];
#pragma clang diagnostic pop
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self setAspectRatioPreset:(TOCropViewControllerAspectRatioPreset)buttonIndex animated:YES];
    self.aspectRatioLockEnabled = YES;
}
#pragma clang diagnostic pop

- (void)setAspectRatioPreset:(TOCropViewControllerAspectRatioPreset)aspectRatioPreset animated:(BOOL)animated
{
    CGSize aspectRatio = CGSizeZero;
    
    _aspectRatioPreset = aspectRatioPreset;
    
    switch (aspectRatioPreset) {
        case TOCropViewControllerAspectRatioPresetOriginal:
            aspectRatio = CGSizeZero;
            break;
        case TOCropViewControllerAspectRatioPresetSquare:
            aspectRatio = CGSizeMake(1.0f, 1.0f);
            break;
        case TOCropViewControllerAspectRatioPreset3x2:
            aspectRatio = CGSizeMake(3.0f, 2.0f);
            break;
        case TOCropViewControllerAspectRatioPreset5x3:
            aspectRatio = CGSizeMake(5.0f, 3.0f);
            break;
        case TOCropViewControllerAspectRatioPreset4x3:
            aspectRatio = CGSizeMake(4.0f, 3.0f);
            break;
        case TOCropViewControllerAspectRatioPreset5x4:
            aspectRatio = CGSizeMake(5.0f, 4.0f);
            break;
        case TOCropViewControllerAspectRatioPreset7x5:
            aspectRatio = CGSizeMake(7.0f, 5.0f);
            break;
        case TOCropViewControllerAspectRatioPreset16x9:
            aspectRatio = CGSizeMake(16.0f, 9.0f);
            break;
        case TOCropViewControllerAspectRatioPresetCustom:
            aspectRatio = self.customAspectRatio;
            break;
    }
    
    //If the image is a portrait shape, flip the aspect ratio to match
    if (aspectRatioPreset != TOCropViewControllerAspectRatioPresetCustom &&
        self.cropView.cropBoxAspectRatioIsPortrait &&
        !self.aspectRatioLockEnabled)
    {
        CGFloat width = aspectRatio.width;
        aspectRatio.width = aspectRatio.height;
        aspectRatio.height = width;
    }
    
    [self.cropView setAspectRatio:aspectRatio animated:animated];
}

- (void)rotateCropViewClockwise
{
    [self.cropView rotateImageNinetyDegreesAnimated:YES clockwise:YES];
}

- (void)rotateCropViewCounterclockwise
{
    [self.cropView rotateImageNinetyDegreesAnimated:YES clockwise:NO];
}

#pragma mark - Crop View Delegates -
- (void)cropViewDidBecomeResettable:(TOCropView *)cropView
{
    self.toolbar.resetButtonEnabled = YES;
}

- (void)cropViewDidBecomeNonResettable:(TOCropView *)cropView
{
    self.toolbar.resetButtonEnabled = NO;
}

#pragma mark - Presentation Handling -
- (void)presentAnimatedFromParentViewController:(UIViewController *)viewController
                                       fromView:(UIView *)fromView
                                      fromFrame:(CGRect)fromFrame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion
{
    [self presentAnimatedFromParentViewController:viewController fromImage:nil fromView:fromView fromFrame:fromFrame
                                            angle:0 toImageFrame:CGRectZero setup:setup completion:nil];
}

- (void)presentAnimatedFromParentViewController:(UIViewController *)viewController
                                      fromImage:(UIImage *)image
                                       fromView:(UIView *)fromView
                                      fromFrame:(CGRect)fromFrame
                                          angle:(NSInteger)angle
                                   toImageFrame:(CGRect)toFrame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion
{
    self.transitionController.image     = image ? image : self.image;
    self.transitionController.fromFrame = fromFrame;
    self.transitionController.fromView  = fromView;
    self.prepareForTransitionHandler    = setup;
    
    if (self.angle != 0 || !CGRectIsEmpty(toFrame)) {
        self.angle = angle;
        self.imageCropFrame = toFrame;
    }
    
    __weak typeof (self) weakSelf = self;
    [viewController presentViewController:self animated:YES completion:^ {
        typeof (self) strongSelf = weakSelf;
        if (completion) {
            completion();
        }
        
        [strongSelf.cropView setCroppingViewsHidden:NO animated:YES];
        if (!CGRectIsEmpty(fromFrame)) {
            [strongSelf.cropView setGridOverlayHidden:NO animated:YES];
        }
    }];
}

- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController
                                         toView:(UIView *)toView
                                        toFrame:(CGRect)frame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion
{
    [self dismissAnimatedFromParentViewController:viewController withCroppedImage:nil toView:toView toFrame:frame setup:setup completion:completion];
}

- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController
                               withCroppedImage:(UIImage *)image
                                         toView:(UIView *)toView
                                        toFrame:(CGRect)frame
                                          setup:(void (^)(void))setup
                                     completion:(void (^)(void))completion
{
    // If a cropped image was supplied, use that, and only zoom out from the crop box
    if (image) {
        self.transitionController.image     = image ? image : self.image;
        self.transitionController.fromFrame = [self.cropView convertRect:self.cropView.cropBoxFrame toView:self.view];
    }
    else { // else use the main image, and zoom out from its entirety
        self.transitionController.image     = self.image;
        self.transitionController.fromFrame = [self.cropView convertRect:self.cropView.imageViewFrame toView:self.view];
    }
    
    self.transitionController.toView    = toView;
    self.transitionController.toFrame   = frame;
    self.prepareForTransitionHandler    = setup;

    [viewController dismissViewControllerAnimated:YES completion:^ {
        if (completion) {
            completion();
        }
    }];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if (self.navigationController || self.modalTransitionStyle == UIModalTransitionStyleCoverVertical) {
        return nil;
    }
    
    self.cropView.simpleRenderMode = YES;
    
    __weak typeof (self) weakSelf = self;
    self.transitionController.prepareForTransitionHandler = ^{
        typeof (self) strongSelf = weakSelf;
        TOCropViewControllerTransitioning *transitioning = strongSelf.transitionController;
        
        transitioning.toFrame = [strongSelf.cropView convertRect:strongSelf.cropView.cropBoxFrame toView:strongSelf.view];
        if (!CGRectIsEmpty(transitioning.fromFrame) || transitioning.fromView) {
            strongSelf.cropView.croppingViewsHidden = YES;
        }

        if (strongSelf.prepareForTransitionHandler)
            strongSelf.prepareForTransitionHandler();
        
        strongSelf.prepareForTransitionHandler = nil;
    };
    
    self.transitionController.isDismissing = NO;
    return self.transitionController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    if (self.navigationController || self.modalTransitionStyle == UIModalTransitionStyleCoverVertical) {
        return nil;
    }
    
    __weak typeof (self) weakSelf = self;
    self.transitionController.prepareForTransitionHandler = ^{
        typeof (self) strongSelf = weakSelf;
        TOCropViewControllerTransitioning *transitioning = strongSelf.transitionController;
        
        if (!CGRectIsEmpty(transitioning.toFrame) || transitioning.toView)
            strongSelf.cropView.croppingViewsHidden = YES;
        else
            strongSelf.cropView.simpleRenderMode = YES;
        
        if (strongSelf.prepareForTransitionHandler)
            strongSelf.prepareForTransitionHandler();
    };
    
    self.transitionController.isDismissing = YES;
    return self.transitionController;
}

#pragma mark - Button Feedback -
- (void)cancelButtonTapped
{
    bool isDelegateOrCallbackHandled = NO;
    
    if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCancelled:)]) {
        [self.delegate cropViewController:self didFinishCancelled:YES];
        
        if (self.onDidFinishCancelled != nil) {
            self.onDidFinishCancelled(YES);
        }
        
        isDelegateOrCallbackHandled = YES;
    }
    
    if (self.onDidFinishCancelled != nil) {
        self.onDidFinishCancelled(YES);
        
        isDelegateOrCallbackHandled = YES;
    }
    
    if (!isDelegateOrCallbackHandled) {
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else {
            self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)doneButtonTapped
{
    CGRect cropFrame = self.cropView.imageCropFrame;
    NSInteger angle = self.cropView.angle;

    //If desired, when the user taps done, show an activity sheet
    if (self.showActivitySheetOnDone) {
        TOActivityCroppedImageProvider *imageItem = [[TOActivityCroppedImageProvider alloc] initWithImage:self.image cropFrame:cropFrame angle:angle circular:(self.croppingStyle == TOCropViewCroppingStyleCircular)];
        TOCroppedImageAttributes *attributes = [[TOCroppedImageAttributes alloc] initWithCroppedFrame:cropFrame angle:angle originalImageSize:self.image.size];
        
        NSMutableArray *activityItems = [@[imageItem, attributes] mutableCopy];
        if (self.activityItems)
            [activityItems addObjectsFromArray:self.activityItems];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:self.applicationActivities];
        activityController.excludedActivityTypes = self.excludedActivityTypes;
        
        if (NSClassFromString(@"UIPopoverPresentationController")) {
            activityController.modalPresentationStyle = UIModalPresentationPopover;
            activityController.popoverPresentationController.sourceView = self.toolbar;
            activityController.popoverPresentationController.sourceRect = self.toolbar.doneButtonFrame;
            [self presentViewController:activityController animated:YES completion:nil];
        }
        else {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                [self presentViewController:activityController animated:YES completion:nil];
            }
            else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [self.activityPopoverController dismissPopoverAnimated:NO];
                self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
                [self.activityPopoverController presentPopoverFromRect:self.toolbar.doneButtonFrame inView:self.toolbar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
#pragma clang diagnostic pop
            }
        }
        __weak typeof(activityController) blockController = activityController;
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
        activityController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            if (!completed)
                return;
            
            bool isCallbackOrDelegateHandled = NO;
            
            if (self.onDidFinishCancelled != nil) {
                self.onDidFinishCancelled(NO);
                isCallbackOrDelegateHandled = YES;
            }
            if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCancelled:)]) {
                [self.delegate cropViewController:self didFinishCancelled:NO];
                isCallbackOrDelegateHandled = YES;
            }
            
            if (!isCallbackOrDelegateHandled) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                blockController.completionWithItemsHandler = nil;
            }
        };
#else
        activityController.completionHandler = ^(NSString *activityType, BOOL completed) {
            if (!completed)
                return;
            
            bool isCallbackOrDelegateHandled = NO
            
            if (self.onDidFinishCancelled != nil) {
                self.onDidFinishCancelled(NO)
                isCallbackOrDelegateHandled = YES
            }
            if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCancelled:)]) {
                [self.delegate cropViewController:self didFinishCancelled:NO];
                isCallbackOrDelegateHandled = YES
            }
            
            if (!isCallbackOrDelegateHandled) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                blockController.completionHandler = nil;
            }
        };
#endif
        
        return;
    }
    
    BOOL isCallbackOrDelegateHandled = NO;
    
    //If the delegate/block that only supplies crop data is provided, call it
    if ([self.delegate respondsToSelector:@selector(cropViewController:didCropImageToRect:angle:)]) {
        [self.delegate cropViewController:self didCropImageToRect:cropFrame angle:angle];
        isCallbackOrDelegateHandled = YES;
    }
    if (self.onDidCropImageToRect != nil) {
        self.onDidCropImageToRect(cropFrame, angle);
        isCallbackOrDelegateHandled = YES;
    }
    
    BOOL isCircularImageDelegateAvailable = [self.delegate respondsToSelector:@selector(cropViewController:didCropToCircularImage:withRect:angle:)];
    BOOL isCircularImageCallbackAvailable = self.onDidCropToCircleImage != nil;
    
    //If cropping circular and the circular generation delegate/block is implemented, call it
    if (self.croppingStyle == TOCropViewCroppingStyleCircular && (isCircularImageDelegateAvailable || isCircularImageCallbackAvailable)) {
        UIImage *image = [self.image croppedImageWithFrame:cropFrame angle:angle circularClip:YES];
        
        //Dispatch on the next run-loop so the animation isn't interuppted by the crop operation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.03f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (isCircularImageDelegateAvailable) {
                [self.delegate cropViewController:self didCropToCircularImage:image withRect:cropFrame angle:angle];
            }
            if (isCircularImageCallbackAvailable) {
                self.onDidCropToCircleImage(image, cropFrame, angle);
            }
        });
        
        isCallbackOrDelegateHandled = YES;
    }
    
    BOOL isDidCropToImageDelegateAvailable = [self.delegate respondsToSelector:@selector(cropViewController:didCropToImage:withRect:angle:)];
    BOOL isDidCropToImageCallbackAvailable = self.onDidCropToRect != nil;
    
    //If the delegate/block that requires the specific cropped image is provided, call it
    if (isDidCropToImageDelegateAvailable || isDidCropToImageCallbackAvailable) {
        UIImage *image = nil;
        if (angle == 0 && CGRectEqualToRect(cropFrame, (CGRect){CGPointZero, self.image.size})) {
            image = self.image;
        }
        else {
            image = [self.image croppedImageWithFrame:cropFrame angle:angle circularClip:NO];
        }
        
        //Dispatch on the next run-loop so the animation isn't interuppted by the crop operation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.03f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (isDidCropToImageDelegateAvailable) {
                [self.delegate cropViewController:self didCropToImage:image withRect:cropFrame angle:angle];
            }
            if (isDidCropToImageCallbackAvailable) {
                self.onDidCropToRect(image, cropFrame, angle);
            }
            
        });
        
        isCallbackOrDelegateHandled = YES;
    }
    
    if (!isCallbackOrDelegateHandled) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Property Methods -

- (TOCropView *)cropView {
    if (!_cropView) {
        _cropView = [[TOCropView alloc] initWithCroppingStyle:self.croppingStyle image:self.image];
        _cropView.delegate = self;
        _cropView.frame = [UIScreen mainScreen].bounds;
        _cropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _cropView;
}

- (TOCropToolbar *)toolbar {
    if (!_toolbar) {
        _toolbar = [[TOCropToolbar alloc] initWithFrame:CGRectZero];
    }
    return _toolbar;
}

- (void)setAspectRatioLockEnabled:(BOOL)aspectRatioLockEnabled
{
    self.toolbar.clampButtonGlowing = aspectRatioLockEnabled;
    self.cropView.aspectRatioLockEnabled = aspectRatioLockEnabled;
    self.aspectRatioPickerButtonHidden = (aspectRatioLockEnabled && self.resetAspectRatioEnabled == NO);
}

- (BOOL)aspectRatioLockEnabled
{
    return self.cropView.aspectRatioLockEnabled;
}

- (void)setRotateButtonsHidden:(BOOL)rotateButtonsHidden
{
    self.toolbar.rotateCounterclockwiseButtonHidden = rotateButtonsHidden;
    
    if (self.rotateClockwiseButtonHidden == NO) {
        self.toolbar.rotateClockwiseButtonHidden = rotateButtonsHidden;
    }
}

- (BOOL)rotateButtonsHidden
{
    if (self.rotateClockwiseButtonHidden == NO) {
        return self.toolbar.rotateCounterclockwiseButtonHidden && self.toolbar.rotateClockwiseButtonHidden;
    }
    
    return self.toolbar.rotateCounterclockwiseButtonHidden;
}

- (void)setRotateClockwiseButtonHidden:(BOOL)rotateClockwiseButtonHidden
{
    if (_rotateClockwiseButtonHidden == rotateClockwiseButtonHidden) {
        return;
    }
    
    _rotateClockwiseButtonHidden = rotateClockwiseButtonHidden;
    
    if (self.rotateButtonsHidden == NO) {
        self.toolbar.rotateClockwiseButtonHidden = _rotateClockwiseButtonHidden;
    }
}

- (void)setAspectRatioPickerButtonHidden:(BOOL)aspectRatioPickerButtonHidden
{
    self.toolbar.clampButtonHidden = aspectRatioPickerButtonHidden;
}

- (BOOL)aspectRatioPickerButtonHidden
{
    return self.toolbar.clampButtonHidden;
}

- (void)setResetAspectRatioEnabled:(BOOL)resetAspectRatioEnabled
{
    self.cropView.resetAspectRatioEnabled = resetAspectRatioEnabled;
    self.aspectRatioPickerButtonHidden = (resetAspectRatioEnabled == NO && self.aspectRatioLockEnabled);
}

- (void)setCustomAspectRatio:(CGSize)customAspectRatio
{
    _customAspectRatio = customAspectRatio;
    [self setAspectRatioPreset:TOCropViewControllerAspectRatioPresetCustom animated:NO];
}

- (BOOL)resetAspectRatioEnabled
{
    return self.cropView.resetAspectRatioEnabled;
}

- (void)setAngle:(NSInteger)angle
{
    self.cropView.angle = angle;
}

- (NSInteger)angle
{
    return self.cropView.angle;
}

- (void)setImageCropFrame:(CGRect)imageCropFrame
{
    self.cropView.imageCropFrame = imageCropFrame;
}

- (CGRect)imageCropFrame
{
    return self.cropView.imageCropFrame;
}

@end
