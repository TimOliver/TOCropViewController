//
//  TOCropViewControllerTests.m
//  TOCropViewControllerTests
//
//  Created by Tim Oliver on 14/06/2015.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "TOCropViewController.h"

@interface TOCropViewControllerTests : XCTestCase

@end

@implementation TOCropViewControllerTests

- (void)testViewControllerInstance {
    // Create a basic image
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(10, 10)];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull context) {
        [context fillRect:CGRectMake(0, 0, 10, 10)];
    }];

    // Perform test
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:image];
    UIView *view = controller.view;
    XCTAssertNotNil(view);
}

@end
