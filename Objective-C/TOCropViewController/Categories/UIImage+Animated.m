//
//  UIImage+Animated.m
//
//  Copyright 2015-2020 Timothy Oliver. All rights reserved.
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

#import "UIImage+Animated.h"
#import "TOImageFrame.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation UIImage (Animated)

+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    NSTimeInterval frameDuration = 0.1;
    NSDictionary *options = @{
        (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(YES),
        (__bridge NSString *)kCGImageSourceShouldCache : @(YES) // Always cache to reduce CPU usage
    };
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)options);
    NSDictionary *frameProperties = (__bridge NSDictionary*)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString*)kCGImagePropertyGIFDictionary];
    
    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString*)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp doubleValue];
    } else {
        NSNumber *delayTimeProp = gifProperties[(NSString*)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp doubleValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    if (frameDuration < 0.011) {
        frameDuration = 0.1;
    }
    
    return frameDuration;
}


+ (nullable UIImage *)animatedImageFromData:(nullable NSData *)data {
    if (!data) {
        return nil;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    
    size_t count = CGImageSourceGetCount(source);
    
    // Decode as static image
    if (count <= 1) {
        return [[UIImage alloc] initWithData:data];
    } else {
        NSMutableArray<TOImageFrame *> *frames = [NSMutableArray array];
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, i, NULL);
            
            // Get image and duration
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            NSTimeInterval duration = [UIImage frameDurationAtIndex:i source:source];
            
            [frames addObject:[TOImageFrame frameWithImage:image duration:duration]];
            CGImageRelease(cgImage);
        }
        return [UIImage animatedImageFromFrames:frames];
    }
}

+ (nullable UIImage *)animatedImageFromFrames:(nullable NSArray<TOImageFrame *> *)frames {
    NSUInteger frameCount = frames.count;
    
    if (frameCount == 0) {
        return nil;
    }
    
    UIImage *animatedImage;
    NSUInteger durations[frameCount];
    for (size_t i = 0; i < frameCount; i++) {
        durations[i] = frames[i].duration * 1000;
    }
    
    NSUInteger const gcd = gcdArray(frameCount, durations);
    __block NSUInteger totalDuration = 0;
    NSMutableArray<UIImage *> *animatedImages = [NSMutableArray arrayWithCapacity:frameCount];
    [frames enumerateObjectsUsingBlock:^(TOImageFrame * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = frame.image;
        NSUInteger duration = frame.duration * 1000;
        totalDuration += duration;
        NSUInteger repeatCount;
        if (gcd) {
            repeatCount = duration / gcd;
        } else {
            repeatCount = 1;
        }
        for (size_t i = 0; i < repeatCount; ++i) {
            [animatedImages addObject:image];
        }
    }];
    
    animatedImage = [UIImage animatedImageWithImages:animatedImages duration:totalDuration / 1000.f];
    
    return animatedImage;
}

- (nullable NSArray<TOImageFrame *> *)frames {
    NSMutableArray<TOImageFrame *> *frames = [NSMutableArray array];
    
    NSArray<UIImage *> *animatedImages = self.images;
    NSInteger frameCount = animatedImages.count;
        
    if (frameCount == 0) {
        return nil;
    }
    NSTimeInterval avgDuration = self.duration / frameCount;
    if (avgDuration == 0) {
        avgDuration = 0.1;
    }
    __block NSUInteger repeatCount = 1;
    __block UIImage *previousImage = animatedImages.firstObject;
    
    [animatedImages enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        //ignore first
        if (idx == 0) {
            return;
        }
        
        if ([image isEqual: previousImage]) {
            repeatCount++;
        } else {
            TOImageFrame *frame = [TOImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
            repeatCount = 1;
        }
        previousImage = image;
    }];
    
    TOImageFrame *frame = [TOImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount];
    [frames addObject:frame];
    return frames;
}

static NSUInteger gcd(NSUInteger a, NSUInteger b) {
    NSUInteger c;
    while (a != 0) {
        c = a;
        a = b % a;
        b = c;
    }
    return b;
}

static NSUInteger gcdArray(size_t const count, NSUInteger const * const values) {
    if (count == 0) {
        return 0;
    }
    NSUInteger result = values[0];
    for (size_t i = 1; i < count; ++i) {
        result = gcd(values[i], result);
    }
    return result;
}

@end
