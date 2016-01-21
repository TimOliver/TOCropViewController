//
//  TOCropToolbar.h
//
//  Copyright 2015 Timothy Oliver. All rights reserved.
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

#import "TOCropToolbar.h"

#define kTOCropToolbarShowButtonsContainerRectForDebugging     0   // convenience debug toggle

@interface TOCropToolbar()

@property (nonatomic, strong) UIButton *doneTextButton;
@property (nonatomic, strong) UIButton *doneIconButton;

@property (nonatomic, strong) UIButton *cancelTextButton;
@property (nonatomic, strong) UIButton *cancelIconButton;

@property (nonatomic, strong) UIButton *rotateCCWButton; // counterclockwise rotation
@property (nonatomic, strong) UIButton *rotateCWButton;  // clockwise rotation
@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *clampButton;

@property (nonatomic, strong) UIButton *rotateButton;   // compatible with original rotateButton

- (void)setup;
- (void)buttonTapped:(id)button;

+ (UIImage *)doneImage;
+ (UIImage *)cancelImage;
+ (UIImage *)resetImage;
+ (UIImage *)rotateCCWImage;
+ (UIImage *)rotateCWImage;
+ (UIImage *)clampImage;

@end

@implementation TOCropToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor colorWithWhite:0.12f alpha:1.0f];
    
    _doneTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _doneTextButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_doneTextButton setTitle:NSLocalizedStringFromTableInBundle(@"Done",
                                                                 @"TOCropViewControllerLocalizable",
                                                                 [NSBundle bundleForClass:[self class]],
                                                                 nil)
                     forState:UIControlStateNormal];
    [_doneTextButton setTitleColor:[UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f] forState:UIControlStateNormal];
    [_doneTextButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [_doneTextButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_doneTextButton];
    
    _doneIconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneIconButton setImage:[TOCropToolbar doneImage] forState:UIControlStateNormal];
    [_doneIconButton setTintColor:[UIColor colorWithRed:1.0f green:0.8f blue:0.0f alpha:1.0f]];
    [_doneIconButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_doneIconButton];
    
    _cancelTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _cancelTextButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [_cancelTextButton setTitle:NSLocalizedStringFromTableInBundle(@"Cancel",
                                                                   @"TOCropViewControllerLocalizable",
                                                                   [NSBundle bundleForClass:[self class]],
                                                                   nil)
                       forState:UIControlStateNormal];
    [_cancelTextButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [_cancelTextButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelTextButton];
    
    _cancelIconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancelIconButton setImage:[TOCropToolbar cancelImage] forState:UIControlStateNormal];
    [_cancelIconButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_cancelIconButton];
    
    _clampButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _clampButton.contentMode = UIViewContentModeCenter;
    _clampButton.tintColor = [UIColor whiteColor];
    [_clampButton setImage:[TOCropToolbar clampImage] forState:UIControlStateNormal];
    [_clampButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_clampButton];
    
    _rotateCWButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _rotateCWButton.contentMode = UIViewContentModeCenter;
    _rotateCWButton.tintColor = [UIColor whiteColor];
    [_rotateCWButton setImage:[TOCropToolbar rotateCWImage] forState:UIControlStateNormal];
    [_rotateCWButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_rotateCWButton];
    
    _rotateCCWButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _rotateCCWButton.contentMode = UIViewContentModeCenter;
    _rotateCCWButton.tintColor = [UIColor whiteColor];
    [_rotateCCWButton setImage:[TOCropToolbar rotateCCWImage] forState:UIControlStateNormal];
    [_rotateCCWButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_rotateCCWButton];
    
    _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _resetButton.contentMode = UIViewContentModeCenter;
    _resetButton.tintColor = [UIColor whiteColor];
    _resetButton.enabled = NO;
    [_resetButton setImage:[TOCropToolbar resetImage] forState:UIControlStateNormal];
    [_resetButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_resetButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL verticalLayout = (CGRectGetWidth(self.bounds) < CGRectGetHeight(self.bounds));
    CGSize boundsSize = self.bounds.size;
    
    self.cancelIconButton.hidden = (!verticalLayout);
    self.cancelTextButton.hidden = (verticalLayout);
    self.doneIconButton.hidden   = (!verticalLayout);
    self.doneTextButton.hidden   = (verticalLayout);
    
    self.rotateCCWButton.hidden = self.rotateButtonHidden;
    
#if kTOCropToolbarShowButtonsContainerRectForDebugging
    static UIView *containerView = nil;
    if (!containerView) {
        containerView = [[UIView alloc] initWithFrame:CGRectZero];
        containerView.backgroundColor = [UIColor redColor];
        containerView.alpha = 0.1;
        [self addSubview:containerView];
    }
#endif
    
    if (verticalLayout == NO) {
        CGRect frame = CGRectZero;
        frame.size.height = 44.0f;
        frame.size.width = [self.cancelTextButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.cancelTextButton.titleLabel.font}].width + 10;
        self.cancelTextButton.frame = frame;
        
        frame.size.width = [self.doneTextButton.titleLabel.text sizeWithAttributes:@{NSFontAttributeName:self.doneTextButton.titleLabel.font}].width + 10;
        frame.origin.x = boundsSize.width - CGRectGetWidth(frame);
        self.doneTextButton.frame = frame;
        
        CGRect containerRect = (CGRect){CGRectGetMaxX(self.cancelTextButton.frame),0,CGRectGetMinX(self.doneTextButton.frame)-CGRectGetMaxX(self.cancelTextButton.frame),44.0f};

#if kTOCropToolbarShowButtonsContainerRectForDebugging
        containerView.frame = containerRect;
#endif
        
        CGSize buttonSize = (CGSize){44.0f,44.0f};
        
        if (self.rotateButtonHidden) {
            [self layoutToolbarButtons:@[self.resetButton, self.clampButton] withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:YES];
        }
        else {
            NSArray *buttonsInOrderHorizontally = @[self.rotateCWButton, self.rotateCCWButton, self.resetButton, self.clampButton];
            [self layoutToolbarButtons:buttonsInOrderHorizontally withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:YES];
        }
    }
    else {
        CGRect frame = CGRectZero;
        frame.size.height = 44.0f;
        frame.size.width = 44.0f;
        frame.origin.y = CGRectGetHeight(self.bounds) - 44.0f;
        self.cancelIconButton.frame = frame;
        
        frame.origin.y = 0.0f;
        frame.size.width = 44.0f;
        frame.size.height = 44.0f;
        self.doneIconButton.frame = frame;
        
        CGRect containerRect = (CGRect){0,CGRectGetMaxY(self.doneIconButton.frame),44.0f,CGRectGetMinY(self.cancelIconButton.frame)-CGRectGetMaxY(self.doneIconButton.frame)};
        
#if kTOCropToolbarShowButtonsContainerRectForDebugging
        containerView.frame = containerRect;
#endif
        
        CGSize buttonSize = (CGSize){44.0f,44.0f};
        
        if (self.rotateButtonHidden) {
            [self layoutToolbarButtons:@[self.resetButton, self.clampButton] withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:NO];
        }
        else {
            NSArray *buttonsInOrderVertically = @[self.rotateCWButton, self.rotateCCWButton, self.resetButton, self.clampButton];
            [self layoutToolbarButtons:buttonsInOrderVertically withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:NO];
        }
    }
}

