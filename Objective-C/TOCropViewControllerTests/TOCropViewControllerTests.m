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
// rotation, and drive the scroll view's touch hooks
@interface TOCropView (UnitTests)
- (void)startResetTimer;
@property (nonatomic, assign) BOOL rotateAnimationInProgress;
@property (nonatomic, strong, readonly) TOCropScrollView *scrollView;
@property (nonatomic, strong, readonly) NSTimer *resetTimer;
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

- (TOCropView *)cropViewWithImageSize:(CGSize)imageSize {
    TOCropView *cropView = [[TOCropView alloc] initWithImage:[self testImageWithSize:imageSize]];
    cropView.frame = (CGRect){0, 0, 320, 480};
    [cropView performInitialSetup];
    return cropView;
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

@end
