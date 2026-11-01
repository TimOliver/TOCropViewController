//
//  TOCropViewControllerTests.m
//  TOCropViewControllerTests
//
//  Created by Tim Oliver on 14/06/2015.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "TOCropScrollView.h"
#import "TOCropViewController.h"
#import "UIImage+CropRotate.h"

// Expose private state so tests can arm the reset timer, simulate an in-flight
// rotation, drive the scroll view's touch hooks, and stand in for a touch landing
// on the crop box
@interface TOCropView (UnitTests) <UIGestureRecognizerDelegate>
- (void)startResetTimer;
@property (nonatomic, assign) BOOL rotateAnimationInProgress;
@property (nonatomic, strong, readonly) TOCropScrollView *scrollView;
@property (nonatomic, strong, readonly) NSTimer *resetTimer;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *gridPanGestureRecognizer;
@property (nonatomic, assign) CGPoint gridPanInitialPoint;
@property (nonatomic, readonly) CGRect cropBoxFrame;
@end

// Expose the controller's layout decisions so tests can drive them with display sizes
@interface TOCropViewController (UnitTests)
@property (nonatomic, readonly) BOOL toolbarOnRightEdge;
@property (nonatomic, readonly) BOOL verticalLayout;
@end

// UIScrollView won't report itself as dragging without a real touch sequence, so
// stand in for one while a block runs
@interface UIScrollView (TOCropTestDragging)
- (BOOL)to_test_alwaysDragging;
@end

@implementation UIScrollView (TOCropTestDragging)
- (BOOL)to_test_alwaysDragging {
    return YES;
}
@end

static void TOCropRunWhileScrollViewIsDragging(void (^block)(void)) {
    Method real = class_getInstanceMethod([UIScrollView class], @selector(isDragging));
    Method stub = class_getInstanceMethod([UIScrollView class], @selector(to_test_alwaysDragging));
    method_exchangeImplementations(real, stub);
    block();
    method_exchangeImplementations(real, stub);
}

// Likewise, a gesture recognizer only reports an active state mid-touch, so stand
// in for the crop box pan having claimed the touch while a block runs
@interface UIGestureRecognizer (TOCropTestActivePan)
- (UIGestureRecognizerState)to_test_alwaysChangedState;
@end

@implementation UIGestureRecognizer (TOCropTestActivePan)
- (UIGestureRecognizerState)to_test_alwaysChangedState {
    return UIGestureRecognizerStateChanged;
}
@end

static void TOCropRunWhileCropBoxPanIsActive(void (^block)(void)) {
    Method real = class_getInstanceMethod([UIGestureRecognizer class], @selector(state));
    Method stub = class_getInstanceMethod([UIGestureRecognizer class], @selector(to_test_alwaysChangedState));
    method_exchangeImplementations(real, stub);
    block();
    method_exchangeImplementations(real, stub);
}

// A view only reports safe area insets once it's in a window, so stand in for the
// home indicator inset of an edge-to-edge layout while a block runs
@interface UIView (TOCropTestSafeArea)
- (UIEdgeInsets)to_test_homeIndicatorSafeAreaInsets;
@end

@implementation UIView (TOCropTestSafeArea)
- (UIEdgeInsets)to_test_homeIndicatorSafeAreaInsets {
    return (UIEdgeInsets){0, 0, 34, 0};
}
@end

static void TOCropRunWhileViewHasBottomSafeArea(void (^block)(void)) {
    Method real = class_getInstanceMethod([UIView class], @selector(safeAreaInsets));
    Method stub = class_getInstanceMethod([UIView class], @selector(to_test_homeIndicatorSafeAreaInsets));
    method_exchangeImplementations(real, stub);
    block();
    method_exchangeImplementations(real, stub);
}

@interface TOCropViewControllerTests : XCTestCase

@end

@implementation TOCropViewControllerTests

#pragma mark - Helpers -

- (UIImage *)testImageWithSize:(CGSize)size {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull context) {
        [[UIColor redColor] setFill];
        [context fillRect:(CGRect){CGPointZero, size}];
    }];
}

// Camera photos are 8-bit Display P3, so stand one in, filled with a red outside sRGB's gamut
- (UIImage *)displayP3PhotoWithSize:(CGSize)size {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    CGContextRef context = CGBitmapContextCreate(NULL, (size_t)size.width, (size_t)size.height, 8, 0, colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipLast);
    const CGFloat red[] = {1.0f, 0.0f, 0.0f, 1.0f};
    CGColorRef color = CGColorCreate(colorSpace, red);
    CGContextSetFillColorWithColor(context, color);
    CGContextFillRect(context, (CGRect){CGPointZero, size});
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGColorRelease(color);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return image;
}

// A different colour in each quarter, so a crop landing in the wrong place shows up
- (UIImage *)quarteredImageWithSize:(CGSize)size scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat new];
    format.scale = scale;
    format.preferredRange = UIGraphicsImageRendererFormatRangeStandard;
    UIImage *image = [[[UIGraphicsImageRenderer alloc] initWithSize:size format:format] imageWithActions:^(UIGraphicsImageRendererContext *context) {
        CGFloat halfWidth = size.width * 0.5f;
        CGFloat halfHeight = size.height * 0.5f;
        [UIColor.redColor setFill];
        [context fillRect:(CGRect){0, 0, halfWidth, halfHeight}];
        [UIColor.greenColor setFill];
        [context fillRect:(CGRect){halfWidth, 0, halfWidth, halfHeight}];
        [UIColor.blueColor setFill];
        [context fillRect:(CGRect){0, halfHeight, halfWidth, halfHeight}];
        [UIColor.whiteColor setFill];
        [context fillRect:(CGRect){halfWidth, halfHeight, halfWidth, halfHeight}];
    }];
    return [UIImage imageWithCGImage:image.CGImage scale:scale orientation:orientation];
}

// The colour of one of an image's pixels as it's displayed (ie, with its orientation applied)
- (NSArray<NSNumber *> *)rgbaOfPixel:(CGPoint)pixel inImage:(UIImage *)image {
    uint8_t rgba[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef context = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextTranslateCTM(context, 0, 1);
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, -pixel.x, -pixel.y);
    UIGraphicsPushContext(context);
    [image drawInRect:(CGRect){CGPointZero, {image.size.width * image.scale, image.size.height * image.scale}}];
    UIGraphicsPopContext();
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return @[ @(rgba[0]), @(rgba[1]), @(rgba[2]), @(rgba[3]) ];
}

- (TOCropView *)cropViewWithImageSize:(CGSize)imageSize {
    TOCropView *cropView = [[TOCropView alloc] initWithImage:[self testImageWithSize:imageSize]];
    cropView.frame = (CGRect){0, 0, 320, 480};
    [cropView performInitialSetup];
    return cropView;
}

// Lays a crop view out the way the controller does on its first layout pass, with
// insets for a status bar above and a bottom toolbar below
- (TOCropView *)cropViewLaidOutLikeTheControllerWithImage:(UIImage *)image frame:(CGRect)frame {
    return [self cropViewLaidOutLikeTheControllerWithImage:image frame:frame configuration:nil];
}

