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
#import "TOCropViewControllerTransitioning.h"
#import "UIImage+CropRotate.h"

// Expose private state so tests can arm the reset timer, simulate an in-flight
// rotation, drive the scroll view's touch hooks, stand in for a touch landing
// on the crop box or dragging its corners and edges, and settle an edit the way
// the reset timer does
@interface TOCropView (UnitTests) <UIGestureRecognizerDelegate>
- (void)startResetTimer;
- (void)startEditing;
- (void)setEditing:(BOOL)editing resetCropBox:(BOOL)resetCropbox animated:(BOOL)animated;
@property (nonatomic, assign) BOOL rotateAnimationInProgress;
@property (nonatomic, strong, readonly) TOCropScrollView *scrollView;
@property (nonatomic, strong, readonly) NSTimer *resetTimer;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *gridPanGestureRecognizer;
@property (nonatomic, assign) CGPoint gridPanInitialPoint;
@property (nonatomic, readonly) CGRect cropBoxFrame;
@property (nonatomic, readonly) CGRect contentBounds;
@property (nonatomic, assign) CGPoint panOriginPoint;
@property (nonatomic, assign) CGRect cropOriginFrame;
@property (nonatomic, assign) NSInteger tappedEdge;
- (NSInteger)cropEdgeForPoint:(CGPoint)point;
- (void)updateCropBoxFrameWithGesturePoint:(CGPoint)point;
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

// The corner adapted layout regions only resolve against a real display, so stand in
// for a folding phone's unfolded inner display - large rounded corners asking for a
// 16pt concentric inset on every edge the safe area leaves bare - while a block runs.
// The factory swizzle hands the adaptivity axis through as a boxed sentinel for the
// edge inset swizzle to recognise, leaving every other layout region untouched
@interface UIViewLayoutRegion (TOCropTestCornerRegions)
+ (UIViewLayoutRegion *)to_test_safeAreaLayoutRegionWithCornerAdaptation:(UIViewLayoutRegionAdaptivityAxis)axis;
@end

@implementation UIViewLayoutRegion (TOCropTestCornerRegions)
+ (UIViewLayoutRegion *)to_test_safeAreaLayoutRegionWithCornerAdaptation:(UIViewLayoutRegionAdaptivityAxis)axis {
    return (UIViewLayoutRegion *)@(axis);
}
@end

@interface UIView (TOCropTestCornerRegionInsets)
- (UIEdgeInsets)to_test_edgeInsetsForLayoutRegion:(UIViewLayoutRegion *)region;
@end

@implementation UIView (TOCropTestCornerRegionInsets)
- (UIEdgeInsets)to_test_edgeInsetsForLayoutRegion:(UIViewLayoutRegion *)region {
    if ([(id)region isKindOfClass:[NSNumber class]]) {
        switch ((UIViewLayoutRegionAdaptivityAxis)[(NSNumber *)region unsignedIntegerValue]) {
            case UIViewLayoutRegionAdaptivityAxisHorizontal: return (UIEdgeInsets){0, 16, 34, 16};
            case UIViewLayoutRegionAdaptivityAxisVertical: return (UIEdgeInsets){16, 0, 34, 0};
            case UIViewLayoutRegionAdaptivityAxisNone: break;
        }
        return (UIEdgeInsets){0, 0, 34, 0};
    }
    return [self to_test_edgeInsetsForLayoutRegion:region];
}
@end

static void TOCropRunWhileDisplayHasRoundedCorners(void (^block)(void)) {
    Method realFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(safeAreaLayoutRegionWithCornerAdaptation:));
    Method stubFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(to_test_safeAreaLayoutRegionWithCornerAdaptation:));
    Method realInsets = class_getInstanceMethod([UIView class], @selector(edgeInsetsForLayoutRegion:));
    Method stubInsets = class_getInstanceMethod([UIView class], @selector(to_test_edgeInsetsForLayoutRegion:));
    method_exchangeImplementations(realFactory, stubFactory);
    method_exchangeImplementations(realInsets, stubInsets);
    block();
    method_exchangeImplementations(realInsets, stubInsets);
    method_exchangeImplementations(realFactory, stubFactory);
}

// The cover display of a folding phone, turned to landscape so the camera gutter
// column lands on the leading edge: the system hands the whole column over as an
// outsized leading safe area inset, and its bar region for that edge places a side
// bar inside the column, below the camera itself. The factory swizzles hand each
// request through as a boxed sentinel (the bar's edge offset by 100, so it can never
// collide with a corner adaptivity axis) for the edge inset swizzle to recognise
@interface UIViewLayoutRegion (TOCropTestBarRegions)
+ (UIViewLayoutRegion *)to_test_layoutRegionForBarOnEdge:(UIRectEdge)edge extent:(CGFloat)extent;
@end

@implementation UIViewLayoutRegion (TOCropTestBarRegions)
+ (UIViewLayoutRegion *)to_test_layoutRegionForBarOnEdge:(UIRectEdge)edge extent:(CGFloat)extent {
    return (UIViewLayoutRegion *)@(100 + edge);
}
@end

@interface UIView (TOCropTestLeadingGutter)
- (UIEdgeInsets)to_test_leadingGutterSafeAreaInsets;
- (UIEdgeInsets)to_test_leadingGutterEdgeInsetsForLayoutRegion:(UIViewLayoutRegion *)region;
@end

@implementation UIView (TOCropTestLeadingGutter)
- (UIEdgeInsets)to_test_leadingGutterSafeAreaInsets {
    return (UIEdgeInsets){0, 84, 34, 0};
}
- (UIEdgeInsets)to_test_leadingGutterEdgeInsetsForLayoutRegion:(UIViewLayoutRegion *)region {
    if ([(id)region isKindOfClass:[NSNumber class]]) {
        switch ((NSUInteger)[(NSNumber *)region unsignedIntegerValue]) {
            case 100 + UIRectEdgeLeft: return (UIEdgeInsets){82, 26, 34, 608};
            case 100 + UIRectEdgeRight: return (UIEdgeInsets){17.33, 608, 34, 26};
            case UIViewLayoutRegionAdaptivityAxisHorizontal: return (UIEdgeInsets){0, 84, 34, 17.33};
            case UIViewLayoutRegionAdaptivityAxisVertical: return (UIEdgeInsets){17.33, 84, 34, 0};
            default: return (UIEdgeInsets){0, 84, 34, 0};
        }
    }
    return [self to_test_leadingGutterEdgeInsetsForLayoutRegion:region];
}
@end

