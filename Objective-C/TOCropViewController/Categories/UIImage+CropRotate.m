//
//  UIImage+CropRotate.m
//
//  Copyright 2015-2024 Timothy Oliver. All rights reserved.
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

#import "UIImage+CropRotate.h"

@implementation UIImage (CropRotate)

- (BOOL)hasAlpha
{
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(self.CGImage);
    return (alphaInfo == kCGImageAlphaFirst || alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst || alphaInfo == kCGImageAlphaPremultipliedLast);
}

- (UIImage *)croppedImageWithFrame:(CGRect)frame angle:(NSInteger)angle flippedHorizontally:(BOOL)flipped circularClip:(BOOL)circular
{
    UIImage *croppedImage = nil;
    UIGraphicsBeginImageContextWithOptions(frame.size, !self.hasAlpha && !circular, self.scale);
    {
        CGContextRef context = UIGraphicsGetCurrentContext();

        // If we're capturing a circular image, set the clip mask first
        if (circular) {
            CGContextAddEllipseInRect(context, (CGRect){CGPointZero, frame.size});
            CGContextClip(context);
        }

        // Offset the origin (Which is the top left corner) to start where our cropping origin is
        CGContextTranslateCTM(context, -frame.origin.x, -frame.origin.y);

        // If an angle was supplied, rotate the entire canvas + coordinate space to match
        if (angle != 0) {
            // Rotation in radians
            CGFloat rotation = angle * (M_PI/180.0f);

            // Work out the new bounding size of the canvas after rotation
            CGRect imageBounds = (CGRect){CGPointZero, self.size};
            CGRect rotatedBounds = CGRectApplyAffineTransform(imageBounds,
                                                              CGAffineTransformMakeRotation(rotation));
            // As we're rotating from the top left corner, and not the center of the canvas, the frame
            // will have rotated out of our visible canvas. Compensate for this.
            CGContextTranslateCTM(context, -rotatedBounds.origin.x, -rotatedBounds.origin.y);

            // Perform the rotation transformation
            CGContextRotateCTM(context, rotation);
        }
        
        if (flipped)
        {
            CGContextScaleCTM(context, -1, 1);
            CGContextTranslateCTM(context, -self.size.width, 0);
        }
        
        // Draw the image with all of the transformation parameters applied.
        // We do not need to worry about specifying the size here since we're already
        // constrained by the context image size
        [self drawAtPoint:CGPointZero];
        
        croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();

    // Re-apply the retina scale we originally had
    return [UIImage imageWithCGImage:croppedImage.CGImage scale:self.scale orientation:UIImageOrientationUp];
}

@end
