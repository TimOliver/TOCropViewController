//
//  UIImage+CropRotate.m
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

#import "UIImage+CropRotate.h"

@implementation UIImage (TOCropRotate)

- (BOOL)hasAlpha {
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(self.CGImage);
    return (alphaInfo == kCGImageAlphaFirst || alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst || alphaInfo == kCGImageAlphaPremultipliedLast);
}

// Draws the cropped region of the image into a context set up in UIKit's coordinate space,
// sized to the crop frame
static void TOCropDrawImageInContext(UIImage *image, CGContextRef context, CGRect frame, NSInteger angle, BOOL circular) {
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
        CGFloat rotation = angle * (M_PI / 180.0f);

        // Work out the new bounding size of the canvas after rotation
        CGRect imageBounds = (CGRect){CGPointZero, image.size};
        CGRect rotatedBounds = CGRectApplyAffineTransform(imageBounds,
                                                          CGAffineTransformMakeRotation(rotation));
        // As we're rotating from the top left corner, and not the center of the canvas, the frame
        // will have rotated out of our visible canvas. Compensate for this.
        CGContextTranslateCTM(context, -rotatedBounds.origin.x, -rotatedBounds.origin.y);

        // Perform the rotation transformation
        CGContextRotateCTM(context, rotation);
    }

    // Draw the image with all of the transformation parameters applied.
    // We do not need to worry about specifying the size here since we're already
    // constrained by the context image size
    [image drawAtPoint:CGPointZero];
}

// A crop that's upright and neither rotated nor clipped can simply be cut out of the image,
// sharing its pixels instead of copying them into a new bitmap
static UIImage *TOCropImageByCuttingOutFrame(UIImage *image, CGRect frame) {
    CGImageRef sourceImage = image.CGImage;
    if (sourceImage == NULL || image.imageOrientation != UIImageOrientationUp) {
        return nil;
    }

    // Only cut out whole pixels lying inside the image, which is what drawing would produce
    CGRect pixelFrame = (CGRect){{frame.origin.x * image.scale, frame.origin.y * image.scale},
                                 {frame.size.width * image.scale, frame.size.height * image.scale}};
    CGRect imageBounds = (CGRect){CGPointZero, {CGImageGetWidth(sourceImage), CGImageGetHeight(sourceImage)}};
    if (!CGRectEqualToRect(pixelFrame, CGRectIntegral(pixelFrame)) || !CGRectContainsRect(imageBounds, pixelFrame)) {
        return nil;
    }

    CGImageRef croppedImage = CGImageCreateWithImageInRect(sourceImage, pixelFrame);
    if (croppedImage == NULL) {
        return nil;
    }
    UIImage *result = [UIImage imageWithCGImage:croppedImage scale:image.scale orientation:UIImageOrientationUp];
    CGImageRelease(croppedImage);
    return result;
}

// Draws the crop into an 8-bit bitmap in the image's own color space. UIKit's renderer would
// switch to 16 bits per channel for a wide color photo (doubling the memory a large crop takes),
// and its 8-bit option is sRGB, which would clip the photo's most saturated colors.
static UIImage *TOCropImageByDrawingIntoBitmap(UIImage *image, CGRect frame, NSInteger angle, BOOL circular, BOOL opaque) {
    CGImageRef sourceImage = image.CGImage;
    if (sourceImage == NULL || CGImageGetBitsPerComponent(sourceImage) > 8) {
        return nil;
    }

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(sourceImage);
    if (colorSpace == NULL || CGColorSpaceGetModel(colorSpace) != kCGColorSpaceModelRGB || !CGColorSpaceSupportsOutput(colorSpace)) {
        return nil;
    }

    size_t width = (size_t)ceil(frame.size.width * image.scale);
    size_t height = (size_t)ceil(frame.size.height * image.scale);
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, bitmapInfo);
    if (context == NULL) {
        return nil;
    }

    // Flip into UIKit's top-left origin, in the image's points
    CGContextTranslateCTM(context, 0.0f, height);
    CGContextScaleCTM(context, image.scale, -image.scale);

    UIGraphicsPushContext(context);
    TOCropDrawImageInContext(image, context, frame, angle, circular);
    UIGraphicsPopContext();

    CGImageRef croppedImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    if (croppedImage == NULL) {
        return nil;
    }
    UIImage *result = [UIImage imageWithCGImage:croppedImage scale:image.scale orientation:UIImageOrientationUp];
    CGImageRelease(croppedImage);
    return result;
}

- (UIImage *)croppedImageWithFrame:(CGRect)frame angle:(NSInteger)angle circularClip:(BOOL)circular {
    BOOL opaque = !self.hasAlpha && !circular;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat new];
    BOOL highDynamicRange = NO;

#if defined(__IPHONE_17_0)
    // When the source image is HDR, request an HDR-capable rendering format so its
    // highlights aren't silently tone-mapped down to SDR. Falls back to the default
    // format wherever HDR rendering isn't supported.
    if (@available(iOS 17.0, *)) {
        if (self.isHighDynamicRange) {
            UITraitCollection *hdrTraits = [UITraitCollection traitCollectionWithImageDynamicRange:UIImageDynamicRangeHigh];
            UIGraphicsImageRendererFormat *hdrFormat = [UIGraphicsImageRendererFormat formatForTraitCollection:hdrTraits];
            if (hdrFormat.supportsHighDynamicRange) {
                format = hdrFormat;
                highDynamicRange = YES;
            }
        }
    }
#endif

    // Standard dynamic range images avoid rendering through UIKit where they can, keeping
    // the crop in the same compact format as the image it came from
    if (!highDynamicRange) {
        UIImage *croppedImage = nil;
        if (angle == 0 && !circular) {
            croppedImage = TOCropImageByCuttingOutFrame(self, frame);
        }
        if (croppedImage == nil) {
            croppedImage = TOCropImageByDrawingIntoBitmap(self, frame, angle, circular, opaque);
        }
        if (croppedImage) {
            return croppedImage;
        }
    }

    format.opaque = opaque;
    format.scale = self.scale;

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:frame.size format:format];
    UIImage *croppedImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        TOCropDrawImageInContext(self, rendererContext.CGContext, frame, angle, circular);
    }];

    // Re-apply the retina scale we originally had
    return [UIImage imageWithCGImage:croppedImage.CGImage scale:self.scale orientation:UIImageOrientationUp];
}

@end