static void TOCropRunWhileLandscapeLeadingEdgeHasCameraGutter(void (^block)(void)) {
    Method realSafeArea = class_getInstanceMethod([UIView class], @selector(safeAreaInsets));
    Method stubSafeArea = class_getInstanceMethod([UIView class], @selector(to_test_leadingGutterSafeAreaInsets));
    Method realBarFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(layoutRegionForBarOnEdge:extent:));
    Method stubBarFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(to_test_layoutRegionForBarOnEdge:extent:));
    Method realCornerFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(safeAreaLayoutRegionWithCornerAdaptation:));
    Method stubCornerFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(to_test_safeAreaLayoutRegionWithCornerAdaptation:));
    Method realInsets = class_getInstanceMethod([UIView class], @selector(edgeInsetsForLayoutRegion:));
    Method stubInsets = class_getInstanceMethod([UIView class], @selector(to_test_leadingGutterEdgeInsetsForLayoutRegion:));
    method_exchangeImplementations(realSafeArea, stubSafeArea);
    method_exchangeImplementations(realBarFactory, stubBarFactory);
    method_exchangeImplementations(realCornerFactory, stubCornerFactory);
    method_exchangeImplementations(realInsets, stubInsets);
    block();
    method_exchangeImplementations(realInsets, stubInsets);
    method_exchangeImplementations(realCornerFactory, stubCornerFactory);
    method_exchangeImplementations(realBarFactory, stubBarFactory);
    method_exchangeImplementations(realSafeArea, stubSafeArea);
}

// The same cover display upright: the camera gutter column sits on the trailing edge,
// its bar region places the side bar inside it, and the bare leading edge asks for a
// fractional corner nudge - the layout regions' insets land on thirds of a point
@interface UIView (TOCropTestTrailingGutter)
- (UIEdgeInsets)to_test_trailingGutterSafeAreaInsets;
- (UIEdgeInsets)to_test_trailingGutterEdgeInsetsForLayoutRegion:(UIViewLayoutRegion *)region;
@end

@implementation UIView (TOCropTestTrailingGutter)
- (UIEdgeInsets)to_test_trailingGutterSafeAreaInsets {
    return (UIEdgeInsets){0, 0, 34, 84};
}
- (UIEdgeInsets)to_test_trailingGutterEdgeInsetsForLayoutRegion:(UIViewLayoutRegion *)region {
    if ([(id)region isKindOfClass:[NSNumber class]]) {
        switch ((NSUInteger)[(NSNumber *)region unsignedIntegerValue]) {
            case 100 + UIRectEdgeRight: return (UIEdgeInsets){82, 396, 34, 26};
            case 100 + UIRectEdgeLeft: return (UIEdgeInsets){17.33, 26, 34, 396};
            case UIViewLayoutRegionAdaptivityAxisHorizontal: return (UIEdgeInsets){0, 2.33, 34, 84};
            case UIViewLayoutRegionAdaptivityAxisVertical: return (UIEdgeInsets){17.33, 0, 34, 84};
            default: return (UIEdgeInsets){0, 0, 34, 84};
        }
    }
    return [self to_test_trailingGutterEdgeInsetsForLayoutRegion:region];
}
@end

static void TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(void (^block)(void)) {
    Method realSafeArea = class_getInstanceMethod([UIView class], @selector(safeAreaInsets));
    Method stubSafeArea = class_getInstanceMethod([UIView class], @selector(to_test_trailingGutterSafeAreaInsets));
    Method realBarFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(layoutRegionForBarOnEdge:extent:));
    Method stubBarFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(to_test_layoutRegionForBarOnEdge:extent:));
    Method realCornerFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(safeAreaLayoutRegionWithCornerAdaptation:));
    Method stubCornerFactory = class_getClassMethod([UIViewLayoutRegion class], @selector(to_test_safeAreaLayoutRegionWithCornerAdaptation:));
    Method realInsets = class_getInstanceMethod([UIView class], @selector(edgeInsetsForLayoutRegion:));
    Method stubInsets = class_getInstanceMethod([UIView class], @selector(to_test_trailingGutterEdgeInsetsForLayoutRegion:));
    method_exchangeImplementations(realSafeArea, stubSafeArea);
    method_exchangeImplementations(realBarFactory, stubBarFactory);
    method_exchangeImplementations(realCornerFactory, stubCornerFactory);
    method_exchangeImplementations(realInsets, stubInsets);
    block();
    method_exchangeImplementations(realInsets, stubInsets);
    method_exchangeImplementations(realCornerFactory, stubCornerFactory);
    method_exchangeImplementations(realBarFactory, stubBarFactory);
    method_exchangeImplementations(realSafeArea, stubSafeArea);
}

// A stand-in for the presenting view that a full screen presentation detaches: its layout
// depends on inputs that refresh only once it is back in a window (the way safe areas do
// after a 180° turn between landscapes), so wherever its subview sat while detached, a
// real layout pass parks it at the settled spot
@interface TOCropTestRelayoutingPresenterView : UIView
@property (nonatomic, strong) UIView *destinationView;
@property (nonatomic, assign) CGRect settledDestinationFrame;
@end

@implementation TOCropTestRelayoutingPresenterView
- (void)layoutSubviews {
    [super layoutSubviews];
    self.destinationView.frame = self.settledDestinationFrame;
}
@end

@interface TOCropTestDismissalContext : NSObject <UIViewControllerContextTransitioning>
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIViewController *fromViewController;
@property (nonatomic, strong) UIViewController *toViewController;
@property (nonatomic, strong) UIView *toView;
@end

@implementation TOCropTestDismissalContext
- (UIViewController *)viewControllerForKey:(UITransitionContextViewControllerKey)key {
    return [key isEqualToString:UITransitionContextFromViewControllerKey] ? self.fromViewController : self.toViewController;
}
- (UIView *)viewForKey:(UITransitionContextViewKey)key {
    return [key isEqualToString:UITransitionContextToViewKey] ? self.toView : nil;
}
- (BOOL)isAnimated { return YES; }
- (BOOL)isInteractive { return NO; }
- (BOOL)transitionWasCancelled { return NO; }
- (UIModalPresentationStyle)presentationStyle { return UIModalPresentationFullScreen; }
- (void)updateInteractiveTransition:(CGFloat)percentComplete {}
- (void)finishInteractiveTransition {}
- (void)cancelInteractiveTransition {}
- (void)pauseInteractiveTransition {}
- (void)completeTransition:(BOOL)didComplete {}
- (CGAffineTransform)targetTransform { return CGAffineTransformIdentity; }
- (CGRect)initialFrameForViewController:(UIViewController *)vc { return self.containerView.bounds; }
- (CGRect)finalFrameForViewController:(UIViewController *)vc { return self.containerView.bounds; }
@end

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

// The crop box's corners and edges, clockwise from the top left, each as the direction it points out of the box
static const CGPoint kTOCropBoxHandles[8] = {{-1, -1}, {0, -1}, {1, -1}, {1, 0}, {1, 1}, {0, 1}, {-1, 1}, {-1, 0}};
static NSString *const kTOCropBoxHandleNames[8] = {@"top left", @"top", @"top right", @"right", @"bottom right", @"bottom", @"bottom left", @"left"};

