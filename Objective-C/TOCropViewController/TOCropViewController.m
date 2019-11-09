//
//  TOCropViewController.m
//
//  Copyright 2015-2018 Timothy Oliver. All rights reserved.
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

static const CGFloat kTOCropViewControllerTitleTopPadding = 14.0f;
static const CGFloat kTOCropViewControllerToolbarHeight = 44.0f;

@interface TOCropViewController () <UIActionSheetDelegate, UIViewControllerTransitioningDelegate, TOCropViewDelegate>

/* The target image */
@property (nonatomic, readwrite) UIImage *image;

/* The cropping style of the crop view */
@property (nonatomic, assign, readwrite) TOCropViewCroppingStyle croppingStyle;

/* Views */
@property (nonatomic, strong) TOCropToolbar *toolbar;
@property (nonatomic, strong, readwrite) TOCropView *cropView;
@property (nonatomic, strong) UIView *toolbarSnapshotView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;

/* Transition animation controller */
@property (nonatomic, copy) void (^prepareForTransitionHandler)(void);
@property (nonatomic, strong) TOCropViewControllerTransitioning *transitionController;
@property (nonatomic, assign) BOOL inTransition;

/* If pushed from a navigation controller, the visibility of that controller's bars. */
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, assign) BOOL toolbarHidden;

/* State for whether content is being laid out vertically or horizontally */
@property (nonatomic, readonly) BOOL verticalLayout;

/* Convenience method for managing status bar state */
@property (nonatomic, readonly) BOOL overrideStatusBar; // Whether the view controller needs to touch the status bar
@property (nonatomic, readonly) BOOL statusBarHidden;   // Whether it should be hidden or visible at this point
@property (nonatomic, readonly) CGFloat statusBarHeight; // The height of the status bar when visible

/* Convenience method for getting the vertical inset for both iPhone X and status bar */
@property (nonatomic, readonly) UIEdgeInsets statusBarSafeInsets;

/* Flag to perform initial setup on the first run */
@property (nonatomic, assign) BOOL firstTime;

@end

@implementation TOCropViewController