// Hosts configure the crop view before it's presented, so apply any configuration
// before the first layout pass
- (TOCropView *)cropViewLaidOutLikeTheControllerWithImage:(UIImage *)image
                                                    frame:(CGRect)frame
                                            configuration:(void (^)(TOCropView *cropView))configuration {
    TOCropView *cropView = [[TOCropView alloc] initWithImage:image];
    cropView.frame = frame;
    cropView.cropRegionInsets = (UIEdgeInsets){59, 0, 94, 0};
    if (configuration) {
        configuration(cropView);
    }
    [cropView moveCroppedContentToCenterAnimated:NO];
    [cropView performInitialSetup];
    [cropView moveCroppedContentToCenterAnimated:NO];
    return cropView;
}

- (TOCropView *)cropViewWithImageSize:(CGSize)imageSize
                          lockedRatio:(CGSize)ratio
                 dimensionSwapEnabled:(BOOL)dimensionSwapEnabled
                            viewWidth:(CGFloat)viewWidth {
    return [self cropViewLaidOutLikeTheControllerWithImage:[self testImageWithSize:imageSize]
                                                     frame:(CGRect){0, 0, viewWidth, 874}
                                             configuration:^(TOCropView *cropView) {
                                                 cropView.aspectRatioLockEnabled = YES;
                                                 cropView.aspectRatioLockDimensionSwapEnabled = dimensionSwapEnabled;
                                                 cropView.aspectRatio = ratio;
                                             }];
}

- (void)rotateCropView:(TOCropView *)cropView times:(NSInteger)times {
    for (NSInteger i = 0; i < times; i++) {
        [cropView rotateImageNinetyDegreesAnimated:NO clockwise:NO completion:nil];
    }
}

static CGFloat TOCropAspectRatioOfRect(CGRect rect) {
    return rect.size.width / rect.size.height;
}

// How many pixels a crop's shorter side is from what the aspect ratio says it should be,
// which should never be more than rounding it to a whole pixel
static CGFloat TOCropPixelsOffAspectRatio(CGRect rect, CGSize ratio) {
    CGFloat ratioValue = ratio.width / ratio.height;
    if (ratioValue >= 1.0f) {
        return fabs(rect.size.height - (rect.size.width / ratioValue));
    }
    return fabs(rect.size.width - (rect.size.height * ratioValue));
}

// Sweeps phone-sized views for each image size and ratio, reporting the first crop that's
// more than a pixel off its ratio
- (void)assertExactRatioCropsForRatios:(NSArray<NSValue *> *)ratios
                             imageSizes:(NSArray<NSValue *> *)imageSizes
                         cropViewMaker:(TOCropView * (^)(UIImage *image, CGSize ratio, CGRect frame))makeCropView {
    NSInteger failures = 0;
    NSString *firstFailure = nil;
    for (NSValue *imageSizeValue in imageSizes) {
        UIImage *image = [self testImageWithSize:imageSizeValue.CGSizeValue];
        for (NSValue *ratioValue in ratios) {
            CGSize ratio = ratioValue.CGSizeValue;
            for (CGFloat width = 300.0f; width <= 460.0f; width += 2.0f) {
                CGRect frame = (CGRect){0, 0, width, 874};
                CGRect cropFrame = makeCropView(image, ratio, frame).imageCropFrame;
                if (TOCropPixelsOffAspectRatio(cropFrame, ratio) > 1.0f) {
                    failures++;
                    if (firstFailure == nil) {
                        firstFailure = [NSString stringWithFormat:@"%@ for %@ on a %@ image in a %@ view",
                                        NSStringFromCGSize(cropFrame.size), NSStringFromCGSize(ratio),
                                        NSStringFromCGSize(image.size), NSStringFromCGSize(frame.size)];
                    }
                }
            }
        }
    }
    XCTAssertEqual(failures, 0, @"Got %@ (and %ld others)", firstFailure, (long)MAX(0, failures - 1));
}

// The rounding that loses pixels only shows up at some view sizes, so check a
// spread of phone-sized views and report the first one that goes wrong
- (void)assertCropFrameAcrossViewWidthsForImageSize:(CGSize)imageSize
                                      afterAdjusting:(void (^)(TOCropView *cropView))adjust
                                        expectFrame:(CGRect)expectedFrame {
    UIImage *image = [self testImageWithSize:imageSize];
    NSInteger failures = 0;
    NSString *firstFailure = nil;
    for (CGFloat width = 300.0f; width <= 460.0f; width += 1.0f) {
        CGRect viewFrame = (CGRect){0, 0, width, 880};
        TOCropView *cropView = [self cropViewLaidOutLikeTheControllerWithImage:image frame:viewFrame];
        if (adjust) {
            adjust(cropView);
        }
        if (!CGRectEqualToRect(cropView.imageCropFrame, expectedFrame)) {
            failures++;
            if (firstFailure == nil) {
                firstFailure = [NSString stringWithFormat:@"%@ in a %@ view", NSStringFromCGRect(cropView.imageCropFrame), NSStringFromCGSize(viewFrame.size)];
            }
        }
    }
    XCTAssertEqual(failures, 0, @"Expected %@ but got %@ (and %ld other view sizes)",
                   NSStringFromCGRect(expectedFrame), firstFailure, (long)MAX(0, failures - 1));
}

// The custom transition only runs for animated presentations from a view controller
// that's on screen, so give each presentation test a window of its own
- (UIWindow *)presentationTestWindow {
    UIWindowScene *scene = nil;
    for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
        if ([candidate isKindOfClass:[UIWindowScene class]]) {
            scene = (UIWindowScene *)candidate;
            break;
        }
    }

    UIWindow *window = [[UIWindow alloc] initWithWindowScene:scene];
    window.rootViewController = [[UIViewController alloc] init];
    [window makeKeyAndVisible];
    [self addTeardownBlock:^{
        window.hidden = YES;
    }];
    return window;
}

- (void)presentViewController:(UIViewController *)viewController
           fromViewController:(UIViewController *)presentingViewController
                     animated:(BOOL)animated {
    XCTestExpectation *presented = [self expectationWithDescription:@"Presented"];
    [presentingViewController presentViewController:viewController animated:animated completion:^{
        [presented fulfill];
    }];
    [self waitForExpectations:@[presented] timeout:5.0];
}

// Hosts can embed the controller as a child, eg above their own toolbar, in which case it
// doesn't control the status bar and has to stay inside the frame it was given
- (TOCropViewController *)cropControllerEmbeddedInWindow:(UIWindow *)window
                                                   frame:(CGRect)frame
                                           configuration:(void (^)(TOCropViewController *cropController))configuration {
    UIViewController *parentController = window.rootViewController;
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){400, 300}]];
    if (configuration) {
        configuration(cropController);
    }
    [parentController addChildViewController:cropController];
    cropController.view.frame = frame;
    [parentController.view addSubview:cropController.view];
    [cropController didMoveToParentViewController:parentController];
    [parentController.view layoutIfNeeded];
    [cropController.view layoutIfNeeded];
    return cropController;
}