// Drags one of the crop box's corners or edges out by a distance (or in, when it's negative) a step
// at a time, the way a touch moves, calling the block after each step
- (void)dragCropBoxOfCropView:(TOCropView *)cropView handle:(NSInteger)handle by:(CGFloat)distance afterEachStep:(void (^)(void))afterEachStep {
    CGRect frame = cropView.cropBoxFrame;
    CGPoint direction = kTOCropBoxHandles[handle];
    CGPoint touch = (CGPoint){CGRectGetMidX(frame) + (direction.x * CGRectGetWidth(frame) * 0.5f),
                              CGRectGetMidY(frame) + (direction.y * CGRectGetHeight(frame) * 0.5f)};
    cropView.panOriginPoint = touch;
    cropView.cropOriginFrame = frame;
    cropView.tappedEdge = [cropView cropEdgeForPoint:touch];

    const NSInteger steps = 20;
    for (NSInteger step = 1; step <= steps; step++) {
        CGFloat travelled = distance * step / steps;
        [cropView updateCropBoxFrameWithGesturePoint:(CGPoint){touch.x + (direction.x * travelled), touch.y + (direction.y * travelled)}];
        if (afterEachStep) {
            afterEachStep();
        }
    }
}

// Runs each sequence of drags (pairs of a handle and a distance) on a fresh crop box locked to each of a
// spread of ratios, on landscape and portrait images, reporting the first step of any of them that leaves
// the box out of its ratio, smaller than its minimum size, or outside the content
- (void)assertLockedCropBoxKeepsItsShapeThroughDrags:(NSArray<NSArray<NSArray<NSNumber *> *> *> *)sequences {
    NSArray<NSValue *> *ratios = @[ [NSValue valueWithCGSize:(CGSize){1, 1}], [NSValue valueWithCGSize:(CGSize){16, 9}],
                                    [NSValue valueWithCGSize:(CGSize){9, 16}], [NSValue valueWithCGSize:(CGSize){4, 3}],
                                    [NSValue valueWithCGSize:(CGSize){3, 4}] ];
    NSArray<NSValue *> *imageSizes = @[ [NSValue valueWithCGSize:(CGSize){400, 300}], [NSValue valueWithCGSize:(CGSize){300, 400}] ];

    __block NSInteger failures = 0;
    __block NSString *firstFailure = nil;
    for (NSValue *imageSizeValue in imageSizes) {
        for (NSValue *ratioValue in ratios) {
            CGSize ratio = ratioValue.CGSizeValue;
            for (NSArray<NSArray<NSNumber *> *> *sequence in sequences) {
                TOCropView *cropView = [self cropViewWithImageSize:imageSizeValue.CGSizeValue lockedRatio:ratio dimensionSwapEnabled:NO viewWidth:402];
                CGRect contentBounds = CGRectInset(cropView.contentBounds, -1.0f, -1.0f);
                NSMutableArray<NSString *> *drags = [NSMutableArray array];
                for (NSArray<NSNumber *> *drag in sequence) {
                    [drags addObject:[NSString stringWithFormat:@"the %@ by %@", kTOCropBoxHandleNames[drag[0].integerValue], drag[1]]];
                    [self dragCropBoxOfCropView:cropView handle:drag[0].integerValue by:drag[1].floatValue afterEachStep:^{
                        CGRect frame = cropView.cropBoxFrame;
                        if (TOCropPixelsOffAspectRatio(frame, ratio) <= 1.0f && MIN(frame.size.width, frame.size.height) >= 41.0f &&
                            CGRectContainsRect(contentBounds, frame)) {
                            return;
                        }
                        failures++;
                        if (firstFailure == nil) {
                            firstFailure = [NSString stringWithFormat:@"%@ dragging %@, at %@ on a %@ image", NSStringFromCGRect(frame),
                                            [drags componentsJoinedByString:@" then "], NSStringFromCGSize(ratio),
                                            NSStringFromCGSize(imageSizeValue.CGSizeValue)];
                        }
                    }];
                }
            }
        }
    }
    XCTAssertEqual(failures, 0, @"The locked crop box went out of shape: %@ (and %ld other steps)", firstFailure, (long)MAX(0, failures - 1));
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

- (void)testLandscapeToolbarFollowsCameraGutterToLeadingEdge {
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];

    TOCropRunWhileLandscapeLeadingEdgeHasCameraGutter(^{
        // A squat cover display turned so the camera column lands on the leading
        // edge: the button strip must cross over to that edge and flow down the
        // camera's own column below the punch, freeing the trailing edge so the
        // crop region only owes its rounded corner there
        controller.view.frame = (CGRect){0, 0, 678, 466};
        [controller.view layoutIfNeeded];

        // From iOS 27.1 the system's bar region places the strip in the column; built against
        // an earlier SDK, or running on an earlier version, it's centred in the 84pt gutter
        // ((84 - 44) / 2) and starts a gutter's width down, clear of the camera
        CGPoint expectedOrigin = (CGPoint){20, 84};
#if defined(__IPHONE_27_1)
        if (@available(iOS 27.1, *)) {
            expectedOrigin = (CGPoint){26, 82};
        }
#endif
        CGRect toolbarFrame = controller.toolbar.frame;
        XCTAssertEqualWithAccuracy(CGRectGetMinX(toolbarFrame), expectedOrigin.x, FLT_EPSILON,
                                   @"the strip must sit inside the leading camera gutter");
        XCTAssertEqualWithAccuracy(CGRectGetMinY(toolbarFrame), expectedOrigin.y, FLT_EPSILON,
                                   @"the strip must start below the camera itself");

        UIEdgeInsets insets = controller.cropView.cropRegionInsets;
        XCTAssertEqualWithAccuracy(insets.left, CGRectGetMaxX(toolbarFrame), FLT_EPSILON,
                                   @"the crop region must start right past the strip");
        XCTAssertEqualWithAccuracy(insets.right, 17.33, 0.05,
                                   @"the freed trailing edge must owe only its corner inset");
    });
}

- (void)testUntouchedCropIsNotResettableWithFractionalContentInsets {
    // A wide image on the upright gutter display: the corner nudge leaves the content
    // bounds at a fractional leading origin, so the whole-point crop box laid out inside
    // them comes up a point shorter than the raw scaled fit it was captured against. An
    // untouched crop must still read as the resting state, or the reset button lights up
    // the moment the screen appears (and again on every rotation)
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];

    TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 466, 678};
        [controller.view layoutIfNeeded];
        XCTAssertFalse(controller.cropView.canBeReset,
                       @"a crop nobody has touched must not be resettable");
    });
}

- (void)testToolbarGlidesToItsSettledFrameAfterPresentation {
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];

    TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 466, 678};
        [controller.view layoutIfNeeded];
        CGRect settledFrame = controller.toolbar.frame;

        // While a presentation runs, the status bar's glyphs still hold the camera
        // gutter column, so the strip rides out the animation placed further down the
        // column. The fade that then dismisses them frees the strip's resting place,
        // and the strip has to glide up to it with that fade, never teleport
        controller.toolbar.frame = CGRectOffset(settledFrame, 0, 92);
        [controller viewDidAppear:YES];
        XCTAssertTrue(CGRectEqualToRect(controller.toolbar.frame, settledFrame),
                      @"the fade must put the strip back on its settled frame");
        XCTAssertTrue(controller.toolbar.layer.animationKeys.count > 0,
                      @"the strip must animate to its settled frame, not teleport");
    });
}

