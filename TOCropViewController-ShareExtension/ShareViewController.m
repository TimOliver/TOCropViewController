//
//  ShareViewController.m
//  TOCropViewController-ShareExtension
//
//  Created by Shardul Patel on 27/08/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "ShareViewController.h"
#import "ViewController.h"


@interface ShareViewController () <DemoViewControllerDelegate>

@end


@implementation ShareViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Get Application's Main Storyboard File
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // Present Demo View Controller
    id viewController = [storyboard instantiateInitialViewController];
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        
        UINavigationController *navigationVC = (UINavigationController *) viewController;
        if ([navigationVC.visibleViewController isKindOfClass:[ViewController class]]) {
            
            ViewController *viewController = (ViewController *) navigationVC.visibleViewController;
            viewController.delegate = self;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:viewController animated:YES completion:nil];
    });
}

#pragma mark - DemoViewControllerDelegate

- (void) demoViewControllerDidClose:(ViewController *)viewController    {
    
    // Dismiss Self
    [self dismissViewControllerAnimated:NO completion:nil];
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}

@end