- (void)dismissViewController:(UIViewController *)viewController {
    XCTestExpectation *dismissed = [self expectationWithDescription:@"Dismissed"];
    [viewController dismissViewControllerAnimated:YES completion:^{
        [dismissed fulfill];
    }];
    [self waitForExpectations:@[dismissed] timeout:5.0];
}

#pragma mark - Tests -

- (void)testGridOverlayHiddenSetter {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    cropView.gridOverlayHidden = YES;
    XCTAssertTrue(cropView.gridOverlayHidden);
    cropView.gridOverlayHidden = NO;
    XCTAssertFalse(cropView.gridOverlayHidden);
}

- (void)testSetAngleAllowsDirectionChanges {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    cropView.angle = 90;
    XCTAssertEqual(cropView.angle, 90);
    cropView.angle = -90;
    XCTAssertEqual(cropView.angle, -90);
}

- (void)testSetAngleNormalizesFullRotations {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    cropView.angle = 360;
    XCTAssertEqual(cropView.angle, 0);
    cropView.angle = 450;
    XCTAssertEqual(cropView.angle, 90);
    cropView.angle = -450;
    XCTAssertEqual(cropView.angle, -90);
}

- (void)testNinetyDegreeRotationRoundTrip {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    for (NSInteger i = 0; i < 4; i++) {
        [cropView rotateImageNinetyDegreesAnimated:NO clockwise:YES completion:nil];
    }
    XCTAssertEqual(cropView.angle, 0);

    // A full revolution should land back on the whole image
    CGRect cropFrame = cropView.imageCropFrame;
    XCTAssertEqualWithAccuracy(cropFrame.size.width, 40.0, 2.0);
    XCTAssertEqualWithAccuracy(cropFrame.size.height, 20.0, 2.0);
}

- (void)testSetAngleBailsOutDuringAnimatedRotation {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    cropView.rotateAnimationInProgress = YES;
    cropView.angle = 90;  // spun forever before the no-progress guard
    XCTAssertEqual(cropView.angle, 0);
    cropView.rotateAnimationInProgress = NO;
}

- (void)testZeroSizeImageDoesNotCrash {
    TOCropView *cropView = [[TOCropView alloc] initWithImage:[UIImage new]];
    cropView.frame = (CGRect){0, 0, 320, 480};
    XCTAssertNoThrow([cropView performInitialSetup]);
    XCTAssertNoThrow([cropView layoutIfNeeded]);
}

- (void)testDegenerateAspectRatioIsIgnored {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    CGRect before = cropView.imageCropFrame;
    [cropView setAspectRatio:(CGSize){0.0f, 5.0f} animated:NO];
    CGRect after = cropView.imageCropFrame;
    XCTAssertEqualWithAccuracy(before.origin.x, after.origin.x, 1.0);
    XCTAssertEqualWithAccuracy(before.size.width, after.size.width, 1.0);
}

- (void)testImageCropFrameStaysWithinImageBounds {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){403, 301}];
    for (NSInteger x = 150; x <= 203; x += 13) {
        [cropView setImageCropFrame:(CGRect){x, 51, 403 - x, 250}];
        CGRect frame = cropView.imageCropFrame;
        XCTAssertLessThanOrEqual(CGRectGetMaxX(frame), 403.0);
        XCTAssertLessThanOrEqual(CGRectGetMaxY(frame), 301.0);
    }
}

- (void)testResetTimerIsNotArmedWhenAPanCancelsTheTouch {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];

    cropView.scrollView.touchesBegan();
    XCTAssertNil(cropView.resetTimer, @"editing should have cancelled any pending reset");

    // UIScrollView cancels the touches it delivered as a normal part of its pan
    // recogniser taking over, so this fires mid-gesture with the finger still down
    TOCropRunWhileScrollViewIsDragging(^{
        cropView.scrollView.touchesCancelled();
    });
    XCTAssertNil(cropView.resetTimer, @"a pan taking over the touch must not arm the reset timer");
}

- (void)testRestingCropBoxCentersWhenFullyZoomedOut {
    // Mimic the squat display side toolbar layout: a trailing inset for the toolbar,
    // and a bottom inset that is purely the home indicator's safe area
    TOCropView *(^makeCropView)(CGSize) = ^(CGSize imageSize) {
        TOCropView *cropView = [[TOCropView alloc] initWithImage:[self testImageWithSize:imageSize]];
        cropView.frame = (CGRect){0, 0, 466, 678};
        cropView.cropRegionInsets = (UIEdgeInsets){0, 0, 34, 70};
        [cropView performInitialSetup];
        return cropView;
    };

    TOCropRunWhileViewHasBottomSafeArea(^{
        // Fully zoomed out, the crop box rests perfectly vertically centered
        TOCropView *cropView = makeCropView((CGSize){40, 20});
        XCTAssertEqualWithAccuracy(CGRectGetMidY(cropView.cropBoxFrame), 678.0 / 2.0, 1.5,
                                   @"a fully zoomed out crop box must be vertically centered");

        // Zooming into a subregion of the image offsets it clear of the safe area
        [cropView setImageCropFrame:(CGRect){10, 5, 20, 10}];
        XCTAssertEqualWithAccuracy(CGRectGetMidY(cropView.cropBoxFrame), 322.0, 1.5,
                                   @"a zoomed in crop box must offset clear of the bottom inset");
    });

    // When the bottom inset is more than the safe area (eg, the bottom toolbar
    // layout), the box keeps centering within the inset region as always
    TOCropView *toolbarCropView = makeCropView((CGSize){40, 20});
    XCTAssertEqualWithAccuracy(CGRectGetMidY(toolbarCropView.cropBoxFrame), 322.0, 1.5,
                               @"an accessory view's bottom inset must keep offsetting the crop box");
}

- (void)testRestingCropBoxFillingTheHeightKeepsTheWholeImage {
    // An image tall enough to fill the content height has no room to shift down into the
    // safe area, so it must keep its regular layout rather than being clipped at the bottom
    void (^checkLayout)(CGSize, CGRect, UIEdgeInsets, NSString *) = ^(CGSize imageSize, CGRect frame, UIEdgeInsets insets, NSString *label) {
        TOCropView *cropView = [[TOCropView alloc] initWithImage:[self testImageWithSize:imageSize]];
        cropView.frame = frame;
        cropView.cropRegionInsets = insets;
        [cropView performInitialSetup];

        XCTAssertEqualWithAccuracy(cropView.imageCropFrame.size.height, imageSize.height, imageSize.height * 0.01,
                                   @"%@: an untouched crop must cover the whole image", label);
        XCTAssertFalse(cropView.canBeReset, @"%@: an untouched crop must not be resettable", label);

        // A layout pass re-centers the crop box every time, which must leave it be
        [cropView moveCroppedContentToCenterAnimated:NO];
        XCTAssertEqualWithAccuracy(cropView.imageCropFrame.size.height, imageSize.height, imageSize.height * 0.01,
                                   @"%@: re-centering must not clip the image", label);
        XCTAssertFalse(cropView.canBeReset, @"%@: re-centering must not make the crop resettable", label);

        // And resetting must land back on the same untouched state
        [cropView resetLayoutToDefaultAnimated:NO];
        XCTAssertFalse(cropView.canBeReset, @"%@: resetting must clear the resettable state", label);
    };

    TOCropRunWhileViewHasBottomSafeArea(^{
        // A tall image alongside the squat display side toolbar
        checkLayout((CGSize){1080, 1920}, (CGRect){0, 0, 466, 678}, (UIEdgeInsets){0, 0, 34, 70}, @"squat portrait");
        // A photo on a regular phone in landscape, beside the leading edge toolbar
        checkLayout((CGSize){4032, 3024}, (CGRect){0, 0, 874, 402}, (UIEdgeInsets){0, 70, 21, 62}, @"phone landscape");
    });
}