- (void)testStatusBarYieldsTheGutterColumnDuringPresentation {
    // The status bar's glyphs stack down the same camera gutter column the side toolbar
    // rests in, so on those displays the bar must hide with the presentation itself.
    // Deferring its exit until the animation lands parks the strip under the glyphs,
    // then migrates it into the room they leave behind
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];
    TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 466, 678};
        [controller.view layoutIfNeeded];
        [controller viewWillAppear:YES];
        XCTAssertTrue(controller.prefersStatusBarHidden,
                      @"a side toolbar display must cede the status bar as the presentation starts");
    });

    // A phone whose status bar lies along the top edge keeps the gentler exit,
    // fading it out only once the presentation has landed
    TOCropViewController *classicController = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];
    classicController.view.frame = (CGRect){0, 0, 402, 874};
    [classicController.view layoutIfNeeded];
    [classicController viewWillAppear:YES];
    XCTAssertFalse(classicController.prefersStatusBarHidden,
                   @"a phone with a top status bar must keep it through the presentation animation");
}

- (void)testCropRegionClearsTheDisplaysRoundedCorners {
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){40, 20}]];

    TOCropRunWhileViewHasBottomSafeArea(^{
        TOCropRunWhileDisplayHasRoundedCorners(^{
            // The unfolded inner display in landscape: the toolbar guards the trailing
            // edge, but the top and leading edges have no safe area at all, leaving the
            // crop box's sharp corners poking into the display's rounded ones
            controller.view.frame = (CGRect){0, 0, 951, 669};
            [controller.view layoutIfNeeded];

            UIEdgeInsets insets = controller.cropView.cropRegionInsets;
            XCTAssertEqualWithAccuracy(insets.top, 16.0, FLT_EPSILON,
                                       @"a bare top edge must take the display's concentric corner inset");
            XCTAssertEqualWithAccuracy(insets.left, 16.0, FLT_EPSILON,
                                       @"a bare leading edge must take the display's concentric corner inset");
            XCTAssertEqualWithAccuracy(insets.bottom, 34.0, FLT_EPSILON,
                                       @"an edge the safe area already clears must keep its own inset");
            XCTAssertGreaterThan(insets.right, 16.0,
                                 @"the toolbar's edge must keep its own larger inset");
        });
    });
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

- (void)testDoneWhileTheImageIsPulledPastTheCropBoxCommitsWhereItComesToRest {
    // Mid-drag, or while it bounces back after one, the image can be pulled well past the edges of
    // the crop box, but what gets committed should be the crop it's about to spring back to
    UIWindow *window = [self presentationTestWindow];
    TOCropViewController *cropController = [self cropControllerEmbeddedInWindow:window frame:window.bounds configuration:nil];
    TOCropView *cropView = cropController.cropView;
    UIScrollView *scrollView = cropView.scrollView;

    __block CGRect committedFrame = CGRectNull;
    cropController.onDidCropImageToRect = ^(CGRect cropRect, NSInteger angle) {
        committedFrame = cropRect;
    };

    for (NSNumber *zoom in @[ @1, @2 ]) {
        scrollView.zoomScale = scrollView.minimumZoomScale * zoom.floatValue;

        // At rest, the content can go no further than lining its edges up with the crop box's
        CGRect cropBoxFrame = cropView.cropBoxFrame;
        CGFloat leftmost = -CGRectGetMinX(cropBoxFrame), rightmost = scrollView.contentSize.width - CGRectGetMaxX(cropBoxFrame);
        CGFloat topmost = -CGRectGetMinY(cropBoxFrame), bottommost = scrollView.contentSize.height - CGRectGetMaxY(cropBoxFrame);
        CGFloat middleX = (leftmost + rightmost) * 0.5f, middleY = (topmost + bottommost) * 0.5f;

        NSArray<NSArray<NSValue *> *> *pulls = @[
            @[ @((CGPoint){leftmost - 150, middleY}), @((CGPoint){leftmost, middleY}) ],
            @[ @((CGPoint){rightmost + 150, middleY}), @((CGPoint){rightmost, middleY}) ],
            @[ @((CGPoint){middleX, topmost - 150}), @((CGPoint){middleX, topmost}) ],
            @[ @((CGPoint){middleX, bottommost + 150}), @((CGPoint){middleX, bottommost}) ],
            @[ @((CGPoint){rightmost + 1000, bottommost + 1000}), @((CGPoint){rightmost, bottommost}) ],
        ];
        for (NSArray<NSValue *> *pull in pulls) {
            scrollView.contentOffset = pull[1].CGPointValue;
            CGRect restingFrame = cropView.imageCropFrame;

            scrollView.contentOffset = pull[0].CGPointValue;
            [cropController commitCurrentCrop];
            XCTAssertTrue(CGRectEqualToRect(committedFrame, restingFrame), @"At %@x zoom, pulled to %@: committed %@, but it comes to rest on %@", zoom,
                          NSStringFromCGPoint(pull[0].CGPointValue), NSStringFromCGRect(committedFrame), NSStringFromCGRect(restingFrame));
        }
    }
}

- (void)testLockedCropBoxKeepsItsShapeWhenDraggedOutAgainstTheEdgeOfTheContent {
    // Shrinking the box from a corner leaves it up against the content's edges on the far side, so
    // dragging it out again before it re-centres used to stop one side at an edge while the other kept going
    NSMutableArray<NSArray<NSArray<NSNumber *> *> *> *sequences = [NSMutableArray array];
    for (NSInteger corner = 0; corner < 8; corner += 2) {
        for (NSInteger handle = 0; handle < 8; handle++) {
            [sequences addObject:@[ @[ @(corner), @-120 ], @[ @(handle), @400 ] ]];
        }
    }
    [self assertLockedCropBoxKeepsItsShapeThroughDrags:sequences];
}

- (void)testLockedCropBoxKeepsItsShapeWhenShrunkAllTheWay {
    // The long side used to stop at the minimum size of a short one, while the short side kept shrinking
    NSMutableArray<NSArray<NSArray<NSNumber *> *> *> *sequences = [NSMutableArray array];
    for (NSInteger handle = 0; handle < 8; handle++) {
        [sequences addObject:@[ @[ @(handle), @-1000 ] ]];
    }
    [self assertLockedCropBoxKeepsItsShapeThroughDrags:sequences];
}

- (void)testLockedCropBoxKeepsItsShapeAtEveryStepOfADrag {
    // Dragging an edge used to size the other side to match where the box was a step earlier, so it
    // went out of shape while it moved
    NSMutableArray<NSArray<NSArray<NSNumber *> *> *> *sequences = [NSMutableArray array];
    for (NSInteger handle = 0; handle < 8; handle++) {
        [sequences addObject:@[ @[ @(handle), @-150 ] ]];
    }
    [self assertLockedCropBoxKeepsItsShapeThroughDrags:sequences];
}

