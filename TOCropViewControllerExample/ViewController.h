//
//  ViewController.h
//  TOCropViewControllerExample
//
//  Created by Tim Oliver on 3/19/15.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>


// Delegate Protocol
@protocol DemoViewControllerDelegate;



@interface ViewController : UIViewController

@property (nonatomic, weak) id<DemoViewControllerDelegate> delegate;

@end



// Delegate Declarations
@protocol DemoViewControllerDelegate <NSObject>

@optional
- (void) demoViewControllerDidClose:(ViewController *)viewController;

@end


