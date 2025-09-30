//
//  TOCropViewControllerAspectRatioPreset.m
//
//  Copyright 2015-2025 Timothy Oliver. All rights reserved.
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

#import "TOCropViewControllerAspectRatioPreset.h"
#if !__has_include(<TOCropViewController/TOCropViewConstants.h>)
#import "TOCropViewConstants.h"
#else
#import <TOCropViewController/TOCropViewConstants.h>
#endif

@interface TOCropViewControllerAspectRatioPreset ()

@property (nonatomic, assign, readwrite) CGFloat width;
@property (nonatomic, assign, readwrite) CGFloat height;
@property (nonatomic, strong, readwrite) NSString *title;

@end

@implementation TOCropViewControllerAspectRatioPreset

- (instancetype)initWithSize:(CGSize)size title:(NSString *)title
{
    self = [super init];
    if (self) {
        _size = size;
        _title = title;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[TOCropViewControllerAspectRatioPreset class]]) {
        return NO;
    }
    TOCropViewControllerAspectRatioPreset *other = (TOCropViewControllerAspectRatioPreset *)object;
    return CGSizeEqualToSize(self.size, other.size) && [self.title isEqualToString:other.title];
}

+ (NSArray<TOCropViewControllerAspectRatioPreset *> *)portraitPresets
{
    TOCropViewControllerAspectRatioPreset *object = [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeZero title:@"Original"];
	NSBundle *resourceBundle = TO_CROP_VIEW_RESOURCE_BUNDLE_FOR_OBJECT(object);
    return @[
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeZero title:NSLocalizedStringFromTableInBundle(@"Original", @"TOCropViewControllerLocalizable", resourceBundle, nil)],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(1.0f, 1.0f) title:NSLocalizedStringFromTableInBundle(@"Square", @"TOCropViewControllerLocalizable", resourceBundle, nil)],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(2.0f, 3.0f) title:@"2:3"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(3.0f, 5.0f) title:@"3:5"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(3.0f, 4.0f) title:@"3:4"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(4.0f, 5.0f) title:@"4:5"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(5.0f, 7.0f) title:@"5:7"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(9.0f, 16.0f) title:@"9:16"],
    ];
}

+ (NSArray<TOCropViewControllerAspectRatioPreset *> *)landscapePresets
{
    TOCropViewControllerAspectRatioPreset *object = [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeZero title:@"Original"];
	NSBundle *resourceBundle = TO_CROP_VIEW_RESOURCE_BUNDLE_FOR_OBJECT(object);
    return @[
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeZero title:NSLocalizedStringFromTableInBundle(@"Original", @"TOCropViewControllerLocalizable", resourceBundle, nil)],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(1.0f, 1.0f) title:NSLocalizedStringFromTableInBundle(@"Square", @"TOCropViewControllerLocalizable", resourceBundle, nil)],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(3.0f, 2.0f) title:@"3:2"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(5.0f, 3.0f) title:@"5:3"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(4.0f, 3.0f) title:@"4:3"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(5.0f, 4.0f) title:@"5:4"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(7.0f, 5.0f) title:@"7:5"],
        [[TOCropViewControllerAspectRatioPreset alloc] initWithSize:CGSizeMake(16.0f, 9.0f) title:@"16:9"],
    ];
}
@end