- (void)testLockedCropBoxDraggedByAnEdgeSlidesAlongTheContentToGrow {
    // Dragging out the bottom edge of a box that's up against the left or right of the content grows it
    // as far as there's room for, sliding it away from that side rather than stopping it
    for (NSValue *ratioValue in @[ [NSValue valueWithCGSize:(CGSize){1, 1}], [NSValue valueWithCGSize:(CGSize){16, 9}], [NSValue valueWithCGSize:(CGSize){3, 4}] ]) {
        CGSize ratio = ratioValue.CGSizeValue;
        for (NSNumber *corner in @[ @0, @2 ]) {
            TOCropView *cropView = [self cropViewWithImageSize:(CGSize){400, 300} lockedRatio:ratio dimensionSwapEnabled:NO viewWidth:402];
            CGRect contentBounds = cropView.contentBounds;
            [self dragCropBoxOfCropView:cropView handle:corner.integerValue by:-120 afterEachStep:nil];
            CGFloat roomBelow = CGRectGetMaxY(contentBounds) - CGRectGetMinY(cropView.cropBoxFrame);
            CGFloat expectedWidth = MIN(CGRectGetWidth(contentBounds), roomBelow * ratio.width / ratio.height);

            [self dragCropBoxOfCropView:cropView handle:5 by:1000 afterEachStep:nil];
            XCTAssertEqualWithAccuracy(CGRectGetWidth(cropView.cropBoxFrame), expectedWidth, 1.0f, @"At %@, after shrinking from the %@, it grew to %@",
                                       NSStringFromCGSize(ratio), kTOCropBoxHandleNames[corner.integerValue], NSStringFromCGRect(cropView.cropBoxFrame));
            XCTAssertLessThanOrEqual(TOCropPixelsOffAspectRatio(cropView.cropBoxFrame, ratio), 1.0f, @"At %@, after shrinking from the %@, it grew to %@",
                                     NSStringFromCGSize(ratio), kTOCropBoxHandleNames[corner.integerValue], NSStringFromCGRect(cropView.cropBoxFrame));
        }
    }
}

- (void)testLockedCropBoxGrowsBackOutFromEveryCornerAndEdge {
    // A locked box shrunk from any corner or edge can be dragged back out from it again, the
    // same as one that isn't locked, rather than only from its bottom and right
    for (NSValue *ratioValue in @[ [NSValue valueWithCGSize:(CGSize){1, 1}], [NSValue valueWithCGSize:(CGSize){16, 9}], [NSValue valueWithCGSize:(CGSize){3, 4}] ]) {
        CGSize ratio = ratioValue.CGSizeValue;
        for (NSInteger handle = 0; handle < 8; handle++) {
            TOCropView *cropView = [self cropViewWithImageSize:(CGSize){400, 300} lockedRatio:ratio dimensionSwapEnabled:NO viewWidth:402];
            CGRect startFrame = cropView.cropBoxFrame;
            [self dragCropBoxOfCropView:cropView handle:handle by:-120 afterEachStep:nil];
            [self dragCropBoxOfCropView:cropView handle:handle by:120 afterEachStep:nil];

            CGRect frame = cropView.cropBoxFrame;
            BOOL grewBack = fabs(CGRectGetMinX(frame) - CGRectGetMinX(startFrame)) <= 1.0f && fabs(CGRectGetMinY(frame) - CGRectGetMinY(startFrame)) <= 1.0f &&
                            fabs(CGRectGetWidth(frame) - CGRectGetWidth(startFrame)) <= 1.0f && fabs(CGRectGetHeight(frame) - CGRectGetHeight(startFrame)) <= 1.0f;
            XCTAssertTrue(grewBack, @"At %@, shrinking from the %@ and dragging it back out left %@ instead of %@", NSStringFromCGSize(ratio),
                          kTOCropBoxHandleNames[handle], NSStringFromCGRect(frame), NSStringFromCGRect(startFrame));
        }
    }
}

- (void)testSettlingBoundsKeepAnUntouchedImageAtRest {
    // The first layout can run against insets that settle a fraction of a point later
    // (eg, the status bar finishing its hide a beat after presentation). Re-fitting the
    // whole-point resting layout to the new bounds scales it off its minimum zoom, so an
    // untouched image suddenly reads as a modified, resettable crop - it must be laid
    // out afresh instead, and still be at rest
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];

    TOCropRunWhileLandscapeLeadingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 678, 466};
        [controller.view layoutIfNeeded];
        XCTAssertFalse(controller.cropView.canBeReset, @"an untouched image must start at rest");

        controller.view.frame = (CGRect){0, 0, 678, 466.41666667};
        [controller.view setNeedsLayout];
        [controller.view layoutIfNeeded];

        XCTAssertEqual(controller.cropView.scrollView.zoomScale, controller.cropView.scrollView.minimumZoomScale,
                       @"an untouched image must stay fully zoomed out when the bounds settle");
        XCTAssertFalse(controller.cropView.canBeReset,
                       @"an untouched image must still be at rest after the bounds settle");
    });
}

- (void)testCommittedWholeImageRestoresAtRest {
    // Committing an image nobody touched reports the whole image as the crop, and
    // restoring that crop into a fresh controller must come back to the resting state,
    // not a crop a hair's breadth smaller that lights up the reset button
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];

    TOCropRunWhileLandscapeLeadingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 678, 466};
        [controller.view layoutIfNeeded];

        CGRect savedRect = controller.cropView.imageCropFrame;
        XCTAssertTrue(CGRectEqualToRect(savedRect, (CGRect){CGPointZero, {4032, 3024}}),
                      @"an untouched image must commit as the whole image, not %@", NSStringFromCGRect(savedRect));

        controller.cropView.imageCropFrame = savedRect;
        XCTAssertEqual(controller.cropView.scrollView.zoomScale, controller.cropView.scrollView.minimumZoomScale,
                       @"restoring a whole-image crop must land fully zoomed out");
        XCTAssertFalse(controller.cropView.canBeReset,
                       @"restoring a whole-image crop must come back to the resting state");
    });
}

- (void)testDismissalZoomAimsAtTheSettledDestinationFrame {
    // A full screen presentation detaches the presenting view, so the layout it carries at
    // dismissal can be stale (on a display with a camera gutter, turning 180° between the
    // landscapes mirrors the safe areas underneath it). The zoom-out has to aim at where
    // the destination view settles once a real layout pass runs, not where the stale
    // layout left it, or the committed image lands offset and snaps over at the end
    UIWindow *window = [[UIWindow alloc] initWithFrame:(CGRect){0, 0, 678, 466}];
    UIView *containerView = [[UIView alloc] initWithFrame:window.bounds];
    [window addSubview:containerView];

    TOCropTestRelayoutingPresenterView *presenterView = [[TOCropTestRelayoutingPresenterView alloc] initWithFrame:window.bounds];
    UIView *destinationView = [[UIView alloc] initWithFrame:(CGRect){{96, 102}, {408, 310}}];
    [presenterView addSubview:destinationView];
    presenterView.destinationView = destinationView;
    presenterView.settledDestinationFrame = (CGRect){{180, 102}, {408, 310}};

    UIViewController *presentingViewController = [[UIViewController alloc] init];
    presentingViewController.view = presenterView;

    TOCropTestDismissalContext *context = [[TOCropTestDismissalContext alloc] init];
    context.containerView = containerView;
    context.fromViewController = [[UIViewController alloc] init];
    context.toViewController = presentingViewController;
    context.toView = presenterView;

    TOCropViewControllerTransitioning *transitioning = [[TOCropViewControllerTransitioning alloc] init];
    transitioning.isDismissing = YES;
    transitioning.toView = destinationView;
    [transitioning animateTransition:context];

    XCTAssertTrue(CGRectEqualToRect(transitioning.toFrame, presenterView.settledDestinationFrame),
                  @"The zoom-out was aimed at %@ when the destination view settles at %@",
                  NSStringFromCGRect(transitioning.toFrame), NSStringFromCGRect(presenterView.settledDestinationFrame));
}