- (void)testSideToolbarHugsTheTrailingEdgeOnSquatDisplays {
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];

    // A folding phone's cover display earns the trailing edge toolbar in both orientations
    controller.view.frame = (CGRect){0, 0, 466, 678};
    XCTAssertTrue(controller.toolbarOnRightEdge, @"a squat portrait display must use the trailing edge toolbar");
    controller.view.frame = (CGRect){0, 0, 678, 466};
    XCTAssertTrue(controller.toolbarOnRightEdge, @"a squat landscape display must use the trailing edge toolbar");

    // While regular phones keep the strip on the leading edge in landscape
    controller.view.frame = (CGRect){0, 0, 874, 402};
    XCTAssertFalse(controller.toolbarOnRightEdge, @"a regular landscape phone keeps the leading edge toolbar");
}

- (void)testRegularWidthPortraitReturnsToTheBottomToolbar {
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];

    // The unfolded inner display in portrait has iPad-like room (regular width),
    // so the toolbar returns to the bottom like the iPad layout
    controller.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassRegular;
    controller.view.frame = (CGRect){0, 0, 669, 951};
    XCTAssertTrue(controller.verticalLayout, @"a regular width squat portrait layout must use the bottom toolbar");

    // While its landscape orientation keeps the trailing edge strip
    controller.view.frame = (CGRect){0, 0, 951, 669};
    XCTAssertFalse(controller.verticalLayout, @"landscape must keep the side toolbar");
    XCTAssertTrue(controller.toolbarOnRightEdge, @"a squat landscape display must keep the trailing edge toolbar");

    // And the compact cover display keeps the side toolbar even in portrait
    controller.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassCompact;
    controller.view.frame = (CGRect){0, 0, 466, 678};
    XCTAssertFalse(controller.verticalLayout, @"a compact squat portrait display must keep the side toolbar");
}

- (void)testUncroppedCropBoxSurvivesRotationRoundTrips {
    // A large image, so any screen-space rounding drift shows up in image space
    TOCropView *cropView = [[TOCropView alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];
    cropView.frame = (CGRect){0, 0, 320, 480};
    [cropView performInitialSetup];
    CGRect before = cropView.imageCropFrame;

    // Mimic the controller's device rotation dance through two full round trips
    for (NSInteger i = 0; i < 4; i++) {
        [cropView prepareforRotation];
        cropView.frame = (i % 2 == 0) ? (CGRect){0, 0, 480, 320} : (CGRect){0, 0, 320, 480};
        [cropView performRelayoutForRotation];
        [cropView moveCroppedContentToCenterAnimated:NO];
    }

    // An untouched crop must come back bit for bit, not slightly shrunken
    CGRect after = cropView.imageCropFrame;
    XCTAssertEqualWithAccuracy(after.origin.x, before.origin.x, 1.0, @"the crop must not drift sideways across rotations");
    XCTAssertEqualWithAccuracy(after.origin.y, before.origin.y, 1.0, @"the crop must not drift downwards across rotations");
    XCTAssertEqualWithAccuracy(after.size.width, before.size.width, 1.0, @"the crop must not narrow across rotations");
    XCTAssertEqualWithAccuracy(after.size.height, before.size.height, 1.0, @"the crop must not shrink across rotations");
}

- (void)testCropBoxPanJudgesTheTouchDownPointNotTheDriftedOne {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    CGRect gridFrame = cropView.gridOverlayView.frame;

    // A pan only recognises after the finger has already travelled, so the begin
    // check must judge where the touch first landed, not where the finger is now.
    // Landing on the box's bottom line grabs it, wherever the finger has moved to
    cropView.gridPanInitialPoint = (CGPoint){CGRectGetMidX(gridFrame), CGRectGetMaxY(gridFrame)};
    XCTAssertTrue([cropView gestureRecognizerShouldBegin:cropView.gridPanGestureRecognizer],
                  @"a touch on the grid line must begin the crop box resize");

    // The 44pt grab band is centered on the line: 22pt inside or outside still grabs
    cropView.gridPanInitialPoint = (CGPoint){CGRectGetMidX(gridFrame), CGRectGetMaxY(gridFrame) - 21.0f};
    XCTAssertTrue([cropView gestureRecognizerShouldBegin:cropView.gridPanGestureRecognizer],
                  @"a touch just inside the grid line must begin the crop box resize");
    cropView.gridPanInitialPoint = (CGPoint){CGRectGetMidX(gridFrame), CGRectGetMaxY(gridFrame) + 21.0f};
    XCTAssertTrue([cropView gestureRecognizerShouldBegin:cropView.gridPanGestureRecognizer],
                  @"a touch just outside the grid line must begin the crop box resize");

    // While a touch in the box's middle pans the image instead
    cropView.gridPanInitialPoint = (CGPoint){CGRectGetMidX(gridFrame), CGRectGetMidY(gridFrame)};
    XCTAssertFalse([cropView gestureRecognizerShouldBegin:cropView.gridPanGestureRecognizer],
                   @"a touch in the middle of the crop box must not resize it");
}

- (void)testResetTimerIsNotArmedWhenTheCropBoxPanCancelsTheTouch {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];

    cropView.scrollView.touchesBegan();
    XCTAssertNil(cropView.resetTimer, @"editing should have cancelled any pending reset");

    // When the crop box resizing pan recognises, it cancels the touches the scroll
    // view was receiving, with the user's finger still down on the crop box handle
    TOCropRunWhileCropBoxPanIsActive(^{
        cropView.scrollView.touchesCancelled();
    });
    XCTAssertNil(cropView.resetTimer, @"the crop box pan taking over must not arm the reset timer");
}

- (void)testResetTimerIsArmedWhenAnIdleTouchIsInterrupted {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];

    // Nothing is scrolling, so this is a real interruption (incoming call, system
    // alert) and the view would otherwise stay stuck in its editing appearance
    cropView.scrollView.touchesBegan();
    cropView.scrollView.touchesCancelled();
    XCTAssertNotNil(cropView.resetTimer, @"an interrupted idle touch must arm the reset timer");
}

- (void)testCroppedImageWithFrame {
    UIImage *image = [self testImageWithSize:(CGSize){40, 20}];

    UIImage *cropped = [image croppedImageWithFrame:(CGRect){10, 5, 20, 10} angle:0 circularClip:NO];
    XCTAssertEqualWithAccuracy(cropped.size.width, 20.0, FLT_EPSILON);
    XCTAssertEqualWithAccuracy(cropped.size.height, 10.0, FLT_EPSILON);
    XCTAssertEqual(cropped.imageOrientation, UIImageOrientationUp);

    // A 90-degree rotation swaps the axes the crop frame is expressed in
    UIImage *rotated = [image croppedImageWithFrame:(CGRect){0, 0, 20, 40} angle:90 circularClip:NO];
    XCTAssertEqualWithAccuracy(rotated.size.width, 20.0, FLT_EPSILON);
    XCTAssertEqualWithAccuracy(rotated.size.height, 40.0, FLT_EPSILON);
}