- (instancetype)initWithCroppingStyle:(TOCropViewCroppingStyle)style image:(UIImage *)image
{
    NSParameterAssert(image);

    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Init parameters
        _image = image;
        _croppingStyle = style;
        
        // Set up base view controller behaviour
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.hidesNavigationBar = true;
        
        // Controller object that handles the transition animation when presenting / dismissing this app
        _transitionController = [[TOCropViewControllerTransitioning alloc] init];

        // Default initial behaviour
        _aspectRatioPreset = TOCropViewControllerAspectRatioPresetOriginal;
        _toolbarPosition = TOCropViewControllerToolbarPositionBottom;
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

    // Set up view controller properties
    self.transitioningDelegate = self;
    self.view.backgroundColor = self.cropView.backgroundColor;
    
    BOOL circularMode = (self.croppingStyle == TOCropViewCroppingStyleCircular);

    // Layout the views initially
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:self.verticalLayout];
    self.toolbar.frame = [self frameForToolbarWithVerticalLayout:self.verticalLayout];

    // Set up toolbar default behaviour
    self.toolbar.clampButtonHidden = self.aspectRatioPickerButtonHidden || circularMode;
    self.toolbar.rotateClockwiseButtonHidden = self.rotateClockwiseButtonHidden;
    
    // Set up the toolbar button actions
    __weak typeof(self) weakSelf = self;
    self.toolbar.doneButtonTapped   = ^{ [weakSelf doneButtonTapped]; };
    self.toolbar.cancelButtonTapped = ^{ [weakSelf cancelButtonTapped]; };
    self.toolbar.resetButtonTapped = ^{ [weakSelf resetCropViewLayout]; };
    self.toolbar.clampButtonTapped = ^{ [weakSelf showAspectRatioDialog]; };
    self.toolbar.rotateCounterclockwiseButtonTapped = ^{ [weakSelf rotateCropViewCounterclockwise]; };
    self.toolbar.rotateClockwiseButtonTapped        = ^{ [weakSelf rotateCropViewClockwise]; };
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // If we're animating onto the screen, set a flag
    // so we can manually control the status bar fade out timing
    if (animated) {
        self.inTransition = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    // If this controller is pushed onto a navigation stack, set flags noting the
    // state of the navigation controller bars before we present, and then hide them
    if (self.navigationController) {
        if (self.hidesNavigationBar) {
            self.navigationBarHidden = self.navigationController.navigationBarHidden;
            self.toolbarHidden = self.navigationController.toolbarHidden;
            [self.navigationController setNavigationBarHidden:YES animated:animated];
            [self.navigationController setToolbarHidden:YES animated:animated];
        }

        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    }
    else {
        // Hide the background content when transitioning for performance
        [self.cropView setBackgroundImageViewHidden:YES animated:NO];
        
        // The title label will fade
        self.titleLabel.alpha = animated ? 0.0f : 1.0f;
    }

    // If an initial aspect ratio was set before presentation, set it now once the rest of
    // the setup will have been done
    if (self.aspectRatioPreset != TOCropViewControllerAspectRatioPresetOriginal) {
        [self setAspectRatioPreset:self.aspectRatioPreset animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Disable the transition flag for the status bar
    self.inTransition = NO;
    
    // Re-enable translucency now that the animation has completed
    self.cropView.simpleRenderMode = NO;

    // Now that the presentation animation will have finished, animate
    // the status bar fading out, and if present, the title label fading in
    void (^updateContentBlock)(void) = ^{
        [self setNeedsStatusBarAppearanceUpdate];
        self.titleLabel.alpha = 1.0f;
    };

    if (animated) {
        [UIView animateWithDuration:0.3f animations:updateContentBlock];
    }
    else {
        updateContentBlock();
    }
    
    // Make the grid overlay view fade in
    if (self.cropView.gridOverlayHidden) {
        [self.cropView setGridOverlayHidden:NO animated:animated];
    }
    
    // Fade in the background view content
    if (self.navigationController == nil) {
        [self.cropView setBackgroundImageViewHidden:NO animated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Set the transition flag again so we can defer the status bar
    self.inTransition = YES;
    [UIView animateWithDuration:0.5f animations:^{ [self setNeedsStatusBarAppearanceUpdate]; }];
    
    // Restore the navigation controller to its state before we were presented
    if (self.navigationController && self.hidesNavigationBar) {
        [self.navigationController setNavigationBarHidden:self.navigationBarHidden animated:animated];
        [self.navigationController setToolbarHidden:self.toolbarHidden animated:animated];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Reset the state once the view has gone offscreen
    self.inTransition = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - Status Bar -
- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.navigationController) {
        return UIStatusBarStyleLightContent;
    }

    // Even though we are a dark theme, leave the status bar
    // as black so it's not obvious that it's still visible during the transition
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    // Disregard the transition animation if we're not actively overriding it
    if (!self.overrideStatusBar) {
        return self.statusBarHidden;
    }

    // Work out whether the status bar needs to be visible
    // during a transition animation or not
    BOOL hidden = YES; // Default is yes
    hidden = hidden && !(self.inTransition); // Not currently in a presentation animation (Where removing the status bar would break the layout)
    hidden = hidden && !(self.view.superview == nil); // Not currently waiting to be added to a super view
    return hidden;
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures
{
    return UIRectEdgeAll;
}

- (CGRect)frameForToolbarWithVerticalLayout:(BOOL)verticalLayout
{
    UIEdgeInsets insets = self.statusBarSafeInsets;

    CGRect frame = CGRectZero;
    if (!verticalLayout) { // In landscape laying out toolbar to the left
        frame.origin.x = insets.left;
        frame.origin.y = 0.0f;
        frame.size.width = kTOCropViewControllerToolbarHeight;
        frame.size.height = CGRectGetHeight(self.view.frame);
    }
    else {
        frame.origin.x = 0.0f;
        frame.size.width = CGRectGetWidth(self.view.bounds);
        frame.size.height = kTOCropViewControllerToolbarHeight;

        if (self.toolbarPosition == TOCropViewControllerToolbarPositionBottom) {
            frame.origin.y = CGRectGetHeight(self.view.bounds) - (frame.size.height + insets.bottom);
        } else {
            frame.origin.y = insets.top;
        }
    }
    
    return frame;
}

- (CGRect)frameForCropViewWithVerticalLayout:(BOOL)verticalLayout
{
    //On an iPad, if being presented in a modal view controller by a UINavigationController,
    //at the time we need it, the size of our view will be incorrect.
    //If this is the case, derive our view size from our parent view controller instead
    UIView *view = nil;
    if (self.parentViewController == nil) {
        view = self.view;
    }
    else {
        view = self.parentViewController.view;
    }

    UIEdgeInsets insets = self.statusBarSafeInsets;

    CGRect bounds = view.bounds;
    CGRect frame = CGRectZero;

    // Horizontal layout (eg landscape)
    if (!verticalLayout) {
        frame.origin.x = kTOCropViewControllerToolbarHeight + insets.left;
        frame.size.width = CGRectGetWidth(bounds) - frame.origin.x;
		frame.size.height = CGRectGetHeight(bounds);
    }
    else { // Vertical layout
        frame.size.height = CGRectGetHeight(bounds);
        frame.size.width = CGRectGetWidth(bounds);

        // Set Y and adjust for height
        if (self.toolbarPosition == TOCropViewControllerToolbarPositionBottom) {
            frame.size.height -= (insets.bottom + kTOCropViewControllerToolbarHeight);
        } else if (self.toolbarPosition == TOCropViewControllerToolbarPositionTop) {
			frame.origin.y = kTOCropViewControllerToolbarHeight + insets.top;
            frame.size.height -= frame.origin.y;
        }
    }
    
    return frame;
}

- (CGRect)frameForTitleLabelWithSize:(CGSize)size verticalLayout:(BOOL)verticalLayout
{
    CGRect frame = (CGRect){CGPointZero, size};
    CGFloat viewWidth = self.view.bounds.size.width;
    CGFloat x = 0.0f; // Additional X offset in landscape mode

    // Adjust for landscape layout
    if (!verticalLayout) {
        x = kTOCropViewControllerTitleTopPadding;
        if (@available(iOS 11.0, *)) {
            x += self.view.safeAreaInsets.left;
        }

        viewWidth -= x;
    }

    // Work out horizontal position
    frame.origin.x = ceilf((viewWidth - frame.size.width) * 0.5f);
    if (!verticalLayout) { frame.origin.x += x; }

    // Work out vertical position
    if (@available(iOS 11.0, *)) {
        frame.origin.y = self.view.safeAreaInsets.top + kTOCropViewControllerTitleTopPadding;
    }
    else {
        frame.origin.y = self.statusBarHeight + kTOCropViewControllerTitleTopPadding;
    }

    return frame;
}

- (void)adjustCropViewInsets
{
    UIEdgeInsets insets = self.statusBarSafeInsets;

    // If there is no title text, inset the top of the content as high as possible
    if (!self.titleLabel.text.length) {
        if (self.verticalLayout) {
          if (self.toolbarPosition == TOCropViewControllerToolbarPositionTop) {
            self.cropView.cropRegionInsets = UIEdgeInsetsMake(0.0f, 0.0f, insets.bottom, 0.0f);
          }
          else { // Add padding to the top otherwise
            self.cropView.cropRegionInsets = UIEdgeInsetsMake(insets.top, 0.0f, 0.0, 0.0f);
          }
        }
        else {
            self.cropView.cropRegionInsets = UIEdgeInsetsMake(0.0f, 0.0f, insets.bottom, 0.0f);
        }

        return;
    }

    // Work out the size of the title label based on the crop view size
    CGRect frame = self.titleLabel.frame;
    frame.size = [self.titleLabel sizeThatFits:self.cropView.frame.size];
    self.titleLabel.frame = frame;

    // Set out the appropriate inset for that
    CGFloat verticalInset = self.statusBarHeight;
    verticalInset += kTOCropViewControllerTitleTopPadding;
    verticalInset += self.titleLabel.frame.size.height;
    self.cropView.cropRegionInsets = UIEdgeInsetsMake(verticalInset, 0, insets.bottom, 0);
}

- (void)adjustToolbarInsets
{
    UIEdgeInsets insets = UIEdgeInsetsZero;

    if (@available(iOS 11.0, *)) {
        // Add padding to the left in landscape mode
        if (!self.verticalLayout) {
            insets.left = self.view.safeAreaInsets.left;
        }
        else {
            // Add padding on top if in vertical and tool bar is at the top
            if (self.toolbarPosition == TOCropViewControllerToolbarPositionTop) {
                insets.top = self.view.safeAreaInsets.top;
            }
            else { // Add padding to the bottom otherwise
                insets.bottom = self.view.safeAreaInsets.bottom;
            }
        }
    }
    else { // iOS <= 10
        if (!self.statusBarHidden && self.toolbarPosition == TOCropViewControllerToolbarPositionTop) {
            insets.top = self.statusBarHeight;
        }
    }

    // Update the toolbar with these properties
    self.toolbar.backgroundViewOutsets = insets;
    self.toolbar.statusBarHeightInset = self.statusBarHeight;
    [self.toolbar setNeedsLayout];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    [self adjustCropViewInsets];
    [self adjustToolbarInsets];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    self.cropView.frame = [self frameForCropViewWithVerticalLayout:self.verticalLayout];
    [self adjustCropViewInsets];
    [self.cropView moveCroppedContentToCenterAnimated:NO];

    if (self.firstTime == NO) {
        [self.cropView performInitialSetup];
        self.firstTime = YES;
    }
    
    if (self.title.length) {
        self.titleLabel.frame = [self frameForTitleLabelWithSize:self.titleLabel.frame.size verticalLayout:self.verticalLayout];
        [self.cropView moveCroppedContentToCenterAnimated:NO];
    }

    [UIView performWithoutAnimation:^{
        self.toolbar.frame = [self frameForToolbarWithVerticalLayout:self.verticalLayout];
        [self adjustToolbarInsets];
        [self.toolbar setNeedsLayout];
    }];
}

#pragma mark - Rotation Handling -

- (void)_willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    self.toolbarSnapshotView = [self.toolbar snapshotViewAfterScreenUpdates:NO];
    self.toolbarSnapshotView.frame = self.toolbar.frame;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        self.toolbarSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    }
    else {
        self.toolbarSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    }
    [self.view addSubview:self.toolbarSnapshotView];

    // Set up the toolbar frame to be just off t
    CGRect frame = [self frameForToolbarWithVerticalLayout:UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        frame.origin.x = -frame.size.width;
    }
    else {
        frame.origin.y = self.view.bounds.size.height;
    }
    self.toolbar.frame = frame;

    [self.toolbar layoutIfNeeded];
    self.toolbar.alpha = 0.0f;
    
    [self.cropView prepareforRotation];
    self.cropView.frame = [self frameForCropViewWithVerticalLayout:!UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
    self.cropView.simpleRenderMode = YES;
    self.cropView.internalLayoutDisabled = YES;
}

- (void)_willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //Remove all animations in the toolbar
    self.toolbar.frame = [self frameForToolbarWithVerticalLayout:!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
    [self.toolbar.layer removeAllAnimations];
    for (CALayer *sublayer in self.toolbar.layer.sublayers) {
        [sublayer removeAllAnimations];
    }

    // On iOS 11, since these layout calls are done multiple times, if we don't aggregate from the
    // current state, the animation breaks.
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:
    ^{
        self.cropView.frame = [self frameForCropViewWithVerticalLayout:!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
        self.toolbar.frame = [self frameForToolbarWithVerticalLayout:UIInterfaceOrientationIsPortrait(toInterfaceOrientation)];
        [self.cropView performRelayoutForRotation];
    } completion:nil];

    self.toolbarSnapshotView.alpha = 0.0f;
    self.toolbar.alpha = 1.0f;
}

- (void)_didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.toolbarSnapshotView removeFromSuperview];
    self.toolbarSnapshotView = nil;
    
    [self.cropView setSimpleRenderMode:NO animated:YES];
    self.cropView.internalLayoutDisabled = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // If the size doesn't change (e.g, we did a 180 degree device rotation), don't bother doing a relayout
    if (CGSizeEqualToSize(size, self.view.bounds.size)) { return; }
    
    UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
    CGSize currentSize = self.view.bounds.size;
    if (currentSize.width < size.width) {
        orientation = UIInterfaceOrientationLandscapeLeft;
    }
    
    [self _willRotateToInterfaceOrientation:orientation duration:coordinator.transitionDuration];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self _willAnimateRotationToInterfaceOrientation:orientation duration:coordinator.transitionDuration];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self _didRotateFromInterfaceOrientation:orientation];
    }];
}

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
    
    // Get the resource bundle depending on the framework/dependency manager we're using
	NSBundle *resourceBundle = TO_CROP_VIEW_RESOURCE_BUNDLE_FOR_OBJECT(self);
    
    //Prepare the localized options
	NSString *cancelButtonTitle = NSLocalizedStringFromTableInBundle(@"Cancel", @"TOCropViewControllerLocalizable", resourceBundle, nil);
	NSString *originalButtonTitle = NSLocalizedStringFromTableInBundle(@"Original", @"TOCropViewControllerLocalizable", resourceBundle, nil);
	NSString *squareButtonTitle = NSLocalizedStringFromTableInBundle(@"Square", @"TOCropViewControllerLocalizable", resourceBundle, nil);
    
    //Prepare the list that will be fed to the alert view/controller
    
    // Ratio titles according to the order of enum TOCropViewControllerAspectRatioPreset
    NSArray<NSString *> *portraitRatioTitles = @[originalButtonTitle, squareButtonTitle, @"2:3", @"3:5", @"3:4", @"4:5", @"5:7", @"9:16"];
    NSArray<NSString *> *landscapeRatioTitles = @[originalButtonTitle, squareButtonTitle, @"3:2", @"5:3", @"4:3", @"5:4", @"7:5", @"16:9"];

    NSMutableArray *ratioValues = [NSMutableArray array];
    NSMutableArray *itemStrings = [NSMutableArray array];

    if (self.allowedAspectRatios == nil) {
        for (NSInteger i = 0; i < TOCropViewControllerAspectRatioPresetCustom; i++) {
            NSString *itemTitle = verticalCropBox ? portraitRatioTitles[i] : landscapeRatioTitles[i];
            [itemStrings addObject:itemTitle];
            [ratioValues addObject:@(i)];
        }
    }
    else {
        for (NSNumber *allowedRatio in self.allowedAspectRatios) {
            TOCropViewControllerAspectRatioPreset ratio = allowedRatio.integerValue;
            NSString *itemTitle = verticalCropBox ? portraitRatioTitles[ratio] : landscapeRatioTitles[ratio];
            [itemStrings addObject:itemTitle];
            [ratioValues addObject:allowedRatio];
        }
    }
    
    // If a custom aspect ratio is provided, and a custom name has been given to it, add it as a visible choice
    if (self.customAspectRatioName.length > 0 && !CGSizeEqualToSize(CGSizeZero, self.customAspectRatio)) {
        [itemStrings addObject:self.customAspectRatioName];
        [ratioValues addObject:@(TOCropViewControllerAspectRatioPresetCustom)];
    }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];

    //Add each item to the alert controller
    for (NSInteger i = 0; i < itemStrings.count; i++) {
        id handlerBlock = ^(UIAlertAction *action) {
            [self setAspectRatioPreset:[ratioValues[i] integerValue] animated:YES];
            self.aspectRatioLockEnabled = YES;
        };
        UIAlertAction *action = [UIAlertAction actionWithTitle:itemStrings[i] style:UIAlertActionStyleDefault handler:handlerBlock];
        [alertController addAction:action];
    }

    alertController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *presentationController = [alertController popoverPresentationController];
    presentationController.sourceView = self.toolbar;
    presentationController.sourceRect = self.toolbar.clampButtonFrame;
    [self presentViewController:alertController animated:YES completion:nil];
}

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
    
    // If the aspect ratio lock is not enabled, allow a swap
    // If the aspect ratio lock is on, allow a aspect ratio swap
    // only if the allowDimensionSwap option is specified.
    BOOL aspectRatioCanSwapDimensions = !self.aspectRatioLockEnabled ||
                                (self.aspectRatioLockEnabled && self.aspectRatioLockDimensionSwapEnabled);
    
    //If the image is a portrait shape, flip the aspect ratio to match
    if (self.cropView.cropBoxAspectRatioIsPortrait &&
        aspectRatioCanSwapDimensions)
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
                                            angle:0 toImageFrame:CGRectZero setup:setup completion:completion];
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
    [viewController presentViewController:self.parentViewController ? self.parentViewController : self
                                 animated:YES
                               completion:^
    {
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
        if (completion) { completion(); }
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

        if (strongSelf.prepareForTransitionHandler) {
            strongSelf.prepareForTransitionHandler();
        }
        
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
        
        if (!CGRectIsEmpty(transitioning.toFrame) || transitioning.toView) {
            strongSelf.cropView.croppingViewsHidden = YES;
        }
        else {
            strongSelf.cropView.simpleRenderMode = YES;
        }
        
        if (strongSelf.prepareForTransitionHandler) {
            strongSelf.prepareForTransitionHandler();
        }
    };
    
    self.transitionController.isDismissing = YES;
    return self.transitionController;
}

