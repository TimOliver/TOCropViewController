//
//  TOCropViewControllerTransitioning.h
//
//  Copyright 2015-2016 Timothy Oliver. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TOCropViewControllerTransitioning : NSObject <UIViewControllerAnimatedTransitioning>

/* State Tracking */
@property (nonatomic, assign) BOOL isDismissing; // Whether this animation is presenting or dismissing
@property (nullable, nonatomic, strong) UIImage *image;    // The image that will be used in this animation

/* Destination/Origin points */
@property (nullable, nonatomic, strong) UIView *fromView;  // The origin view who's frame the image will be animated from
@property (nullable, nonatomic, strong) UIView *toView;    // The destination view who's frame the image will animate to

@property (nonatomic, assign) CGRect fromFrame;  // An origin frame that the image will be animated from
@property (nonatomic, assign) CGRect toFrame;    // A destination frame the image will aniamte to

/* A block called just before the transition to perform any last-second UI configuration */
@property (nullable, nonatomic, copy) void (^prepareForTransitionHandler)(void);

/* Empties all of the properties in this object */
- (void)reset;

@end
