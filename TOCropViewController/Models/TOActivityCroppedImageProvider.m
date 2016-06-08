//
//  TOActivityCroppedImageProvider.m
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

#import "TOActivityCroppedImageProvider.h"
#import "UIImage+CropRotate.h"

@interface TOActivityCroppedImageProvider ()

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, assign, readwrite) CGRect cropFrame;
@property (nonatomic, assign, readwrite) NSInteger angle;
@property (nonatomic, assign, readwrite) BOOL circular;

@property (atomic, strong) UIImage *croppedImage;

@end

@implementation TOActivityCroppedImageProvider

- (instancetype)initWithImage:(UIImage *)image cropFrame:(CGRect)cropFrame angle:(NSInteger)angle circular:(BOOL)circular
{
    if (self = [super initWithPlaceholderItem:[UIImage new]]) {
        _image = image;
        _cropFrame = cropFrame;
        _angle = angle;
        _circular = circular;
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
    
    UIImage *image = [self.image croppedImageWithFrame:self.cropFrame angle:self.angle circularClip:self.circular];
    self.croppedImage = image;
    return self.croppedImage;
}

@end