#pragma mark - Button Feedback -
- (void)cancelButtonTapped
{
    if (!self.showCancelConfirmationDialog) {
        [self dismissCropViewController];
        return;
    }

    // Get the resource bundle depending on the framework/dependency manager we're using
    NSBundle *resourceBundle = TO_CROP_VIEW_RESOURCE_BUNDLE_FOR_OBJECT(self);

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    alertController.popoverPresentationController.sourceView = self.toolbar.visibleCancelButton;

    NSString *yesButtonTitle = NSLocalizedStringFromTableInBundle(@"Delete Changes", @"TOCropViewControllerLocalizable", resourceBundle, nil);
    NSString *noButtonTitle = NSLocalizedStringFromTableInBundle(@"Cancel", @"TOCropViewControllerLocalizable", resourceBundle, nil);

    __weak typeof (self) weakSelf = self;
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:yesButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [weakSelf dismissCropViewController];
    }];
    [alertController addAction:yesAction];

    UIAlertAction *noAction = [UIAlertAction actionWithTitle:noButtonTitle style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:noAction];

    [weakSelf presentViewController:alertController animated:YES completion: nil];
}

- (void)dismissCropViewController
{
    bool isDelegateOrCallbackHandled = NO;

    // Check if the delegate method was implemented and call if so
    if ([self.delegate respondsToSelector:@selector(cropViewController:didFinishCancelled:)]) {
        [self.delegate cropViewController:self didFinishCancelled:YES];
        isDelegateOrCallbackHandled = YES;
    }

    // Check if the block version was implemented and call if so
    if (self.onDidFinishCancelled != nil) {
        self.onDidFinishCancelled(YES);
        isDelegateOrCallbackHandled = YES;
    }

    // If neither callbacks were implemented, perform a default dismissing animation
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
        if (self.activityItems) {
            [activityItems addObjectsFromArray:self.activityItems];
        }
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:self.applicationActivities];
        activityController.excludedActivityTypes = self.excludedActivityTypes;

        activityController.modalPresentationStyle = UIModalPresentationPopover;
        activityController.popoverPresentationController.sourceView = self.toolbar;
        activityController.popoverPresentationController.sourceRect = self.toolbar.doneButtonFrame;
        [self presentViewController:activityController animated:YES completion:nil];

        __weak typeof(activityController) blockController = activityController;

        activityController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            if (!completed) {
                return;
            }
            
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

    // Check if the circular APIs were implemented
    BOOL isCircularImageDelegateAvailable = [self.delegate respondsToSelector:@selector(cropViewController:didCropToCircularImage:withRect:angle:)];
    BOOL isCircularImageCallbackAvailable = self.onDidCropToCircleImage != nil;

    // Check if non-circular was implemented
    BOOL isDidCropToImageDelegateAvailable = [self.delegate respondsToSelector:@selector(cropViewController:didCropToImage:withRect:angle:)];
    BOOL isDidCropToImageCallbackAvailable = self.onDidCropToRect != nil;

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
    //If the delegate/block that requires the specific cropped image is provided, call it
    else if (isDidCropToImageDelegateAvailable || isDidCropToImageCallbackAvailable) {
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

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];

    if (self.title.length == 0) {
        [_titleLabel removeFromSuperview];
        _cropView.cropRegionInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        _titleLabel = nil;
        return;
    }

    self.titleLabel.text = self.title;
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = [self frameForTitleLabelWithSize:self.titleLabel.frame.size verticalLayout:self.verticalLayout];
}