- (void)testProgrammaticCropAfterSetupSurvivesALayoutPass {
    // A crop applied through imageCropFrame once the controller has laid out must stay
    // applied through a later layout pass rather than snapping back to the whole image
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){400, 300}]];
    controller.view.frame = (CGRect){0, 0, 402, 874};
    [controller.view layoutIfNeeded];
    XCTAssertFalse(controller.cropView.canBeReset, @"precondition: an untouched image starts at rest");

    controller.imageCropFrame = (CGRect){{100, 75}, {200, 150}};
    CGRect applied = controller.imageCropFrame;
    XCTAssertLessThan(CGRectGetWidth(applied), 300.0, @"precondition: the crop was applied, got %@", NSStringFromCGRect(applied));

    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];

    CGRect afterLayout = controller.imageCropFrame;
    XCTAssertEqualWithAccuracy(CGRectGetWidth(afterLayout), CGRectGetWidth(applied), 2.0,
                               @"a layout pass discarded the programmatic crop: %@ became %@",
                               NSStringFromCGRect(applied), NSStringFromCGRect(afterLayout));
    XCTAssertEqualWithAccuracy(CGRectGetMinX(afterLayout), CGRectGetMinX(applied), 2.0,
                               @"a layout pass moved the programmatic crop: %@ became %@",
                               NSStringFromCGRect(applied), NSStringFromCGRect(afterLayout));
}

- (void)testProgrammaticCropAfterSetupIsResettable {
    // A crop applied through imageCropFrame once the controller has laid out is not the
    // resting state, so Reset must be available for it
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){400, 300}]];
    controller.view.frame = (CGRect){0, 0, 402, 874};
    [controller.view layoutIfNeeded];

    controller.imageCropFrame = (CGRect){{100, 75}, {200, 150}};
    XCTAssertTrue(controller.cropView.canBeReset, @"a programmatically applied crop must be resettable");
}

- (void)testTapRecentreOnAnUntouchedImageStaysAtRestThroughLayout {
    // A tap on the image starts the reset timer, whose recentre re-fits even an untouched
    // image by a fraction of a point inside fractional content bounds; the next layout
    // pass must still treat the image as untouched rather than lighting Reset
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];

    TOCropRunWhileLandscapeLeadingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 678, 466.41666667};
        [controller.view layoutIfNeeded];
        XCTAssertFalse(controller.cropView.canBeReset, @"precondition: an untouched image starts at rest");

        CGRect restingBox = controller.cropView.cropBoxFrame;
        [controller.cropView moveCroppedContentToCenterAnimated:NO];
        XCTAssertTrue(CGRectEqualToRect(controller.cropView.cropBoxFrame, restingBox),
                      @"the recentre after a tap must not re-fit an untouched image (%@ became %@)",
                      NSStringFromCGRect(restingBox), NSStringFromCGRect(controller.cropView.cropBoxFrame));

        [controller.view setNeedsLayout];
        [controller.view layoutIfNeeded];
        XCTAssertFalse(controller.cropView.canBeReset, @"a tap must not leave an untouched image resettable after layout");
    });
}

- (void)testUntouchedPortraitCommitIsTheWholeImageWithFractionalInsets {
    // Inside the cover display's fractional content bounds, Done on an untouched photo must
    // still commit the whole image, not one a few pixels narrower
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];

    TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 466, 678};
        [controller.view layoutIfNeeded];
        CGRect committed = controller.cropView.imageCropFrame;
        XCTAssertTrue(CGRectEqualToRect(committed, (CGRect){CGPointZero, {4032, 3024}}),
                      @"an untouched photo must commit whole, not %@ (box %@)",
                      NSStringFromCGRect(committed), NSStringFromCGRect(controller.cropView.cropBoxFrame));
    });
}

- (void)testNinetyDegreeRoundTripLeavesAnUntouchedImageAtRestWithFractionalInsets {
    // Turning the image left and then back right changes nothing, so the reset button must
    // stay dim even inside the cover display's fractional content bounds
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];

    TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 466, 678};
        [controller.view layoutIfNeeded];
        CGRect restingBox = controller.cropView.cropBoxFrame;
        [controller.cropView rotateImageNinetyDegreesAnimated:NO clockwise:NO completion:nil];
        [controller.cropView rotateImageNinetyDegreesAnimated:NO clockwise:YES completion:nil];
        XCTAssertFalse(controller.cropView.canBeReset,
                       @"rotating left then right must leave an untouched image at rest (box %@, resting %@)",
                       NSStringFromCGRect(controller.cropView.cropBoxFrame), NSStringFromCGRect(restingBox));
    });
}

- (void)testLockedSquarePresetHoldsSteadyAcrossLayoutPassesWithFractionalInsets {
    // A locked square crop must come to rest and stay there: repeated layout passes inside
    // fractional content bounds must not keep growing or distorting it
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];

    TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 466, 678};
        [controller.view layoutIfNeeded];
        controller.aspectRatioLockEnabled = YES;
        [controller setAspectRatioPreset:(CGSize){1, 1} animated:NO];
        [controller.view setNeedsLayout];
        [controller.view layoutIfNeeded];

        CGRect settled = controller.cropView.cropBoxFrame;
        for (NSInteger pass = 0; pass < 5; pass++) {
            [controller.view setNeedsLayout];
            [controller.view layoutIfNeeded];
        }
        CGRect after = controller.cropView.cropBoxFrame;
        XCTAssertTrue(CGRectEqualToRect(settled, after), @"layout passes moved the square crop box from %@ to %@",
                      NSStringFromCGRect(settled), NSStringFromCGRect(after));
        XCTAssertEqual(CGRectGetWidth(after), CGRectGetHeight(after), @"a square preset must stay square, got %@",
                       NSStringFromCGRect(after));
    });
}

// A square crop locked on a landscape photo, in a view wide enough to leave the box room to
// move sideways over the image, where resetting keeps the ratio
- (TOCropView *)lockedSquareCropViewWithRoomToMove {
    return [self cropViewLaidOutLikeTheControllerWithImage:[self testImageWithSize:(CGSize){4032, 3024}]
                                                     frame:(CGRect){0, 0, 874, 402}
                                             configuration:^(TOCropView *cropView) {
                                                 cropView.aspectRatioLockEnabled = YES;
                                                 cropView.resetAspectRatioEnabled = NO;
                                                 cropView.aspectRatio = (CGSize){1, 1};
                                             }];
}