// The convenience method for calculating button's frame inside of the container rect
- (void)layoutToolbarButtons:(NSArray *)buttons withSameButtonSize:(CGSize)size inContainerRect:(CGRect)containerRect horizontally:(BOOL)horizontally
{
    NSInteger count = buttons.count;
    CGFloat fixedSize = horizontally ? size.width : size.height;
    CGFloat maxLength = horizontally ? CGRectGetWidth(containerRect) : CGRectGetHeight(containerRect);
    CGFloat padding = (maxLength - fixedSize * count) / (count + 1);
    
    for (NSInteger i = 0; i < count; i++) {
        UIView *button = buttons[i];
        CGFloat sameOffset = horizontally ? fabs(CGRectGetHeight(containerRect)-CGRectGetHeight(button.bounds)) : fabs(CGRectGetWidth(containerRect)-CGRectGetWidth(button.bounds));
        CGFloat diffOffset = padding + i * (fixedSize + padding);
        CGPoint origin = horizontally ? CGPointMake(diffOffset, sameOffset) : CGPointMake(sameOffset, diffOffset);
        if (horizontally) {
            origin.x += CGRectGetMinX(containerRect);
        } else {
            origin.y += CGRectGetMinY(containerRect);
        }
        button.frame = (CGRect){origin, size};
    }
}