- (void)setDoneButtonTitle:(NSString *)title {
    self.toolbar.doneTextButtonTitle = title;
}

- (void)setCancelButtonTitle:(NSString *)title {
    self.toolbar.cancelTextButtonTitle = title;
}

- (TOCropView *)cropView {
    // Lazily create the crop view in case we try and access it before presentation, but
    // don't add it until our parent view controller view has loaded at the right time
    if (!_cropView) {
        _cropView = [[TOCropView alloc] initWithCroppingStyle:self.croppingStyle image:self.image];
        _cropView.delegate = self;
        _cropView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_cropView];
    }
    return _cropView;
}

- (TOCropToolbar *)toolbar {
    if (!_toolbar) {
        _toolbar = [[TOCropToolbar alloc] initWithFrame:CGRectZero];
        [self.view addSubview:_toolbar];
    }
    return _toolbar;
}

- (UILabel *)titleLabel
{
    if (!self.title.length) { return nil; }
    if (_titleLabel) { return _titleLabel; }

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.numberOfLines = 1;
    _titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignBaselines;
    _titleLabel.clipsToBounds = YES;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.text = self.title;

    [self.view insertSubview:self.titleLabel aboveSubview:self.cropView];

    return _titleLabel;
}

- (void)setAspectRatioLockEnabled:(BOOL)aspectRatioLockEnabled
{
    self.toolbar.clampButtonGlowing = aspectRatioLockEnabled;
    self.cropView.aspectRatioLockEnabled = aspectRatioLockEnabled;
    if (!self.aspectRatioPickerButtonHidden) {
        self.aspectRatioPickerButtonHidden = (aspectRatioLockEnabled && self.resetAspectRatioEnabled == NO);
    }
}