- (void)testCropViewIsReleasedWithPendingResetTimer {
    __weak TOCropView *weakCropView = nil;
    @autoreleasepool {
        TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
        [cropView startResetTimer];
        weakCropView = cropView;
    }
    XCTAssertNil(weakCropView);
}

- (void)testControllerPropertiesReadBack {
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];
    controller.doneButtonTitle = @"Save";
    XCTAssertEqualObjects(controller.doneButtonTitle, @"Save");
    controller.cancelButtonTitle = @"Back";
    XCTAssertEqualObjects(controller.cancelButtonTitle, @"Back");
    controller.showOnlyIcons = YES;
    XCTAssertTrue(controller.showOnlyIcons);
    controller.doneButtonColor = UIColor.systemPinkColor;
    XCTAssertEqualObjects(controller.doneButtonColor, UIColor.systemPinkColor);
    controller.cancelButtonColor = UIColor.systemTealColor;
    XCTAssertEqualObjects(controller.cancelButtonColor, UIColor.systemTealColor);
    controller.resetButtonHidden = YES;
    XCTAssertTrue(controller.resetButtonHidden);
}

- (void)testAspectRatioPresetEqualityAndHashing {
    TOCropViewControllerAspectRatioPreset *first = [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:(CGSize){16, 9} title:@"16:9"];
    TOCropViewControllerAspectRatioPreset *second = [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:(CGSize){16, 9} title:@"16:9"];
    XCTAssertEqualObjects(first, second);
    XCTAssertEqual(first.hash, second.hash);
    NSSet *presets = [NSSet setWithArray:@[first, second]];
    XCTAssertEqual(presets.count, 1u);
}

- (void)testViewControllerInstance {
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){10, 10}]];
    UIView *view = controller.view;
    XCTAssertNotNil(view);
}

- (void)testRotationCompletionFiresWhenNotAnimated {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    __block NSInteger callCount = 0;
    __block BOOL reportedCompleted = NO;
    [cropView rotateImageNinetyDegreesAnimated:NO
                                     clockwise:YES
                                    completion:^(BOOL completed) {
                                        callCount++;
                                        reportedCompleted = completed;
                                    }];
    XCTAssertEqual(cropView.angle, 90);
    XCTAssertEqual(callCount, 1);
    XCTAssertTrue(reportedCompleted);
}

- (void)testRotationCompletionFiresWhenRotationIsRejected {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
    cropView.rotateAnimationInProgress = YES;

    __block NSInteger callCount = 0;
    __block BOOL reportedCompleted = YES;
    [cropView rotateImageNinetyDegreesAnimated:YES
                                     clockwise:YES
                                    completion:^(BOOL completed) {
                                        callCount++;
                                        reportedCompleted = completed;
                                    }];
    cropView.rotateAnimationInProgress = NO;

    // The rotation was dropped, but the handler must still run so callers gating
    // UI on it (such as the toolbar's rotation buttons) don't stay disabled
    XCTAssertEqual(cropView.angle, 0);
    XCTAssertEqual(callCount, 1);
    XCTAssertFalse(reportedCompleted);
}

- (void)testCircularCropViewHasNoGridOverlay {
    TOCropView *cropView = [[TOCropView alloc] initWithCroppingStyle:TOCropViewCroppingStyleCircular
                                                               image:[self testImageWithSize:(CGSize){40, 20}]];
    cropView.frame = (CGRect){0, 0, 320, 480};
    XCTAssertNoThrow([cropView performInitialSetup]);

    // Circular cropping has no rectangular grid, so the property is nullable
    XCTAssertNil(cropView.gridOverlayView);
    XCTAssertNoThrow([cropView setGridOverlayHidden:NO animated:NO]);
}

- (void)testHidingRotationButtonsRelaysOutTheToolbar {
    // Buttons flow in the order [counterclockwise, reset, clamp, clockwise], so hiding
    // the counterclockwise button must slide the reset button into the leading slot.
    // If the property invalidates layout, an implicit and a forced layout agree.
    TOCropToolbar *toolbar = [[TOCropToolbar alloc] initWithFrame:(CGRect){0, 0, 375, 44}];
    [toolbar layoutIfNeeded];

    toolbar.rotateCounterclockwiseButtonHidden = YES;
    [toolbar layoutIfNeeded];
    CGRect implicitFrame = toolbar.resetButton.frame;

    [toolbar setNeedsLayout];
    [toolbar layoutIfNeeded];
    XCTAssertTrue(CGRectEqualToRect(implicitFrame, toolbar.resetButton.frame));

    // And the same for its clockwise counterpart
    TOCropToolbar *other = [[TOCropToolbar alloc] initWithFrame:(CGRect){0, 0, 375, 44}];
    [other layoutIfNeeded];

    other.rotateClockwiseButtonHidden = YES;
    [other layoutIfNeeded];
    CGRect otherImplicitFrame = other.clampButton.frame;

    [other setNeedsLayout];
    [other layoutIfNeeded];
    XCTAssertTrue(CGRectEqualToRect(otherImplicitFrame, other.clampButton.frame));
}

- (void)testDoneAndCancelButtonsRemainReachable {
    TOCropToolbar *toolbar = [[TOCropToolbar alloc] initWithFrame:(CGRect){0, 0, 375, 44}];

    // On iOS 26 the text buttons are never built, so turning this off must not be
    // honoured, or the toolbar would be left with no way to commit or cancel
    toolbar.showOnlyIcons = NO;
    [toolbar layoutIfNeeded];

    XCTAssertTrue(toolbar.doneTextButton != nil || toolbar.doneIconButton.hidden == NO);
    XCTAssertTrue(toolbar.cancelTextButton != nil || toolbar.cancelIconButton.hidden == NO);
    XCTAssertNotNil(toolbar.visibleCancelButton);
    XCTAssertFalse(CGRectIsEmpty(toolbar.doneButtonFrame));
}

- (void)testToolButtonsSitCentredBetweenCancelAndDone {
    // Whichever design the toolbar was built with, its layout must agree with it. Laying
    // out for a glass container that was never built pins the tools to the leading edge.
    TOCropToolbar *toolbar = [[TOCropToolbar alloc] initWithFrame:(CGRect){0, 0, 375, 44}];
    [toolbar layoutIfNeeded];

    CGRect cancelFrame = toolbar.visibleCancelButton.frame;
    CGRect doneFrame = toolbar.doneButtonFrame;

    // The tool buttons may live inside the glass container, so compare in toolbar space
    UIButton *firstTool = toolbar.rotateCounterclockwiseButton;
    UIButton *lastTool = toolbar.rotateClockwiseButton;
    CGRect toolsFrame = CGRectUnion([toolbar convertRect:firstTool.bounds fromView:firstTool],
                                    [toolbar convertRect:lastTool.bounds fromView:lastTool]);

    XCTAssertGreaterThanOrEqual(CGRectGetMinX(toolsFrame), CGRectGetMaxX(cancelFrame));
    XCTAssertLessThanOrEqual(CGRectGetMaxX(toolsFrame), CGRectGetMinX(doneFrame));

    CGFloat gapMidX = (CGRectGetMaxX(cancelFrame) + CGRectGetMinX(doneFrame)) * 0.5f;
    XCTAssertEqualWithAccuracy(CGRectGetMidX(toolsFrame), gapMidX, 1.0f);
}

