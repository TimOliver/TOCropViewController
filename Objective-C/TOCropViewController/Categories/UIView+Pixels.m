//
//  UIView+Pixels.m
//
//  Copyright 2024 Jan de Vries. All rights reserved.
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

#import "UIView+Pixels.h"

@implementation UIView (TOPixels)

- (CGFloat)roundToNearestPixel:(CGFloat)val {
    CGFloat screenScale = 2.0f;
    if (self.window != nil && self.window.screen != nil) {
        screenScale = self.window.screen.scale;
    }
    return roundf(val * screenScale) / screenScale;
}

- (BOOL)pixelCount:(CGFloat)val1 equals:(CGFloat)val2
{
    if (self.window == nil || self.window.screen == nil) {
        return val1 == val2;
    }
    CGFloat screenScale = self.window.screen.scale;
    return roundf(val1*screenScale) == roundf(val2*screenScale);
}

@end