- (void)buttonTapped:(id)button
{
    if (button == self.cancelTextButton || button == self.cancelIconButton) {
        if (self.cancelButtonTapped)
            self.cancelButtonTapped();
    }
    else if (button == self.doneTextButton || button == self.doneIconButton) {
        if (self.doneButtonTapped)
            self.doneButtonTapped();
    }
    else if (button == self.resetButton && self.resetButtonTapped) {
        self.resetButtonTapped();
    }
    else if (button == self.rotateCCWButton && self.rotateCCWButtonTapped) {
        self.rotateCCWButtonTapped();
    }
    else if (button == self.rotateCWButton && self.rotateCWButtonTapped) {
        self.rotateCWButtonTapped();
    }
    else if (button == self.clampButton && self.clampButtonTapped) {
        self.clampButtonTapped();
        return;
    }
}

- (CGRect)clampButtonFrame
{
    return self.clampButton.frame;
}

- (void)setClampButtonGlowing:(BOOL)clampButtonGlowing
{
    if (_clampButtonGlowing == clampButtonGlowing)
        return;
    
    _clampButtonGlowing = clampButtonGlowing;
    
    if (_clampButtonGlowing)
        self.clampButton.tintColor = nil;
    else
        self.clampButton.tintColor = [UIColor whiteColor];
}

- (void)setRotateButtonHidden:(BOOL)rotateButtonHidden
{
    if (_rotateButtonHidden == rotateButtonHidden)
        return;
    
    _rotateButtonHidden = rotateButtonHidden;
    [self setNeedsLayout];
}

- (BOOL)resetButtonEnabled
{
    return self.resetButton.enabled;
}

- (void)setResetButtonEnabled:(BOOL)resetButtonEnabled
{
    self.resetButton.enabled = resetButtonEnabled;
}

- (CGRect)doneButtonFrame
{
    if (self.doneIconButton.hidden == NO)
        return self.doneIconButton.frame;
    
    return self.doneTextButton.frame;
}

#pragma mark - Image Generation -
+ (UIImage *)doneImage
{
    UIImage *doneImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){17,14}, NO, 0.0f);
    {
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = UIBezierPath.bezierPath;
        [rectanglePath moveToPoint: CGPointMake(1, 7)];
        [rectanglePath addLineToPoint: CGPointMake(6, 12)];
        [rectanglePath addLineToPoint: CGPointMake(16, 1)];
        [UIColor.whiteColor setStroke];
        rectanglePath.lineWidth = 2;
        [rectanglePath stroke];
        
        
        doneImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return doneImage;
}

+ (UIImage *)cancelImage
{
    UIImage *cancelImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){16,16}, NO, 0.0f);
    {
        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        [bezierPath moveToPoint: CGPointMake(15, 15)];
        [bezierPath addLineToPoint: CGPointMake(1, 1)];
        [UIColor.whiteColor setStroke];
        bezierPath.lineWidth = 2;
        [bezierPath stroke];
        
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        [bezier2Path moveToPoint: CGPointMake(1, 15)];
        [bezier2Path addLineToPoint: CGPointMake(15, 1)];
        [UIColor.whiteColor setStroke];
        bezier2Path.lineWidth = 2;
        [bezier2Path stroke];
        
        cancelImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return cancelImage;
}

+ (UIImage *)rotateCCWImage
{
    UIImage *rotateImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){18,21}, NO, 0.0f);
    {
        //// Rectangle 2 Drawing
        UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRect: CGRectMake(0, 9, 12, 12)];
        [UIColor.whiteColor setFill];
        [rectangle2Path fill];
        
        
        //// Rectangle 3 Drawing
        UIBezierPath* rectangle3Path = UIBezierPath.bezierPath;
        [rectangle3Path moveToPoint: CGPointMake(5, 3)];
        [rectangle3Path addLineToPoint: CGPointMake(10, 6)];
        [rectangle3Path addLineToPoint: CGPointMake(10, 0)];
        [rectangle3Path addLineToPoint: CGPointMake(5, 3)];
        [rectangle3Path closePath];
        [UIColor.whiteColor setFill];
        [rectangle3Path fill];
        
        
        //// Bezier Drawing
        UIBezierPath* bezierPath = UIBezierPath.bezierPath;
        [bezierPath moveToPoint: CGPointMake(10, 3)];
        [bezierPath addCurveToPoint: CGPointMake(17.5, 11) controlPoint1: CGPointMake(15, 3) controlPoint2: CGPointMake(17.5, 5.91)];
        [UIColor.whiteColor setStroke];
        bezierPath.lineWidth = 1;
        [bezierPath stroke];
        rotateImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return rotateImage;
}