- (void)setAspectRatioLockDimensionSwapEnabled:(BOOL)aspectRatioLockDimensionSwapEnabled
{
    self.cropView.aspectRatioLockDimensionSwapEnabled = aspectRatioLockDimensionSwapEnabled;
}

- (BOOL)aspectRatioLockEnabled
{
    return self.cropView.aspectRatioLockEnabled;
}

- (void)setRotateButtonsHidden:(BOOL)rotateButtonsHidden
{
    self.toolbar.rotateCounterclockwiseButtonHidden = rotateButtonsHidden;
    self.toolbar.rotateClockwiseButtonHidden = rotateButtonsHidden;
}

- (void)setResetButtonHidden:(BOOL)resetButtonHidden
{
    self.toolbar.resetButtonHidden = resetButtonHidden;
}

- (BOOL)rotateButtonsHidden
{
    return self.toolbar.rotateCounterclockwiseButtonHidden && self.toolbar.rotateClockwiseButtonHidden;
}

- (void)setRotateClockwiseButtonHidden:(BOOL)rotateClockwiseButtonHidden
{
    self.toolbar.rotateClockwiseButtonHidden = rotateClockwiseButtonHidden;
}

- (BOOL)rotateClockwiseButtonHidden {
    return self.toolbar.rotateClockwiseButtonHidden;
}