- (void)testDismissingLeavesASheetPresenterOnScreen {
    UIWindow *window = [self presentationTestWindow];
    UIViewController *sheetController = [[UIViewController alloc] init];
    sheetController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:sheetController fromViewController:window.rootViewController animated:NO];
    CGRect sheetFrame = sheetController.view.frame;

    // A sheet's view is never removed from its window, so the crop controller's
    // transition mustn't move or resize it on the way out either
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){400, 300}]];
    [self presentViewController:cropController fromViewController:sheetController animated:YES];
    [self dismissViewController:cropController];

    XCTAssertNotNil(sheetController.view.window);
    XCTAssertTrue(CGRectEqualToRect(sheetController.view.frame, sheetFrame));
}

- (void)testDismissingOverFullScreenLeavesThePresenterOnScreen {
    UIWindow *window = [self presentationTestWindow];
    UIViewController *presentingController = window.rootViewController;

    TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){400, 300}]];
    cropController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:cropController fromViewController:presentingController animated:YES];
    [self dismissViewController:cropController];

    XCTAssertNotNil(presentingController.view.window);
}

- (void)testDismissingFullScreenRestoresThePresenter {
    UIWindow *window = [self presentationTestWindow];
    UIViewController *presentingController = window.rootViewController;

    // Full screen presentations take the presenter's view out of the window, so the
    // transition is responsible for putting it back
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){400, 300}]];
    [self presentViewController:cropController fromViewController:presentingController animated:YES];
    [self dismissViewController:cropController];

    XCTAssertNotNil(presentingController.view.window);
    XCTAssertTrue(CGRectEqualToRect(presentingController.view.frame, window.bounds));
}

- (void)testTransitioningDelegateSetByTheHostIsKept {
    // Hosts opt out of the custom transition by clearing this before presenting,
    // so loading the view mustn't quietly install it again
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){400, 300}]];
    cropController.transitioningDelegate = nil;
    [cropController loadViewIfNeeded];

    XCTAssertNil(cropController.transitioningDelegate);
}

- (void)testUntouchedCropCoversTheWholeImage {
    // Pressing Done without touching anything must hand back every pixel
    for (NSValue *value in @[ @((CGSize){4032, 3024}), @((CGSize){3024, 4032}), @((CGSize){1200, 1600}) ]) {
        CGSize imageSize = value.CGSizeValue;
        [self assertCropFrameAcrossViewWidthsForImageSize:imageSize
                                           afterAdjusting:nil
                                              expectFrame:(CGRect){CGPointZero, imageSize}];
    }
}

- (void)testResetCropCoversTheWholeImage {
    CGSize imageSize = (CGSize){4032, 3024};
    [self assertCropFrameAcrossViewWidthsForImageSize:imageSize
                                       afterAdjusting:^(TOCropView *cropView) {
                                           cropView.scrollView.zoomScale = cropView.scrollView.minimumZoomScale * 2.0f;
                                           [cropView resetLayoutToDefaultAnimated:NO];
                                       }
                                          expectFrame:(CGRect){CGPointZero, imageSize}];
}

- (void)testRotatingAnUncroppedImageKeepsTheWholeImage {
    CGSize imageSize = (CGSize){4032, 3024};
    [self assertCropFrameAcrossViewWidthsForImageSize:imageSize
                                       afterAdjusting:^(TOCropView *cropView) {
                                           [cropView rotateImageNinetyDegreesAnimated:NO clockwise:NO completion:nil];
                                       }
                                          expectFrame:(CGRect){0, 0, imageSize.height, imageSize.width}];
}

- (void)testRotatingAnUncroppedImageAllTheWayAroundKeepsTheWholeImage {
    CGSize imageSize = (CGSize){4032, 3024};
    [self assertCropFrameAcrossViewWidthsForImageSize:imageSize
                                       afterAdjusting:^(TOCropView *cropView) {
                                           for (NSInteger i = 0; i < 4; i++) {
                                               [cropView rotateImageNinetyDegreesAnimated:NO clockwise:NO completion:nil];
                                           }
                                       }
                                          expectFrame:(CGRect){CGPointZero, imageSize}];
}

- (void)testLockedRatioKeepsItsShapeWhenTheImageIsRotated {
    // A locked crop box keeps its shape while the image turns underneath it, and only
    // zooms in as far as it takes to keep the box filled by the now landscape image
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){3024, 4032} lockedRatio:(CGSize){3, 4} dimensionSwapEnabled:NO viewWidth:402];
    [self rotateCropView:cropView times:1];

    CGRect cropFrame = cropView.imageCropFrame;
    XCTAssertEqualWithAccuracy(TOCropAspectRatioOfRect(cropFrame), 3.0 / 4.0, 0.002);
    XCTAssertEqual(cropFrame.size.height, 3024);
}

- (void)testLockedRatioRotationAllTheWayAroundReturnsToTheStart {
    for (NSValue *value in @[ @((CGSize){3024, 4032}), @((CGSize){4032, 3024}) ]) {
        TOCropView *cropView = [self cropViewWithImageSize:value.CGSizeValue lockedRatio:(CGSize){3, 4} dimensionSwapEnabled:NO viewWidth:402];
        CGRect startFrame = cropView.imageCropFrame;
        [self rotateCropView:cropView times:4];
        XCTAssertTrue(CGRectEqualToRect(cropView.imageCropFrame, startFrame), @"%@ came back as %@",
                      NSStringFromCGRect(startFrame), NSStringFromCGRect(cropView.imageCropFrame));
    }
}

- (void)testLockedRatioRotationAllTheWayAroundKeepsAnOffCentreCrop {
    // A zoomed in crop near the image's edge comes back to the same place, rather than
    // drifting or zooming further in with each turn
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){4032, 3024} lockedRatio:(CGSize){3, 4} dimensionSwapEnabled:NO viewWidth:402];
    cropView.imageCropFrame = (CGRect){150, 300, 900, 1200};
    CGRect startFrame = cropView.imageCropFrame;

    [self rotateCropView:cropView times:4];

    XCTAssertTrue(CGRectEqualToRect(cropView.imageCropFrame, startFrame), @"%@ came back as %@",
                  NSStringFromCGRect(startFrame), NSStringFromCGRect(cropView.imageCropFrame));
}