// Drags the crop box's left edge in, then its right edge back out by the same distance, which
// leaves the box the size it started at, but framing a part of the image further right
- (void)moveCropBoxOfCropViewRight:(TOCropView *)cropView by:(CGFloat)distance {
    [cropView startEditing];
    [self dragCropBoxOfCropView:cropView handle:7 by:-distance afterEachStep:nil];
    [self dragCropBoxOfCropView:cropView handle:3 by:distance afterEachStep:nil];
}

- (void)testWholeImageCropUnderAPresetSurvivesALayoutPass {
    // Under a 16:9 preset, a crop of the whole image is no longer the preset's resting layout,
    // so a later layout pass must carry the crop across rather than lay the band back out
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];
    controller.view.frame = (CGRect){0, 0, 402, 874};
    [controller.view layoutIfNeeded];
    [controller setAspectRatioPreset:(CGSize){16, 9} animated:NO];
    XCTAssertLessThan(CGRectGetHeight(controller.imageCropFrame), 2900.0, @"precondition: the preset cropped to a band, got %@",
                      NSStringFromCGRect(controller.imageCropFrame));

    controller.imageCropFrame = (CGRect){CGPointZero, {4032, 3024}};
    XCTAssertEqualWithAccuracy(CGRectGetHeight(controller.imageCropFrame), 3024.0, 16.0, @"precondition: the whole image was applied, got %@",
                               NSStringFromCGRect(controller.imageCropFrame));

    [controller.view setNeedsLayout];
    [controller.view layoutIfNeeded];
    CGRect crop = controller.imageCropFrame;
    XCTAssertEqualWithAccuracy(CGRectGetWidth(crop), 4032.0, 16.0, @"a layout pass changed the whole-image crop to %@", NSStringFromCGRect(crop));
    XCTAssertEqualWithAccuracy(CGRectGetHeight(crop), 3024.0, 16.0, @"a layout pass turned the whole-image crop back into the preset's band, %@",
                               NSStringFromCGRect(crop));
}

- (void)testWholeImageRestoredWithAPresetSurvivesAppearing {
    // A host restoring a whole-image crop alongside a 16:9 preset: the preset is applied as the
    // controller appears, and the layout pass inside its appearance must keep the restored crop
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];
    controller.aspectRatioPreset = (CGSize){16, 9};
    controller.imageCropFrame = (CGRect){CGPointZero, {4032, 3024}};

    TOCropRunWhilePortraitTrailingEdgeHasCameraGutter(^{
        [controller beginAppearanceTransition:YES animated:NO];
        controller.view.frame = (CGRect){0, 0, 466, 678};
        [controller.view layoutIfNeeded];
        XCTAssertEqualWithAccuracy(CGRectGetHeight(controller.imageCropFrame), 3024.0, 16.0, @"precondition: the whole image was restored, got %@",
                                   NSStringFromCGRect(controller.imageCropFrame));

        [controller endAppearanceTransition];
        CGRect crop = controller.imageCropFrame;
        XCTAssertEqualWithAccuracy(CGRectGetWidth(crop), 4032.0, 16.0, @"appearing changed the restored crop to %@", NSStringFromCGRect(crop));
        XCTAssertEqualWithAccuracy(CGRectGetHeight(crop), 3024.0, 16.0, @"appearing turned the restored crop back into the preset's band, %@",
                                   NSStringFromCGRect(crop));
    });
}

