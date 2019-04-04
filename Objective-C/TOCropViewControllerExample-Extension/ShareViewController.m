//
//  ShareViewController.m
//  TOCropViewController-ShareExtension
//
//  Created by Shardul Patel on 27/08/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "ShareViewController.h"
#import "ViewController.h"

@implementation ShareViewController

- (void) viewDidLoad {
    [super viewDidLoad];

    // Instantiate and create the initial view controller from the main example app
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *viewController = [storyboard instantiateInitialViewController];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    [super dismissViewControllerAnimated:flag completion:completion];
}

@end