+ (UIImage *)rotateCWImage
{
    UIImage *rotateCCWImage = [self.class rotateCCWImage];
    UIGraphicsBeginImageContextWithOptions(rotateCCWImage.size, NO, rotateCCWImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotateCCWImage.size.width, rotateCCWImage.size.height);
    CGContextRotateCTM(context, M_PI);
    CGContextDrawImage(context,CGRectMake(0,0,rotateCCWImage.size.width,rotateCCWImage.size.height),rotateCCWImage.CGImage);
    UIImage *rotateCWImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rotateCWImage;
}

+ (UIImage *)resetImage
{
    UIImage *resetImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){22,18}, NO, 0.0f);
    {
        
        //// Bezier 2 Drawing
        UIBezierPath* bezier2Path = UIBezierPath.bezierPath;
        [bezier2Path moveToPoint: CGPointMake(22, 9)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 18) controlPoint1: CGPointMake(22, 13.97) controlPoint2: CGPointMake(17.97, 18)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 16) controlPoint1: CGPointMake(13, 17.35) controlPoint2: CGPointMake(13, 16.68)];
        [bezier2Path addCurveToPoint: CGPointMake(20, 9) controlPoint1: CGPointMake(16.87, 16) controlPoint2: CGPointMake(20, 12.87)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 2) controlPoint1: CGPointMake(20, 5.13) controlPoint2: CGPointMake(16.87, 2)];
        [bezier2Path addCurveToPoint: CGPointMake(6.55, 6.27) controlPoint1: CGPointMake(10.1, 2) controlPoint2: CGPointMake(7.62, 3.76)];
        [bezier2Path addCurveToPoint: CGPointMake(6, 9) controlPoint1: CGPointMake(6.2, 7.11) controlPoint2: CGPointMake(6, 8.03)];
        [bezier2Path addLineToPoint: CGPointMake(4, 9)];
        [bezier2Path addCurveToPoint: CGPointMake(4.65, 5.63) controlPoint1: CGPointMake(4, 7.81) controlPoint2: CGPointMake(4.23, 6.67)];
        [bezier2Path addCurveToPoint: CGPointMake(7.65, 1.76) controlPoint1: CGPointMake(5.28, 4.08) controlPoint2: CGPointMake(6.32, 2.74)];
        [bezier2Path addCurveToPoint: CGPointMake(13, 0) controlPoint1: CGPointMake(9.15, 0.65) controlPoint2: CGPointMake(11, 0)];
        [bezier2Path addCurveToPoint: CGPointMake(22, 9) controlPoint1: CGPointMake(17.97, 0) controlPoint2: CGPointMake(22, 4.03)];
        [bezier2Path closePath];
        [UIColor.whiteColor setFill];
        [bezier2Path fill];
        
        
        //// Polygon Drawing
        UIBezierPath* polygonPath = UIBezierPath.bezierPath;
        [polygonPath moveToPoint: CGPointMake(5, 15)];
        [polygonPath addLineToPoint: CGPointMake(10, 9)];
        [polygonPath addLineToPoint: CGPointMake(0, 9)];
        [polygonPath addLineToPoint: CGPointMake(5, 15)];
        [polygonPath closePath];
        [UIColor.whiteColor setFill];
        [polygonPath fill];


        resetImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    
    return resetImage;
}

+ (UIImage *)clampImage
{
    UIImage *clampImage = nil;
    
    UIGraphicsBeginImageContextWithOptions((CGSize){22,16}, NO, 0.0f);
    {
        //// Color Declarations
        UIColor* outerBox = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.553];
        UIColor* innerBox = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 0.773];
        
        //// Rectangle Drawing
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 3, 13, 13)];
        [UIColor.whiteColor setFill];
        [rectanglePath fill];
        
        
        //// Outer
        {
            //// Top Drawing
            UIBezierPath* topPath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, 22, 2)];
            [outerBox setFill];
            [topPath fill];
            
            
            //// Side Drawing
            UIBezierPath* sidePath = [UIBezierPath bezierPathWithRect: CGRectMake(19, 2, 3, 14)];
            [outerBox setFill];
            [sidePath fill];
        }
        
        
        //// Rectangle 2 Drawing
        UIBezierPath* rectangle2Path = [UIBezierPath bezierPathWithRect: CGRectMake(14, 3, 4, 13)];
        [innerBox setFill];
        [rectangle2Path fill];
        
        
        clampImage = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return clampImage;
}

#pragma mark - Rotate Button Compatibility

- (void)setRotateButton:(UIButton *)rotateButton
{
    self.rotateCCWButton = rotateButton;
}

- (UIButton *)rotateButton
{
    return self.rotateCCWButton;
}

@end