- (void)setAspectRatioPickerButtonHidden:(BOOL)aspectRatioPickerButtonHidden
{
    self.toolbar.clampButtonHidden = aspectRatioPickerButtonHidden;
}

- (BOOL)aspectRatioPickerButtonHidden
{
    return self.toolbar.clampButtonHidden;
}

- (void)setDoneButtonHidden:(BOOL)doneButtonHidden
{
    self.toolbar.doneButtonHidden = doneButtonHidden;
}

- (BOOL)doneButtonHidden
{
    return self.toolbar.doneButtonHidden;
}

- (void)setCancelButtonHidden:(BOOL)cancelButtonHidden
{
    self.toolbar.cancelButtonHidden = cancelButtonHidden;
}

- (BOOL)cancelButtonHidden
{
    return self.toolbar.cancelButtonHidden;
}

- (void)setResetAspectRatioEnabled:(BOOL)resetAspectRatioEnabled
{
    self.cropView.resetAspectRatioEnabled = resetAspectRatioEnabled;
    if (!self.aspectRatioPickerButtonHidden) {
        self.aspectRatioPickerButtonHidden = (resetAspectRatioEnabled == NO && self.aspectRatioLockEnabled);
    }
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

- (BOOL)verticalLayout
{
    return CGRectGetWidth(self.view.bounds) < CGRectGetHeight(self.view.bounds);
}

- (BOOL)overrideStatusBar
{
    // If we're pushed from a navigation controller, we'll defer
    // to its handling of the status bar
    if (self.navigationController) {
        return NO;
    }
    
    // If the view controller presenting us already hid it, we don't need to
    // do anything ourselves
    if (self.presentingViewController.prefersStatusBarHidden) {
        return NO;
    }
    
    // We'll handle the status bar
    return YES;
}

- (BOOL)statusBarHidden
{
    // Defer behaviour to the hosting navigation controller
    if (self.navigationController) {
        return self.navigationController.prefersStatusBarHidden;
    }
    
    //If our presenting controller has already hidden the status bar,
    //hide the status bar by default
    if (self.presentingViewController.prefersStatusBarHidden) {
        return YES;
    }
    
    // Our default behaviour is to always hide the status bar
    return YES;
}

- (CGFloat)statusBarHeight
{
    CGFloat statusBarHeight = 0.0f;
    if (@available(iOS 11.0, *)) {
        statusBarHeight = self.view.safeAreaInsets.top;

        // On non-Face ID devices, always disregard the top inset
        // unless we explicitly set the status bar to be visible.
        if (self.statusBarHidden &&
            self.view.safeAreaInsets.bottom <= FLT_EPSILON)
        {
            statusBarHeight = 0.0f;
        }
    }
    else {
        if (self.statusBarHidden) {
            statusBarHeight = 0.0f;
        }
        else {
            statusBarHeight = self.topLayoutGuide.length;
        }
    }
    
    return statusBarHeight;
}

- (UIEdgeInsets)statusBarSafeInsets
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        insets = self.view.safeAreaInsets;
        insets.top = self.statusBarHeight;
    }
    else {
        insets.top = self.statusBarHeight;
    }

    return insets;
}

- (void)setMinimumAspectRatio:(CGFloat)minimumAspectRatio
{
    self.cropView.minimumAspectRatio = minimumAspectRatio;
}

- (CGFloat)minimumAspectRatio
{
    return self.cropView.minimumAspectRatio;
}

@end
