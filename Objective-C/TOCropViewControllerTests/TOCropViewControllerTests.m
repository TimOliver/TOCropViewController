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

- (void)testCropViewIsReleasedWithPendingResetTimer {
    __weak TOCropView *weakCropView = nil;
    @autoreleasepool {
        TOCropView *cropView = [self cropViewWithImageSize:(CGSize){40, 20}];
        [cropView startResetTimer];
        weakCropView = cropView;
    }
    XCTAssertNil(weakCropView);
}

- (void)testViewControllerInstance {
    // Create a basic image
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(10, 10)];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull context) {
        [context fillRect:CGRectMake(0, 0, 10, 10)];
    }];

    // Perform test
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:image];
    UIView *view = controller.view;
    XCTAssertNotNil(view);
}

@end