- (void)testAnimatedLockedRatioRotationEndsWhereTheUnanimatedOneDoes {
    UIWindow *window = [self presentationTestWindow];
    TOCropView *animatedView = [self cropViewWithImageSize:(CGSize){3024, 4032} lockedRatio:(CGSize){3, 4} dimensionSwapEnabled:NO viewWidth:402];
    [window.rootViewController.view addSubview:animatedView];
    TOCropView *unanimatedView = [self cropViewWithImageSize:(CGSize){3024, 4032} lockedRatio:(CGSize){3, 4} dimensionSwapEnabled:NO viewWidth:402];

    for (NSInteger i = 0; i < 2; i++) {
        XCTestExpectation *rotated = [self expectationWithDescription:@"Rotated"];
        [animatedView rotateImageNinetyDegreesAnimated:YES clockwise:NO completion:^(BOOL completed) {
            [rotated fulfill];
        }];
        [self waitForExpectations:@[rotated] timeout:5.0];
    }
    [self rotateCropView:unanimatedView times:2];

    XCTAssertTrue(CGRectEqualToRect(animatedView.imageCropFrame, unanimatedView.imageCropFrame), @"%@ vs %@",
                  NSStringFromCGRect(animatedView.imageCropFrame), NSStringFromCGRect(unanimatedView.imageCropFrame));
}

- (void)testSwitchingBetweenTallPresetsKeepsTheCropCentred {
    // These presets are too tall to fit a landscape image at its current zoom, so each
    // one zooms out, which mustn't drag the crop towards the image's left edge
    CGSize imageSize = (CGSize){4032, 3024};
    TOCropView *cropView = [self cropViewLaidOutLikeTheControllerWithImage:[self testImageWithSize:imageSize] frame:(CGRect){0, 0, 402, 874}];
    for (NSValue *value in @[ @((CGSize){2, 3}), @((CGSize){3, 4}), @((CGSize){9, 16}), @((CGSize){2, 3}) ]) {
        [cropView setAspectRatio:value.CGSizeValue animated:NO];
        XCTAssertEqualWithAccuracy(CGRectGetMidX(cropView.imageCropFrame) / imageSize.width, 0.5, 0.01,
                                   @"Off centre after switching to %@", NSStringFromCGSize(value.CGSizeValue));
    }
}

- (void)testExtremeLockedRatioKeepsItsShape {
    // The minimum crop box size mustn't stretch the short side of a very wide ratio
    CGSize ratio = (CGSize){1920, 190};
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){4032, 3024} lockedRatio:ratio dimensionSwapEnabled:NO viewWidth:375];
    XCTAssertEqualWithAccuracy(TOCropAspectRatioOfRect(cropView.imageCropFrame), ratio.width / ratio.height, 0.2);

    [self rotateCropView:cropView times:1];
    XCTAssertEqualWithAccuracy(TOCropAspectRatioOfRect(cropView.imageCropFrame), ratio.width / ratio.height, 0.2);
}

- (void)testExtremeRatioSwapsWithoutLosingItsShape {
    CGSize ratio = (CGSize){1920, 190};
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){4032, 3024} lockedRatio:ratio dimensionSwapEnabled:YES viewWidth:375];
    [self rotateCropView:cropView times:1];

    // Within the few percent that rounding a 34pt tall crop box to whole points costs
    XCTAssertEqualWithAccuracy(TOCropAspectRatioOfRect(cropView.imageCropFrame), ratio.height / ratio.width, 0.005);
}

- (void)testSwappingRotationAfterChoosingARatioKeepsTheSameRegion {
    // Rotating half way round with dimension swapping on shows the same part of the
    // image, so the rotation state saved when the ratio was chosen has to match the box
    CGSize imageSize = (CGSize){4032, 3024};
    TOCropView *cropView = [self cropViewLaidOutLikeTheControllerWithImage:[self testImageWithSize:imageSize]
                                                                     frame:(CGRect){0, 0, 402, 874}
                                                             configuration:^(TOCropView *cropView) {
                                                                 cropView.aspectRatioLockDimensionSwapEnabled = YES;
                                                             }];
    cropView.imageCropFrame = (CGRect){400, 300, 2400, 1600};
    [cropView setAspectRatio:(CGSize){1, 1} animated:NO];
    cropView.aspectRatioLockEnabled = YES;
    CGRect squareFrame = cropView.imageCropFrame;

    [self rotateCropView:cropView times:2];

    XCTAssertEqualWithAccuracy(cropView.imageCropFrame.size.width, squareFrame.size.width, 2.0);
    XCTAssertEqualWithAccuracy(cropView.imageCropFrame.size.height, squareFrame.size.height, 2.0);
}

- (void)testSquarePresetGivesASquareCropAtEveryViewSize {
    // Fitting the preset to the view can land a hair over the view's width, which mustn't
    // cost the box a whole point of width and leave it one point off square
    UIImage *image = [self testImageWithSize:(CGSize){4032, 3024}];
    NSInteger failures = 0;
    NSString *firstFailure = nil;
    for (CGFloat width = 300.0f; width <= 460.0f; width += 1.0f) {
        for (CGFloat height = 700.0f; height <= 940.0f; height += 60.0f) {
            TOCropView *cropView = [self cropViewLaidOutLikeTheControllerWithImage:image
                                                                             frame:(CGRect){0, 0, width, height}
                                                                     configuration:^(TOCropView *cropView) {
                                                                         cropView.aspectRatio = (CGSize){1, 1};
                                                                     }];
            CGSize boxSize = cropView.cropBoxFrame.size;
            CGSize cropSize = cropView.imageCropFrame.size;
            if (boxSize.width != boxSize.height || cropSize.width != cropSize.height) {
                failures++;
                if (firstFailure == nil) {
                    firstFailure = [NSString stringWithFormat:@"box %@ and crop %@ in a %gx%g view",
                                    NSStringFromCGSize(boxSize), NSStringFromCGSize(cropSize), width, height];
                }
            }
        }
    }
    XCTAssertEqual(failures, 0, @"Got %@ (and %ld others)", firstFailure, (long)MAX(0, failures - 1));
}

- (void)testLockedPresetCropsHaveTheExactRatio {
    [self assertExactRatioCropsForRatios:@[ @((CGSize){4, 5}), @((CGSize){3, 2}), @((CGSize){16, 9}) ]
                              imageSizes:@[ @((CGSize){4032, 3024}), @((CGSize){3024, 4032}) ]
                          cropViewMaker:^TOCropView *(UIImage *image, CGSize ratio, CGRect frame) {
                              return [self cropViewLaidOutLikeTheControllerWithImage:image frame:frame configuration:^(TOCropView *cropView) {
                                  cropView.aspectRatioLockEnabled = YES;
                                  cropView.aspectRatio = ratio;
                              }];
                          }];
}

- (void)testPresetChosenFromThePickerHasTheExactRatio {
    // The controller applies a picked preset to a crop view that's already laid out, then locks it
    [self assertExactRatioCropsForRatios:@[ @((CGSize){4, 5}), @((CGSize){3, 2}), @((CGSize){16, 9}) ]
                              imageSizes:@[ @((CGSize){4032, 3024}) ]
                          cropViewMaker:^TOCropView *(UIImage *image, CGSize ratio, CGRect frame) {
                              TOCropView *cropView = [self cropViewLaidOutLikeTheControllerWithImage:image frame:frame];
                              [cropView setAspectRatio:ratio animated:NO];
                              cropView.aspectRatioLockEnabled = YES;
                              return cropView;
                          }];
}

