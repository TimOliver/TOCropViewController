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
    TOCropViewController *controller = [[TOCropViewController alloc] initWithImage:nil];
    UIView *view = controller.view;
    XCTAssert(view!=nil, @"Pass");
}

@end
