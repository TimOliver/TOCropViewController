//
//  TOActivityCroppedImageProvider.h
//  TOCropViewControllerExample
//
//  Created by Tim Oliver on 6/06/2015.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TOActivityCroppedImageProvider : UIActivityItemProvider

@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) CGRect cropFrame;
@property (nonatomic, readonly) NSInteger angle;

- (instancetype)initWithImage:(UIImage *)image cropFrame:(CGRect)cropFrame angle:(NSInteger)angle;

@end