- (void)testExtremeLockedRatioStaysExactWhenRotated {
    CGSize ratio = (CGSize){1920, 190};
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){4032, 3024} lockedRatio:ratio dimensionSwapEnabled:NO viewWidth:375];
    XCTAssertLessThanOrEqual(TOCropPixelsOffAspectRatio(cropView.imageCropFrame, ratio), 1.0);

    [self rotateCropView:cropView times:1];
    XCTAssertLessThanOrEqual(TOCropPixelsOffAspectRatio(cropView.imageCropFrame, ratio), 1.0);
}

- (void)testSwappedExtremeRatioIsExactWhenRotated {
    TOCropView *cropView = [self cropViewWithImageSize:(CGSize){4032, 3024} lockedRatio:(CGSize){1920, 190} dimensionSwapEnabled:YES viewWidth:375];
    [self rotateCropView:cropView times:1];
    XCTAssertLessThanOrEqual(TOCropPixelsOffAspectRatio(cropView.imageCropFrame, (CGSize){190, 1920}), 1.0);
}

- (void)testCroppingAPhotoKeepsItsEightBitWideColourFormat {
    // Rendering the crop at 16 bits per channel doubles the memory a large photo takes,
    // which is enough to crash a share extension, and converting it to sRGB would clip
    // the photo's most saturated colours
    UIImage *image = [self displayP3PhotoWithSize:(CGSize){400, 300}];
    NSArray *crops = @[ @[ @0, @NO, [NSValue valueWithCGRect:(CGRect){50, 40, 200, 150}] ],
                        @[ @90, @NO, [NSValue valueWithCGRect:(CGRect){40, 50, 150, 200}] ],
                        @[ @0, @YES, [NSValue valueWithCGRect:(CGRect){50, 40, 150, 150}] ] ];
    for (NSArray *crop in crops) {
        UIImage *cropped = [image croppedImageWithFrame:[crop[2] CGRectValue] angle:[crop[0] integerValue] circularClip:[crop[1] boolValue]];
        CFStringRef colorSpaceName = CGColorSpaceCopyName(CGImageGetColorSpace(cropped.CGImage));
        XCTAssertEqual(CGImageGetBitsPerComponent(cropped.CGImage), 8, @"%@", crop);
        XCTAssertTrue(colorSpaceName != NULL && CFEqual(colorSpaceName, kCGColorSpaceDisplayP3), @"%@ came out in %@", crop, colorSpaceName);
        if (colorSpaceName) {
            CFRelease(colorSpaceName);
        }
    }
}

- (void)testUnrotatedCropReusesThePhotosPixels {
    // A crop that's only cut out of the photo, not rotated or clipped, needs no new bitmap
    // at all. Sharing the photo's pixel buffer shows up as keeping its row length.
    UIImage *image = [self displayP3PhotoWithSize:(CGSize){400, 300}];
    UIImage *cropped = [image croppedImageWithFrame:(CGRect){50, 40, 120, 150} angle:0 circularClip:NO];
    XCTAssertEqual(CGImageGetBytesPerRow(cropped.CGImage), CGImageGetBytesPerRow(image.CGImage));
    XCTAssertEqual(cropped.imageOrientation, UIImageOrientationUp);
}

- (void)testUnrotatedCropsHaveTheRightPixels {
    // The crop frame is in the image's displayed points, so it has to be mapped through the
    // image's scale and orientation to find the right pixels
    CGRect frame = (CGRect){30, 10, 60, 50};
    for (NSNumber *orientation in @[ @(UIImageOrientationUp), @(UIImageOrientationRight), @(UIImageOrientationLeftMirrored) ]) {
        for (NSNumber *scale in @[ @1, @2 ]) {
            UIImage *image = [self quarteredImageWithSize:(CGSize){120, 80} scale:scale.floatValue orientation:orientation.integerValue];
            UIImage *cropped = [image croppedImageWithFrame:frame angle:0 circularClip:NO];
            XCTAssertEqualWithAccuracy(cropped.size.width, frame.size.width, FLT_EPSILON);
            XCTAssertEqualWithAccuracy(cropped.size.height, frame.size.height, FLT_EPSILON);
            for (NSValue *pointValue in @[ [NSValue valueWithCGPoint:(CGPoint){1, 1}], [NSValue valueWithCGPoint:(CGPoint){58, 1}],
                                           [NSValue valueWithCGPoint:(CGPoint){1, 48}], [NSValue valueWithCGPoint:(CGPoint){58, 48}] ]) {
                CGPoint point = pointValue.CGPointValue;
                CGFloat pixelScale = scale.floatValue;
                CGPoint croppedPixel = (CGPoint){point.x * pixelScale, point.y * pixelScale};
                CGPoint sourcePixel = (CGPoint){(frame.origin.x + point.x) * pixelScale, (frame.origin.y + point.y) * pixelScale};
                XCTAssertEqualObjects([self rgbaOfPixel:croppedPixel inImage:cropped], [self rgbaOfPixel:sourcePixel inImage:image],
                                      @"Orientation %@, scale %@, point %@", orientation, scale, NSStringFromCGPoint(point));
            }
        }
    }
}

- (void)testEmbeddedControllerStaysInsideItsOwnFrame {
    UIWindow *window = [self presentationTestWindow];
    CGRect frame = (CGRect){0, 0, CGRectGetWidth(window.bounds), CGRectGetHeight(window.bounds) - 150};
    TOCropViewController *cropController = [self cropControllerEmbeddedInWindow:window frame:frame configuration:nil];

    XCTAssertTrue(CGRectContainsRect(cropController.view.bounds, cropController.cropView.frame), @"%@ overhangs %@",
                  NSStringFromCGRect(cropController.cropView.frame), NSStringFromCGRect(cropController.view.bounds));
}

- (void)testTopToolbarClearsAStatusBarItCantHide {
    // An embedded controller doesn't get a say over the status bar, so it stays on screen
    UIWindow *window = [self presentationTestWindow];
    TOCropViewController *cropController = [self cropControllerEmbeddedInWindow:window
                                                                          frame:window.bounds
                                                                  configuration:^(TOCropViewController *cropController) {
                                                                      cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;
                                                                  }];

    XCTAssertGreaterThan(cropController.view.safeAreaInsets.top, 0.0f);
    XCTAssertGreaterThanOrEqual(CGRectGetMinY(cropController.toolbar.frame), cropController.view.safeAreaInsets.top);
}

- (void)testTopToolbarSitsBelowTheTitle {
    UIWindow *window = [self presentationTestWindow];
    TOCropViewController *cropController = [self cropControllerEmbeddedInWindow:window
                                                                          frame:window.bounds
                                                                  configuration:^(TOCropViewController *cropController) {
                                                                      cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;
                                                                      cropController.title = @"Crop Your Photo";
                                                                  }];

    XCTAssertGreaterThanOrEqual(CGRectGetMinY(cropController.toolbar.frame), CGRectGetMaxY(cropController.titleLabel.frame), @"Toolbar %@, title %@",
                                NSStringFromCGRect(cropController.toolbar.frame), NSStringFromCGRect(cropController.titleLabel.frame));
}

@end