- (void)testWholeImageCropUnderAPresetSurvivesDeviceRotation {
    // The same whole-image crop under a 16:9 preset, carried through the device rotation dance
    TOCropView *cropView = [[TOCropView alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];
    cropView.frame = (CGRect){0, 0, 320, 480};
    [cropView performInitialSetup];
    [cropView setAspectRatio:(CGSize){16, 9} animated:NO];
    cropView.imageCropFrame = (CGRect){CGPointZero, {4032, 3024}};
    XCTAssertEqualWithAccuracy(CGRectGetHeight(cropView.imageCropFrame), 3024.0, 16.0, @"precondition: the whole image was applied, got %@",
                               NSStringFromCGRect(cropView.imageCropFrame));

    for (NSInteger i = 0; i < 2; i++) {
        [cropView prepareforRotation];
        cropView.frame = (i % 2 == 0) ? (CGRect){0, 0, 480, 320} : (CGRect){0, 0, 320, 480};
        [cropView performRelayoutForRotation];

        CGRect crop = cropView.imageCropFrame;
        XCTAssertEqualWithAccuracy(CGRectGetWidth(crop), 4032.0, 16.0, @"rotation %ld changed the whole-image crop to %@", (long)i,
                                   NSStringFromCGRect(crop));
        XCTAssertEqualWithAccuracy(CGRectGetHeight(crop), 3024.0, 16.0, @"rotation %ld turned the whole-image crop back into the preset's band, %@",
                                   (long)i, NSStringFromCGRect(crop));
    }
}

- (void)testCropMovedAcrossTheImageSurvivesALayoutPass {
    // Dragging one edge of a locked box in and the opposite one back out moves the crop across the
    // image without changing the box's size. Once the box re-centres, a later layout pass must
    // carry that crop across rather than lay the resting layout back out over it
    TOCropView *cropView = [self lockedSquareCropViewWithRoomToMove];
    CGRect restingCrop = cropView.imageCropFrame;
    [self moveCropBoxOfCropViewRight:cropView by:20.0f];
    [cropView setEditing:NO resetCropBox:YES animated:NO];
    CGRect movedCrop = cropView.imageCropFrame;
    XCTAssertGreaterThan(CGRectGetMinX(movedCrop), CGRectGetMinX(restingCrop) + 100.0f, @"precondition: the crop moved right, from %@ to %@",
                         NSStringFromCGRect(restingCrop), NSStringFromCGRect(movedCrop));

    cropView.frame = (CGRect){0, 0, 874, 410};
    [cropView performRelayoutForBoundsChange];
    CGRect crop = cropView.imageCropFrame;
    XCTAssertEqualWithAccuracy(CGRectGetMinX(crop), CGRectGetMinX(movedCrop), 16.0, @"a layout pass moved the crop from %@ to %@",
                               NSStringFromCGRect(movedCrop), NSStringFromCGRect(crop));
}

- (void)testCropMovedAcrossTheImageSurvivesALayoutPassBeforeItRecentres {
    // A layout pass can also land between the drag ending and the box re-centring, while the box
    // still sits off to the side of where it rests
    TOCropView *cropView = [self lockedSquareCropViewWithRoomToMove];
    CGRect restingCrop = cropView.imageCropFrame;
    [self moveCropBoxOfCropViewRight:cropView by:20.0f];
    CGRect movedCrop = cropView.imageCropFrame;
    XCTAssertGreaterThan(CGRectGetMinX(movedCrop), CGRectGetMinX(restingCrop) + 100.0f, @"precondition: the crop moved right, from %@ to %@",
                         NSStringFromCGRect(restingCrop), NSStringFromCGRect(movedCrop));

    [cropView performRelayoutForBoundsChange];
    CGRect crop = cropView.imageCropFrame;
    XCTAssertEqualWithAccuracy(CGRectGetMinX(crop), CGRectGetMinX(movedCrop), 16.0, @"a layout pass moved the crop from %@ to %@",
                               NSStringFromCGRect(movedCrop), NSStringFromCGRect(crop));
}

- (void)testCropMovedAcrossTheImageSurvivesDeviceRotation {
    // The same moved crop, carried through the device rotation dance
    TOCropView *cropView = [self lockedSquareCropViewWithRoomToMove];
    CGRect restingCrop = cropView.imageCropFrame;
    [self moveCropBoxOfCropViewRight:cropView by:20.0f];
    [cropView setEditing:NO resetCropBox:YES animated:NO];
    CGRect movedCrop = cropView.imageCropFrame;
    XCTAssertGreaterThan(CGRectGetMinX(movedCrop), CGRectGetMinX(restingCrop) + 100.0f, @"precondition: the crop moved right, from %@ to %@",
                         NSStringFromCGRect(restingCrop), NSStringFromCGRect(movedCrop));

    [cropView prepareforRotation];
    cropView.frame = (CGRect){0, 0, 402, 874};
    [cropView performRelayoutForRotation];
    CGRect crop = cropView.imageCropFrame;
    XCTAssertEqualWithAccuracy(CGRectGetMidX(crop), CGRectGetMidX(movedCrop), 16.0, @"rotating moved the crop from %@ to %@",
                               NSStringFromCGRect(movedCrop), NSStringFromCGRect(crop));
}

- (void)testCropMovedAcrossTheImageIsResettable {
    // The moved crop's box is the size it started at, but it frames a different part of the
    // image, so once the box re-centres there is something for Reset to put back
    TOCropView *cropView = [self lockedSquareCropViewWithRoomToMove];
    XCTAssertFalse(cropView.canBeReset, @"precondition: an untouched crop starts at rest");
    [self moveCropBoxOfCropViewRight:cropView by:20.0f];
    [cropView setEditing:NO resetCropBox:YES animated:NO];
    XCTAssertTrue(cropView.canBeReset, @"a crop moved across the image must be resettable, crop %@", NSStringFromCGRect(cropView.imageCropFrame));
}

- (void)testLayoutPassesLeaveTheCropAloneWhileInternalLayoutIsDisabled {
    // While the controller lays the crop view out itself (eg, through a device rotation), the
    // ordinary layout passes in between must leave it alone, untouched image or not
    TOCropView *cropView = [self cropViewLaidOutLikeTheControllerWithImage:[self testImageWithSize:(CGSize){4032, 3024}]
                                                                     frame:(CGRect){0, 0, 402, 874}];
    XCTAssertFalse(cropView.canBeReset, @"precondition: an untouched image starts at rest");
    CGRect cropBoxFrame = cropView.cropBoxFrame;

    cropView.internalLayoutDisabled = YES;
    cropView.frame = (CGRect){0, 0, 874, 402};
    [cropView performRelayoutForBoundsChange];
    XCTAssertTrue(CGRectEqualToRect(cropView.cropBoxFrame, cropBoxFrame), @"a layout pass moved the crop box from %@ to %@ while internal layout was disabled",
                  NSStringFromCGRect(cropBoxFrame), NSStringFromCGRect(cropView.cropBoxFrame));
}

- (void)testTapOnAnUntouchedLockedBandLeavesItAtRest {
    // A tap re-centres the crop box once the reset timer fires. On a ratio band nobody has
    // touched, that must leave it exactly where the initial layout put it, with nothing to
    // reset, or the band falls off the fresh layout on every later layout pass
    for (NSValue *ratioValue in @[ [NSValue valueWithCGSize:(CGSize){16, 9}], [NSValue valueWithCGSize:(CGSize){1, 1}],
                                   [NSValue valueWithCGSize:(CGSize){3, 4}] ]) {
        for (CGFloat width = 380.0f; width <= 440.0f; width += 3.0f) {
            TOCropView *cropView = [self cropViewLaidOutLikeTheControllerWithImage:[self testImageWithSize:(CGSize){4032, 3024}]
                                                                             frame:(CGRect){0, 0, width, 874}
                                                                     configuration:^(TOCropView *cropView) {
                                                                         cropView.resetAspectRatioEnabled = NO;
                                                                         cropView.aspectRatio = ratioValue.CGSizeValue;
                                                                     }];
            CGRect restingBox = cropView.cropBoxFrame;
            [cropView startEditing];
            [cropView setEditing:NO resetCropBox:YES animated:NO];
            XCTAssertTrue(CGRectEqualToRect(cropView.cropBoxFrame, restingBox), @"a tap moved the %@ band from %@ to %@ in a %.0fpt wide view",
                          NSStringFromCGSize(ratioValue.CGSizeValue), NSStringFromCGRect(restingBox), NSStringFromCGRect(cropView.cropBoxFrame), width);
            XCTAssertFalse(cropView.canBeReset, @"a tap left the untouched %@ band resettable in a %.0fpt wide view",
                           NSStringFromCGSize(ratioValue.CGSizeValue), width);
        }
    }
}

- (void)testRotatingAZeroSizedCircularImageDoesNotCrash {
    // A circular crop view starts with a square ratio, but an empty image never gets an initial
    // layout, so there's no crop box for a rotation to rescale
    TOCropView *cropView = [[TOCropView alloc] initWithCroppingStyle:TOCropViewCroppingStyleCircular image:[UIImage new]];
    cropView.frame = (CGRect){0, 0, 320, 480};
    [cropView performInitialSetup];
    [cropView prepareforRotation];
    cropView.frame = (CGRect){0, 0, 480, 320};
    [cropView performRelayoutForRotation];
    XCTAssertFalse(isnan(cropView.scrollView.zoomScale) || isinf(cropView.scrollView.minimumZoomScale),
                   @"rotating an empty image produced zoom %f (minimum %f)", cropView.scrollView.zoomScale, cropView.scrollView.minimumZoomScale);
}

- (void)testRestoredWholeImageStaysAtRestThroughSettlingBounds {
    // A whole-image crop restored into the controller is the resting layout itself, so when the
    // bounds then settle it must still come back fully zoomed out, whole and untouched
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:[self testImageWithSize:(CGSize){4032, 3024}]];

    TOCropRunWhileLandscapeLeadingEdgeHasCameraGutter(^{
        controller.view.frame = (CGRect){0, 0, 678, 466};
        [controller.view layoutIfNeeded];
        controller.cropView.imageCropFrame = (CGRect){CGPointZero, {4032, 3024}};

        controller.view.frame = (CGRect){0, 0, 678, 466.41666667};
        [controller.view setNeedsLayout];
        [controller.view layoutIfNeeded];
        XCTAssertEqual(controller.cropView.scrollView.zoomScale, controller.cropView.scrollView.minimumZoomScale,
                       @"a restored whole image must stay fully zoomed out when the bounds settle");
        XCTAssertFalse(controller.cropView.canBeReset, @"a restored whole image must still be at rest after the bounds settle");
        XCTAssertTrue(CGRectEqualToRect(controller.cropView.imageCropFrame, (CGRect){CGPointZero, {4032, 3024}}),
                      @"a restored whole image must still commit whole, not %@", NSStringFromCGRect(controller.cropView.imageCropFrame));
    });
}

@end
