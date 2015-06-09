//
//  TOCropViewControllerTransitioning.m
//  TOCropViewControllerExample
//
//  Created by Tim Oliver on 6/1/15.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import "TOCropViewControllerTransitioning.h"
#import <QuartzCore/QuartzCore.h>

@implementation TOCropViewControllerTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.4f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIView *containerView = [transitionContext containerView];
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIViewController *cropViewController = (self.isDismissing == NO) ? toViewController : fromViewController;
    UIViewController *previousController = (self.isDismissing == NO) ? fromViewController : toViewController;
    
    UIImageView *imageView = nil;
    if ((self.isDismissing && !CGRectIsEmpty(self.toFrame)) || (!self.isDismissing && !CGRectIsEmpty(self.fromFrame))) {
        imageView = [[UIImageView alloc] initWithImage:self.image];
        imageView.frame = self.fromFrame;
        [containerView addSubview:imageView];
    }
    
    if (self.isDismissing == NO) {
        [containerView addSubview:cropViewController.view];
        [containerView bringSubviewToFront:imageView];
    }
    else {
        [containerView insertSubview:previousController.view belowSubview:cropViewController.view];
    }
    
    if (self.prepareForTransitionHandler)
        self.prepareForTransitionHandler();
    
    cropViewController.view.alpha = (self.isDismissing ? 1.0f : 0.0f);
    
    id animationBlock = ^{
        cropViewController.view.alpha = (self.isDismissing ? 0.0f : 1.0f);
        imageView.frame = self.toFrame;
    };
    
    id animationCompleteBlock = ^(BOOL completed) {
        [imageView removeFromSuperview];
        [self reset];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    };
    
    if (imageView == nil)
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:animationBlock completion:animationCompleteBlock];
    else
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.7f options:0 animations:animationBlock completion:animationCompleteBlock];
}

- (void)reset
{
    self.image = nil;
    self.fromFrame = CGRectZero;
    self.toFrame = CGRectZero;
    self.prepareForTransitionHandler = nil;
}

@end
