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

#import "TOCropViewController.h"
#import "TOCropViewControllerTransitioning.h"
#import "TOActivityCroppedImageProvider.h"
#import "UIImage+CropRotate.h"
#import "TOCroppedImageAttributes.h"

@interface TOCropViewController () <UIActionSheetDelegate, UIViewControllerTransitioningDelegate, TOCropViewDelegate>

@property (nonatomic, readwrite) UIImage *image;
@property (nonatomic, strong) TOCropToolbar *toolbar;
@property (nonatomic, strong, readwrite) TOCropView *cropView;
@property (nonatomic, strong) UIView *snapshotView;
@property (nonatomic, strong) TOCropViewControllerTransitioning *transitionController;
@property (nonatomic, assign) BOOL inTransition;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UIPopoverController *activityPopoverController;
#pragma clang diagnostic pop

/* Button callback */
- (void)cancelButtonTapped;
- (void)doneButtonTapped;
- (void)showAspectRatioDialog;
- (void)resetCropViewLayout;
- (void)rotateCropView;

/* View layout */
- (CGRect)frameForToolBarWithVerticalLayout:(BOOL)verticalLayout;
- (CGRect)frameForCropViewWithVerticalLayout:(BOOL)verticalLayout;

@end

@implementation TOCropViewController

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        
        _transitionController = [[TOCropViewControllerTransitioning alloc] init];
        _image = image;
        
        _defaultAspectRatio = TOCropViewControllerAspectRatioOriginal;
        _toolbarPosition = TOCropViewControllerToolbarPositionBottom;
        _lockedAspectRatio = NO;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.cropView.frame = [self frameForCropViewWithVerticalLayout:CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)];
    [self.view addSubview:self.cropView];

    self.toolbar.frame = [self frameForToolBarWithVerticalLayout:CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds)];
    [self.view addSubview:self.toolbar];
    
    __weak typeof(self) weakSelf = self;
    self.toolbar.doneButtonTapped =     ^{ [weakSelf doneButtonTapped]; };
    self.toolbar.cancelButtonTapped =   ^{ [weakSelf cancelButtonTapped]; };
    self.toolbar.resetButtonTapped =    ^{ [weakSelf resetCropViewLayout]; };
    self.toolbar.clampButtonTapped =    ^{ [weakSelf showAspectRatioDialog]; };
    self.toolbar.rotateButtonTapped =   ^{ [weakSelf rotateCropView]; };
    
    self.transitioningDelegate = self;
    
    self.view.backgroundColor = self.cropView.backgroundColor;

    if (self.defaultAspectRatio != TOCropViewControllerAspectRatioOriginal) {
        [self setAspectRatio:self.defaultAspectRatio animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([UIApplication sharedApplication].statusBarHidden == NO) {
        self.inTransition = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.inTransition = NO;
    if (animated && [UIApplication sharedApplication].statusBarHidden == NO) {
        [UIView animateWithDuration:0.3f animations:^{ [self setNeedsStatusBarAppearanceUpdate]; }];
        
        if (self.cropView.gridOverlayHidden)
            [self.cropView setGridOverlayHidden:NO animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.inTransition = YES;
    [UIView animateWithDuration:0.5f animations:^{ [self setNeedsStatusBarAppearanceUpdate]; }];
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
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return !self.inTransition;
}

- (CGRect)frameForToolBarWithVerticalLayout:(BOOL)verticalLayout
{
    CGRect frame = self.toolbar.frame;
    if (verticalLayout ) {
        frame = self.toolbar.frame;
        frame.origin.x = 0.0f;
        frame.origin.y = 0.0f;
        frame.size.width = 44.0f;
        frame.size.height = CGRectGetHeight(self.view.frame);
    }
    else {
        frame.origin.x = 0.0f;
        
        if (_toolbarPosition == TOCropViewControllerToolbarPositionBottom) {
            frame.origin.y = CGRectGetHeight(self.view.bounds) - 44.0f;
        } else {
            frame.origin.y = 0;
        }
        
        frame.size.width = CGRectGetWidth(self.view.bounds);
        frame.size.height = 44.0f;
    }
    
    return frame;
}

- (CGRect)frameForCropViewWithVerticalLayout:(BOOL)verticalLayout
{
    CGRect frame = self.cropView.frame;
    if (verticalLayout ) {
        frame.origin.x = 44.0f;
        frame.origin.y = 0.0f;
        frame.size.width = CGRectGetWidth(self.view.bounds) - 44.0f;
        frame.size.height = CGRectGetHeight(self.view.frame);
    }
    else {
        frame.origin.x = 0.0f;
        
        if (_toolbarPosition == TOCropViewControllerToolbarPositionBottom) {
            frame.origin.y = 0.0f;
        } else {
            frame.origin.y = 44.0f;
        }

        frame.size.width = CGRectGetWidth(self.view.bounds);
        frame.size.height = CGRectGetHeight(self.view.frame) - 44.0f;
    }
    
    return frame;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    BOOL verticalLayout = CGRectGetWidth(self.view.bounds) > CGRectGetHeight(self.view.bounds);
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:verticalLayout];
    
    [self.cropView prepareforRotation];
    [self.cropView performRelayoutForRotation];
    
    [UIView setAnimationsEnabled:NO];
    self.toolbar.frame = [self frameForToolBarWithVerticalLayout:verticalLayout];
    [self.toolbar setNeedsLayout];
    [UIView setAnimationsEnabled:YES];
}

#pragma mark - Rotation Handling -

//TODO: Deprecate iOS 7 properly at the right time
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.snapshotView = [self.toolbar snapshotViewAfterScreenUpdates:NO];
    self.snapshotView.frame = self.toolbar.frame;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        self.snapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    else
        self.snapshotView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    
    [self.view addSubview:self.snapshotView];

    self.toolbar.frame = [self frameForToolBarWithVerticalLayout:UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    [self.toolbar layoutIfNeeded];
    
    self.toolbar.alpha = 0.0f;
    
    self.cropView.simpleMode = YES;
    [self.cropView prepareforRotation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.toolbar.frame = [self frameForToolBarWithVerticalLayout:UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    
    [UIView animateWithDuration:duration animations:^{
        self.snapshotView.alpha = 0.0f;
        self.toolbar.alpha = 1.0f;
    }];
    [self.cropView performRelayoutForRotation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.snapshotView removeFromSuperview];
    self.snapshotView = nil;
    
    [self.cropView setSimpleMode:NO animated:YES];
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
    [self.cropView resetLayoutToDefaultAnimated:YES];
    
    if (self.lockedAspectRatio) {
        [self setAspectRatio:self.defaultAspectRatio animated:NO];
    } else {
        self.cropView.aspectLockEnabled = NO;
        self.toolbar.clampButtonGlowing = NO;
    }
}

#pragma mark - Aspect Ratio Handling -
- (void)showAspectRatioDialog
{
    if (self.cropView.aspectLockEnabled) {
        self.cropView.aspectLockEnabled = NO;
        self.toolbar.clampButtonGlowing = NO;
        return;
    }
    
    //Depending on the shape of the image, work out if horizontal, or vertical options are required
    BOOL verticalCropBox = self.cropView.cropBoxAspectRatioIsPortrait;
    
    //Prepare the localized options
    NSString *cancelButtonTitle = NSLocalizedStringFromTableInBundle(@"Cancel", @"TOCropViewControllerLocalizable", [NSBundle bundleForClass:[self class]], nil);
    NSString *originalButtonTitle = NSLocalizedStringFromTableInBundle(@"Original", @"TOCropViewControllerLocalizable", [NSBundle bundleForClass:[self class]], nil);
    NSString *squareButtonTitle = NSLocalizedStringFromTableInBundle(@"Square", @"TOCropViewControllerLocalizable", [NSBundle bundleForClass:[self class]], nil);
    
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
                [self setAspectRatio:(TOCropViewControllerAspectRatio)i animated:YES];
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
    [self setAspectRatio:(TOCropViewControllerAspectRatio)buttonIndex animated:YES];
}
#pragma clang diagnostic pop

- (void)setAspectRatio:(TOCropViewControllerAspectRatio)aspectRatioSize animated:(BOOL)animated
{
    CGSize aspectRatio = CGSizeZero;
    
    switch (aspectRatioSize) {
        case TOCropViewControllerAspectRatioOriginal:
            aspectRatio = CGSizeZero;
            break;
        case TOCropViewControllerAspectRatioSquare:
            aspectRatio = CGSizeMake(1.0f, 1.0f);
            break;
        case TOCropViewControllerAspectRatio3x2:
            aspectRatio = CGSizeMake(3.0f, 2.0f);
            break;
        case TOCropViewControllerAspectRatio5x3:
            aspectRatio = CGSizeMake(5.0f, 3.0f);
            break;
        case TOCropViewControllerAspectRatio4x3:
            aspectRatio = CGSizeMake(4.0f, 3.0f);
            break;
        case TOCropViewControllerAspectRatio5x4:
            aspectRatio = CGSizeMake(5.0f, 4.0f);
            break;
        case TOCropViewControllerAspectRatio7x5:
            aspectRatio = CGSizeMake(7.0f, 5.0f);
            break;
        case TOCropViewControllerAspectRatio16x9:
            aspectRatio = CGSizeMake(16.0f, 9.0f);
            break;
    }
    
    if (self.cropView.cropBoxAspectRatioIsPortrait) {
        CGFloat width = aspectRatio.width;
        aspectRatio.width = aspectRatio.height;
        aspectRatio.height = width;
    }
    
    [self.cropView setAspectLockEnabledWithAspectRatio:aspectRatio animated:animated];
    self.toolbar.clampButtonGlowing = YES;
}

- (void)rotateCropView
{
    [self.cropView rotateImageNinetyDegreesAnimated:YES];
    if (self.lockedAspectRatio) {
        [self setAspectRatio:self.defaultAspectRatio animated:NO];
    }
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
- (void)presentAnimatedFromParentViewController:(UIViewController *)viewController fromFrame:(CGRect)frame completion:(void (^)(void))completion
{
    self.transitionController.image = self.image;
    self.transitionController.fromFrame = frame;

    __weak typeof (self) weakSelf = self;
    [viewController presentViewController:self animated:YES completion:^ {
        typeof (self) strongSelf = weakSelf;
        if (completion) {
            completion();
        }
        
        [strongSelf.cropView setCroppingViewsHidden:NO animated:YES];
        if (!CGRectIsEmpty(frame)) {
            [strongSelf.cropView setGridOverlayHidden:NO animated:YES];
        }
    }];
}

- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController withCroppedImage:(UIImage *)image toFrame:(CGRect)frame completion:(void (^)(void))completion
{
    self.transitionController.image = image;
    self.transitionController.fromFrame = [self.cropView convertRect:self.cropView.cropBoxFrame toView:self.view];
    self.transitionController.toFrame = frame;

    [viewController dismissViewControllerAnimated:YES completion:^ {
        if (completion) {
            completion();
        }
    }];
}

- (void)dismissAnimatedFromParentViewController:(UIViewController *)viewController toFrame:(CGRect)frame completion:(void (^)(void))completion
{
    self.transitionController.image = self.image;
    self.transitionController.fromFrame = [self.cropView convertRect:self.cropView.imageViewFrame toView:self.view];
    self.transitionController.toFrame = frame;
    
    [viewController dismissViewControllerAnimated:YES completion:^ {
        if (completion) {
            completion();
        }
    }];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    __weak typeof (self) weakSelf = self;
    self.transitionController.prepareForTransitionHandler = ^{
        typeof (self) strongSelf = weakSelf;
        strongSelf.transitionController.toFrame = [strongSelf.cropView convertRect:strongSelf.cropView.cropBoxFrame toView:strongSelf.view];
        if (!CGRectIsEmpty(strongSelf.transitionController.fromFrame))
            strongSelf.cropView.croppingViewsHidden = YES;
        
        if (strongSelf.prepareForTransitionHandler)
            strongSelf.prepareForTransitionHandler();
        
        strongSelf.prepareForTransitionHandler = nil;
    };
    
    self.transitionController.isDismissing = NO;
    return self.transitionController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    __weak typeof (self) weakSelf = self;
    self.transitionController.prepareForTransitionHandler = ^{
        typeof (self) strongSelf = weakSelf;
        if (!CGRectIsEmpty(strongSelf.transitionController.toFrame))
            strongSelf.cropView.croppingViewsHidden = YES;
        else
            strongSelf.cropView.simpleMode = YES;
        
        if (strongSelf.prepareForTransitionHandler)
            strongSelf.prepareForTransitionHandler();
    };
    
    self.transitionController.isDismissing = YES;
    return self.transitionController;
}

#pragma mark - Button Feedback -
- (void)cancelButtonTapped
{
    if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCancelled:)]) {
        [self.delegate cropViewController:self didFinishCancelled:YES];
        return;
    }
    
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonTapped
{
    CGRect cropFrame = self.cropView.croppedImageFrame;
    NSInteger angle = self.cropView.angle;

    //If desired, when the user taps done, show an activity sheet
    if (self.showActivitySheetOnDone) {
        TOActivityCroppedImageProvider *imageItem = [[TOActivityCroppedImageProvider alloc] initWithImage:self.image cropFrame:cropFrame angle:angle];
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
            
            if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCancelled:)]) {
                [self.delegate cropViewController:self didFinishCancelled:NO];
            }
            else {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                blockController.completionWithItemsHandler = nil;
            }
        };
        #else
        activityController.completionHandler = ^(NSString *activityType, BOOL completed) {
            if (!completed)
                return;
            
            if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCancelled:)]) {
                [self.delegate cropViewController:self didFinishCancelled:NO];
            }
            else {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                blockController.completionHandler = nil;
            }
        };
        #endif
        
        return;
    }
    
    //If the delegate that only supplies crop data is provided, call it
    if ([self.delegate respondsToSelector:@selector(cropViewController:didCropImageToRect:angle:)]) {
        [self.delegate cropViewController:self didCropImageToRect:cropFrame angle:angle];
    }
    //If the delegate that requires the specific cropped image is provided, call it
    else if ([self.delegate respondsToSelector:@selector(cropViewController:didCropToImage:withRect:angle:)]) {
        UIImage *image = nil;
        if (angle == 0 && CGRectEqualToRect(cropFrame, (CGRect){CGPointZero, self.image.size})) {
            image = self.image;
        }
        else {
            image = [self.image croppedImageWithFrame:cropFrame angle:angle];
        }
        
        //dispatch on the next run-loop so the animation isn't interuppted by the crop operation
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.03f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.delegate cropViewController:self didCropToImage:image withRect:cropFrame angle:angle];
        });
    }
    else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Property methods

- (TOCropView *)cropView {
    if (!_cropView) {
        _cropView = [[TOCropView alloc] initWithImage:self.image];
        _cropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _cropView.delegate = self;
        _cropView.frame = [UIScreen mainScreen].bounds;
    }
    return _cropView;
}

- (TOCropToolbar *)toolbar {
    if (!_toolbar) {
        static CGFloat height = 44.f;
        CGRect frame = CGRectMake(.0f,
                                  CGRectGetHeight([UIScreen mainScreen].bounds) - height,
                                  CGRectGetWidth([UIScreen mainScreen].bounds),
                                  height);
        _toolbar = [[TOCropToolbar alloc] initWithFrame:frame];
    }
    return _toolbar;
}

@end
