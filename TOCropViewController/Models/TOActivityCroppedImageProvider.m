//
//  TOActivityCroppedImageProvider.m
//  TOCropViewControllerExample
//
//  Created by Tim Oliver on 6/06/2015.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import "TOActivityCroppedImageProvider.h"
#import "UIImage+CropRotate.h"

@interface TOActivityCroppedImageProvider ()

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, assign, readwrite) CGRect cropFrame;
@property (nonatomic, assign, readwrite) NSInteger angle;

@property (atomic, strong) UIImage *croppedImage;

@end

@implementation TOActivityCroppedImageProvider

- (instancetype)initWithImage:(UIImage *)image cropFrame:(CGRect)cropFrame angle:(NSInteger)angle
{
    if (self = [super initWithPlaceholderItem:[UIImage new]]) {
        _image = image;
        _cropFrame = cropFrame;
        _angle = angle;
    }
    
    return self;
}

#pragma mark - UIActivity Protocols -
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return [[UIImage alloc] init];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    return self.croppedImage;
}

#pragma mark - Image Generation -
- (id)item
{
    //If the user didn't touch the image, just forward along the original
    if (self.angle == 0 && CGRectEqualToRect(self.cropFrame, (CGRect){CGPointZero, self.image.size})) {
        self.croppedImage = self.image;
        return self.croppedImage;
    }
    
    UIImage *image = [self.image croppedImageWithFrame:self.cropFrame angle:self.angle];
    self.croppedImage = image;
    return self.croppedImage;
}

@end
