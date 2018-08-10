//
//  TOCropViewControllerTransitioning.m
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

#import "TOCropViewControllerTransitioning.h"
#import <QuartzCore/QuartzCore.h>

@implementation TOCropViewControllerTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.45f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Get the master view where the animation takes place
    UIView *containerView = [transitionContext containerView];
    
    // Get the origin/destination view controllers
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    // Work out which one is the crop view controller
    UIViewController *cropViewController = (self.isDismissing == NO) ? toViewController : fromViewController;
    UIViewController *previousController = (self.isDismissing == NO) ? fromViewController : toViewController;
    
    // Just in case, match up the frame sizes
    cropViewController.view.frame = containerView.bounds;
    if (self.isDismissing) {
        previousController.view.frame = containerView.bounds;
    }
    
    // Add the view layers beforehand as this will trigger the initial sets of layouts
    if (self.isDismissing == NO) {
        [containerView addSubview:cropViewController.view];

        //Force a relayout now that the view is in the view hierarchy (so things like the safe area insets are now valid)
        [cropViewController viewDidLayoutSubviews];
    }
    else {
        [containerView insertSubview:previousController.view belowSubview:cropViewController.view];
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
    }
    else if (self.isDismissing && self.toView) {
        self.toFrame = [self.toView.superview convertRect:self.toView.frame toView:containerView];
    }
        
    UIImageView *imageView = nil;
    if ((self.isDismissing && !CGRectIsEmpty(self.toFrame)) || (!self.isDismissing && !CGRectIsEmpty(self.fromFrame))) {
        imageView = [[UIImageView alloc] initWithImage:self.image];
        imageView.frame = self.fromFrame;
        [containerView addSubview:imageView];
        
        if (@available(iOS 11.0, *)) {
            imageView.accessibilityIgnoresInvertColors = YES;
        }
    }
    
    cropViewController.view.alpha = (self.isDismissing ? 1.0f : 0.0f);
    if (imageView) {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.7f options:0 animations:^{
            imageView.frame = self.toFrame;
        } completion:^(BOOL complete) {
            [UIView animateWithDuration:0.25f animations:^{
                imageView.alpha = 0.0f;
            }completion:^(BOOL complete) {
                [imageView removeFromSuperview];
            }];
        }];
    }
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        cropViewController.view.alpha = (self.isDismissing ? 0.0f : 1.0f);
    } completion:^(BOOL complete) {
        [self reset];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

- (void)reset
{
    self.image = nil;
    self.toView = nil;
    self.fromView = nil;
    self.fromFrame = CGRectZero;
    self.toFrame = CGRectZero;
    self.prepareForTransitionHandler = nil;
}

@end
