//
//  ViewController.m
//  TOCropViewControllerExample
//
//  Created by Tim Oliver on 3/19/15.
//  Copyright (c) 2015 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOCropViewController.h"

@interface ViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate, TOCropViewControllerDelegate>

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) UIImagePickerController *standardPicker;
@property (nonatomic, strong) UIImagePickerController *profilePicker;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UIPopoverController *activityPopoverController;
#pragma clang diagnostic pop

- (void)showCropViewController;
- (void)sharePhoto;

- (void)layoutImageView;
- (void)didTapImageView;

- (void)updateImageViewWithImage:(UIImage *)image fromCropViewController:(TOCropViewController *)cropViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TOCropViewController";

    self.navigationController.navigationBar.translucent = NO;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showCropViewController)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(sharePhoto)];

    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.userInteractionEnabled = YES;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapImageView)];
    [self.imageView addGestureRecognizer:tapRecognizer];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutImageView];
}

- (void)layoutImageView
{
    if (self.imageView.image == nil)
        return;
    
    CGFloat padding = 20.0f;
    
    CGRect viewFrame = self.view.frame;
    viewFrame.size.width -= (padding * 2.0f);
    viewFrame.size.height -= ((padding * 2.0f));
    
    CGRect imageFrame = CGRectZero;
    imageFrame.size = self.imageView.image.size;
    
    if (self.imageView.image.size.width > viewFrame.size.width &&
        self.imageView.image.size.height > viewFrame.size.height)
    {
        CGFloat scale = MIN(viewFrame.size.width / imageFrame.size.width, viewFrame.size.height / imageFrame.size.height);
        imageFrame.size.width *= scale;
        imageFrame.size.height *= scale;
        imageFrame.origin.x = (CGRectGetWidth(self.view.bounds) - imageFrame.size.width) * 0.5f;
        imageFrame.origin.y = (CGRectGetHeight(self.view.bounds) - imageFrame.size.height) * 0.5f;
        self.imageView.frame = imageFrame;
    }
    else {
        self.imageView.frame = imageFrame;
        self.imageView.center = self.view.center;
    }
}

#pragma mark - Bar Button Items -
- (void)showCropViewController
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Crop Image"
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
                                               self.standardPicker = [[UIImagePickerController alloc] init];
                                               self.standardPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                               self.standardPicker.allowsEditing = NO;
                                               self.standardPicker.delegate = self;
                                               [self presentViewController:self.standardPicker animated:YES completion:nil];
                                           }];
    
    UIAlertAction *profileAction = [UIAlertAction actionWithTitle:@"Make Profile Picture"
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action) {
                                             self.profilePicker = [[UIImagePickerController alloc] init];
                                             self.profilePicker.modalPresentationStyle = UIModalPresentationFormSheet;
                                             self.profilePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                             self.profilePicker.allowsEditing = NO;
                                             self.profilePicker.delegate = self;
                                             [self presentViewController:self.profilePicker animated:YES completion:nil];
                                         }];
    
    [alertController addAction:defaultAction];
    [alertController addAction:profileAction];
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [alertController popoverPresentationController];
    popPresenter.barButtonItem = self.navigationItem.leftBarButtonItem;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)sharePhoto
{
    if (self.imageView.image == nil)
        return;
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[self.imageView.image] applicationActivities:nil];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self presentViewController:activityController animated:YES completion:nil];
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.activityPopoverController dismissPopoverAnimated:NO];
        self.activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [self.activityPopoverController presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
#pragma clang diagnostic pop
    }
}

#pragma mark - Cropper Delegate -
- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}

- (void)cropViewController:(TOCropViewController *)cropViewController didCropToCircularImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle
{
    [self updateImageViewWithImage:image fromCropViewController:cropViewController];
}

- (void)updateImageViewWithImage:(UIImage *)image fromCropViewController:(TOCropViewController *)cropViewController
{
    self.imageView.image = image;
    [self layoutImageView];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    if (cropViewController.croppingStyle != TOCropViewCroppingStyleCircular) {
        CGRect viewFrame = [self.view convertRect:self.imageView.frame toView:self.navigationController.view];
        self.imageView.hidden = YES;
        [cropViewController dismissAnimatedFromParentViewController:self withCroppedImage:image toFrame:viewFrame completion:^{
            self.imageView.hidden = NO;
        }];
    }
    else {
        [cropViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Image Picker Delegate -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    if (picker == self.profilePicker) {
        TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:TOCropViewCroppingStyleCircular image:image];
        cropController.delegate = self;
        self.image = image;
        [picker pushViewController:cropController animated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:^{
            self.image = image;
            TOCropViewController *cropController = [[TOCropViewController alloc] initWithCroppingStyle:TOCropViewCroppingStyleDefault image:image];
            cropController.delegate = self;
            
            // Uncomment this to test out locked aspect ratio sizes
            // cropController.defaultAspectRatio = TOCropViewControllerAspectRatioSquare;
            // cropController.aspectRatioLocked = YES;
            
            // Uncomment this to place the toolbar at the top of the view controller
            // cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;
            
            [self presentViewController:cropController animated:YES completion:nil];
        }];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Gesture Recognizer -
- (void)didTapImageView
{
    TOCropViewController *cropController = [[TOCropViewController alloc] initWithImage:self.image];
    cropController.delegate = self;
    
    // Uncomment this to place the toolbar at the top of the view controller
    // cropController.toolbarPosition = TOCropViewControllerToolbarPositionTop;
    
    [self presentViewController:cropController animated:YES completion:nil];
}

@end
