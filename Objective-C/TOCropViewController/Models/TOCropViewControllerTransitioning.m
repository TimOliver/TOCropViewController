//
//  TOCropViewControllerTransitioning.m
//
//  Copyright 2015-2026 Timothy Oliver. All rights reserved.
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

#import "TOCropViewControllerTransitioning.h"

#import <QuartzCore/QuartzCore.h>

@interface TOCropViewControllerTransitioning ()

@property (nonatomic, strong, nullable) UIImageView *imageView;      // The image as it flies to the destination view
@property (nonatomic, strong, nullable) CADisplayLink *displayLink;  // Keeps an eye on the destination view while it does
@property (nonatomic, assign) CFTimeInterval landingTime;            // When the image is due to land

@end

@implementation TOCropViewControllerTransitioning

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.45f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // Get the master view where the animation takes place
    UIView *containerView = [transitionContext containerView];

    // Get the origin/destination view controllers
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    // Work out which one is the crop view controller
    UIViewController *cropViewController = (self.isDismissing == NO) ? toViewController : fromViewController;

    // Full screen presentations take the presenting view out of the window, so on the way
    // out UIKit hands it back to be restored. Any other presentation (eg, from a sheet, or
    // over full screen) leaves it where it was, and moving it into the container would see
    // it torn down along with the container once the transition completes.
    UIView *previousView = nil;
    if (self.isDismissing) {
        previousView = [transitionContext viewForKey:UITransitionContextToViewKey];
    }

    // Just in case, match up the frame sizes
    cropViewController.view.frame = containerView.bounds;
    previousView.frame = containerView.bounds;

    // Add the view layers beforehand as this will trigger the initial sets of layouts
    if (self.isDismissing == NO) {
        [containerView addSubview:cropViewController.view];

        // Force a relayout now that the view is in the view hierarchy (so things like the safe area insets are now valid)]
        [cropViewController.view setNeedsLayout];
        [cropViewController.view layoutIfNeeded];
        [cropViewController viewDidLayoutSubviews];
    } else if (previousView) {
        [containerView insertSubview:previousView belowSubview:cropViewController.view];

        // Match the presentation: settle this view's layout now that it is back in the
        // hierarchy. Its safe area insets can have changed while it was detached (on a
        // display with a camera gutter, turning 180° between the landscapes mirrors them),
        // and the fresh values only finish propagating in the window's own layout pass, so
        // run one before any destination frames are measured out of this view
        [previousView setNeedsLayout];
        [containerView.window layoutIfNeeded];
    }

    // Perform any last UI updates now so we can potentially factor them into our calculations, but after
    // the container views have been set up
    if (self.prepareForTransitionHandler) {
        self.prepareForTransitionHandler();
    }

    // If origin/destination views were supplied, use them to supplant the
    // frames
    if (!self.isDismissing && self.fromView) {
        self.fromFrame = [self.fromView.superview convertRect:self.fromView.frame toView:containerView];
    } else if (self.isDismissing && self.toView) {
        self.toFrame = [self.toView.superview convertRect:self.toView.frame toView:containerView];
    }

    UIImageView *imageView = nil;
    if ((self.isDismissing && !CGRectIsEmpty(self.toFrame)) || (!self.isDismissing && !CGRectIsEmpty(self.fromFrame))) {
        imageView = [[UIImageView alloc] initWithImage:self.image];
        imageView.frame = self.fromFrame;
        imageView.accessibilityIgnoresInvertColors = YES;
        [containerView addSubview:imageView];
    }

    cropViewController.view.alpha = (self.isDismissing ? 1.0f : 0.0f);
    if (imageView) {
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
            delay:0.0f
            usingSpringWithDamping:1.0f
            initialSpringVelocity:0.7f
            options:0
            animations:^{
                imageView.frame = self.toFrame;
            }
            completion:^(BOOL complete) {
                [self stopFollowingDestinationView];
                [UIView animateWithDuration:0.25f
                    animations:^{
                        imageView.alpha = 0.0f;
                    }
                    completion:^(BOOL complete) {
                        [imageView removeFromSuperview];
                    }];
            }];

        // The destination view can still move while the image is on its way, such as when a status bar
        // hidden while cropping comes back and moves the safe area it's laid out in (on iPhones without a
        // notch, the safe area only catches up a moment after the dismissal starts), so follow it there
        if (self.isDismissing && self.toView) {
            [self followDestinationViewWithImageView:imageView landingTime:CACurrentMediaTime() + [self transitionDuration:transitionContext]];
        }
    }

    [UIView animateWithDuration:[self transitionDuration:transitionContext]
        animations:^{
            cropViewController.view.alpha = (self.isDismissing ? 0.0f : 1.0f);
        }
        completion:^(BOOL complete) {
            [self reset];
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
}

- (void)followDestinationViewWithImageView:(UIImageView *)imageView landingTime:(CFTimeInterval)landingTime {
    self.imageView = imageView;
    self.landingTime = landingTime;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(destinationViewDisplayLinkFired)];
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)destinationViewDisplayLinkFired {
    UIView *containerView = self.imageView.superview;
    CFTimeInterval timeLeft = self.landingTime - CACurrentMediaTime();
    if (self.toView.superview == nil || containerView == nil || timeLeft <= 0.0f) {
        [self stopFollowingDestinationView];
        return;
    }

    CGRect toFrame = [self.toView.superview convertRect:self.toView.frame toView:containerView];
    if (CGRectEqualToRect(toFrame, self.toFrame)) {
        return;
    }

    // Steer the image to where the view is now, landing at the same time it was going to. This adds to
    // the animation already under way rather than replacing it, so the image carries on smoothly
    self.toFrame = toFrame;
    UIImageView *imageView = self.imageView;
    [UIView animateWithDuration:timeLeft
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.0f
                        options:0
                     animations:^{
                         imageView.frame = toFrame;
                     }
                     completion:nil];
}

- (void)stopFollowingDestinationView {
    [self.displayLink invalidate];
    self.displayLink = nil;
    self.imageView = nil;
}

- (void)reset {
    self.image = nil;
    self.toView = nil;
    self.fromView = nil;
    self.fromFrame = CGRectZero;
    self.toFrame = CGRectZero;
    self.prepareForTransitionHandler = nil;
    [self stopFollowingDestinationView];
}

@end
