//
//  TOCropToolbar.h
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

#import "TOCropToolbar.h"
#import "UIView+Pixels.h"

#define TOCROPTOOLBAR_DEBUG_SHOWING_BUTTONS_CONTAINER_RECT 0   // convenience debug toggle

@interface TOCropToolbar()

@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong, readwrite) UIButton *doneTextButton;
@property (nonatomic, strong, readwrite) UIButton *doneIconButton;

@property (nonatomic, strong, readwrite) UIButton *cancelTextButton;
@property (nonatomic, strong, readwrite) UIButton *cancelIconButton;

@property (nonatomic, strong) UIButton *resetButton;
@property (nonatomic, strong) UIButton *clampButton;

@property (nonatomic, strong) UIButton *rotateButton; // defaults to counterclockwise button for legacy compatibility

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
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    [self addSubview:self.backgroundView];
    
    // On iOS 9 and up, we can use the new layout features to determine whether we're in an 'Arabic' style language mode
    _reverseContentLayout = ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft);

    // Get the resource bundle depending on the framework/dependency manager we're using
    NSBundle *resourceBundle = TO_CROP_VIEW_RESOURCE_BUNDLE_FOR_OBJECT(self);
    
    _doneTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneTextButton setTitle: _doneTextButtonTitle ?
        _doneTextButtonTitle : NSLocalizedStringFromTableInBundle(@"Done",
																  @"TOCropViewControllerLocalizable",
																  resourceBundle,
                                                                  nil)
                     forState:UIControlStateNormal];
    [_doneTextButton setTitleColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        [_doneTextButton.titleLabel setFont:[UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium]];
    } else {
        [_doneTextButton.titleLabel setFont:[UIFont systemFontOfSize:17.0]];
    }
    [_doneTextButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_doneTextButton sizeToFit];
    [self addSubview:_doneTextButton];
    
    _doneIconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneIconButton setImage:[TOCropToolbar doneImage] forState:UIControlStateNormal];
    [_doneIconButton setTintColor:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0]];
    [_doneIconButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_doneIconButton];

    // Set the default color for the done buttons
    self.doneButtonColor = nil;

    _cancelTextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [_cancelTextButton setTitle: _cancelTextButtonTitle ?
        _cancelTextButtonTitle : NSLocalizedStringFromTableInBundle(@"Cancel",
																	@"TOCropViewControllerLocalizable",
																	resourceBundle,
                                                                    nil)
                       forState:UIControlStateNormal];
    [_cancelTextButton.titleLabel setFont:[UIFont systemFontOfSize:17.0]];
    [_cancelTextButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_cancelTextButton sizeToFit];
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
    
    _rotateCounterclockwiseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _rotateCounterclockwiseButton.contentMode = UIViewContentModeCenter;
    _rotateCounterclockwiseButton.tintColor = [UIColor whiteColor];
    [_rotateCounterclockwiseButton setImage:[TOCropToolbar rotateCCWImage] forState:UIControlStateNormal];
    [_rotateCounterclockwiseButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_rotateCounterclockwiseButton];
    
    _rotateClockwiseButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _rotateClockwiseButton.contentMode = UIViewContentModeCenter;
    _rotateClockwiseButton.tintColor = [UIColor whiteColor];
    [_rotateClockwiseButton setImage:[TOCropToolbar rotateCWImage] forState:UIControlStateNormal];
    [_rotateClockwiseButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_rotateClockwiseButton];
    
    _flipHorizontalButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _flipHorizontalButton.contentMode = UIViewContentModeCenter;
    _flipHorizontalButton.tintColor = [UIColor whiteColor];
    [_flipHorizontalButton setImage:[TOCropToolbar flipHImage] forState:UIControlStateNormal];
    [_flipHorizontalButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_flipHorizontalButton];
    
    _flipVerticalButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _flipVerticalButton.contentMode = UIViewContentModeCenter;
    _flipVerticalButton.tintColor = [UIColor whiteColor];
    [_flipVerticalButton setImage:[TOCropToolbar flipVImage] forState:UIControlStateNormal];
    [_flipVerticalButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_flipVerticalButton];
    
    _resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _resetButton.contentMode = UIViewContentModeCenter;
    _resetButton.tintColor = [UIColor whiteColor];
    _resetButton.enabled = NO;
    [_resetButton setImage:[TOCropToolbar resetImage] forState:UIControlStateNormal];
    [_resetButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    _resetButton.accessibilityLabel = NSLocalizedStringFromTableInBundle(@"Reset",
                                                                         @"TOCropViewControllerLocalizable",
                                                                         resourceBundle,
                                                                         nil);
    [self addSubview:_resetButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL verticalLayout = (CGRectGetWidth(self.bounds) < CGRectGetHeight(self.bounds));
    CGSize boundsSize = self.bounds.size;
    
    self.cancelIconButton.hidden = self.cancelButtonHidden || (_showOnlyIcons ? NO : !verticalLayout);
    self.cancelTextButton.hidden = self.cancelButtonHidden || (_showOnlyIcons ? YES : verticalLayout);
    self.doneIconButton.hidden   = self.doneButtonHidden || (_showOnlyIcons ? NO : !verticalLayout);
    self.doneTextButton.hidden   = self.doneButtonHidden || (_showOnlyIcons ? YES : verticalLayout);

    CGRect frame = self.bounds;
    frame.origin.x -= self.backgroundViewOutsets.left;
    frame.size.width += self.backgroundViewOutsets.left;
    frame.size.width += self.backgroundViewOutsets.right;
    frame.origin.y -= self.backgroundViewOutsets.top;
    frame.size.height += self.backgroundViewOutsets.top;
    frame.size.height += self.backgroundViewOutsets.bottom;
    self.backgroundView.frame = frame;
    
#if TOCROPTOOLBAR_DEBUG_SHOWING_BUTTONS_CONTAINER_RECT
    static UIView *containerView = nil;
    if (!containerView) {
        containerView = [[UIView alloc] initWithFrame:CGRectZero];
        containerView.backgroundColor = [UIColor redColor];
        containerView.alpha = 0.1;
        [self addSubview:containerView];
    }
#endif
    
    if (verticalLayout == NO) {
        CGFloat insetPadding = 10.0;
        
        // Work out the cancel button frame
        CGRect frame = CGRectZero;
        frame.size.height = 44.0;
        frame.size.width = _showOnlyIcons ? 44.0 : MIN(self.frame.size.width / 3.0, self.cancelTextButton.frame.size.width);

        //If normal layout, place on the left side, else place on the right
        if (self.reverseContentLayout == NO) {
            frame.origin.x = insetPadding;
        }
        else {
            frame.origin.x = boundsSize.width - (frame.size.width + insetPadding);
        }
        (_showOnlyIcons ? self.cancelIconButton : self.cancelTextButton).frame = frame;
        
        // Work out the Done button frame
        frame.size.width = _showOnlyIcons ? 44.0 : MIN(self.frame.size.width / 3.0, self.doneTextButton.frame.size.width);
        
        if (self.reverseContentLayout == NO) {
            frame.origin.x = boundsSize.width - (frame.size.width + insetPadding);
        }
        else {
            frame.origin.x = insetPadding;
        }
        (_showOnlyIcons ? self.doneIconButton : self.doneTextButton).frame = frame;
        
        // Work out the frame between the two buttons where we can layout our action buttons
        CGFloat x = self.reverseContentLayout ? CGRectGetMaxX((_showOnlyIcons ? self.doneIconButton : self.doneTextButton).frame) : CGRectGetMaxX((_showOnlyIcons ? self.cancelIconButton : self.cancelTextButton).frame);
        CGFloat width = 0.0;
        
        if (self.reverseContentLayout == NO) {
            width = CGRectGetMinX((_showOnlyIcons ? self.doneIconButton : self.doneTextButton).frame) - CGRectGetMaxX((_showOnlyIcons ? self.cancelIconButton : self.cancelTextButton).frame);
        }
        else {
            width = CGRectGetMinX((_showOnlyIcons ? self.cancelIconButton : self.cancelTextButton).frame) - CGRectGetMaxX((_showOnlyIcons ? self.doneIconButton : self.doneTextButton).frame);
        }

        CGRect containerRect = CGRectInset([self CGRectIntegralRetina:(CGRect){x,frame.origin.y,width,44.0}], _showOnlyIcons ? 0 : insetPadding, 0);

#if TOCROPTOOLBAR_DEBUG_SHOWING_BUTTONS_CONTAINER_RECT
        containerView.frame = containerRect;
#endif
        
        CGSize buttonSize = (CGSize){44.0,44.0};
        
        NSMutableArray *buttonsInOrderHorizontally = [NSMutableArray new];
        
        if (!self.clampButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.clampButton];
        }
        
        if (!self.rotateCounterclockwiseButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.rotateCounterclockwiseButton];
        }
        
        if (!self.flipHorizontalButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.flipHorizontalButton];
        }
               
        if (!self.flipVerticalButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.flipVerticalButton];
        }
               
        if (!self.rotateClockwiseButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.rotateClockwiseButton];
        }
        
        if (!self.resetButtonHidden) {
            [buttonsInOrderHorizontally addObject:self.resetButton];
        }
        [self layoutToolbarButtons:buttonsInOrderHorizontally withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:YES];
    }
    else {
        CGRect frame = CGRectZero;
        frame.size.height = 44.0;
        frame.size.width = 44.0;
        frame.origin.y = CGRectGetHeight(self.bounds) - 44.0;
        self.cancelIconButton.frame = frame;
        
        frame.origin.y = self.statusBarHeightInset;
        frame.size.width = 44.0;
        frame.size.height = 44.0;
        self.doneIconButton.frame = frame;
        
        CGRect containerRect = (CGRect){0,CGRectGetMaxY(self.doneIconButton.frame),44.0,CGRectGetMinY(self.cancelIconButton.frame)-CGRectGetMaxY(self.doneIconButton.frame)};
        
#if TOCROPTOOLBAR_DEBUG_SHOWING_BUTTONS_CONTAINER_RECT
        containerView.frame = containerRect;
#endif
        
        CGSize buttonSize = (CGSize){44.0,44.0};
        
        NSMutableArray *buttonsInOrderVertically = [NSMutableArray new];

        if (!self.clampButtonHidden) {
            [buttonsInOrderVertically addObject:self.clampButton];
        }
        
        if (!self.rotateClockwiseButtonHidden) {
            [buttonsInOrderVertically addObject:self.rotateClockwiseButton];
        }
        
        if (!self.rotateCounterclockwiseButtonHidden) {
            [buttonsInOrderVertically addObject:self.rotateCounterclockwiseButton];
        }
        
        if (!self.flipHorizontalButtonHidden) {
            [buttonsInOrderVertically addObject:self.flipHorizontalButton];
        }
               
        if (!self.flipVerticalButtonHidden) {
            [buttonsInOrderVertically addObject:self.flipVerticalButton];
        }
        
        if (!self.resetButtonHidden) {
            [buttonsInOrderVertically addObject:self.resetButton];
        }
        
        [self layoutToolbarButtons:buttonsInOrderVertically withSameButtonSize:buttonSize inContainerRect:containerRect horizontally:NO];
    }
}

// The convenience method for calculating button's frame inside of the container rect
- (void)layoutToolbarButtons:(NSArray *)buttons withSameButtonSize:(CGSize)size inContainerRect:(CGRect)containerRect horizontally:(BOOL)horizontally
{
    if (buttons.count > 0){
        NSInteger count = buttons.count;
        CGFloat fixedSize = horizontally ? size.width : size.height;
        CGFloat maxLength = horizontally ? CGRectGetWidth(containerRect) : CGRectGetHeight(containerRect);
        CGFloat padding = (maxLength - fixedSize * count) / (count + 1);
        
        for (NSInteger i = 0; i < count; i++) {
            UIButton *button = buttons[i];
            CGFloat sameOffset = horizontally ? fabs(CGRectGetHeight(containerRect)-44.0f) : fabs(CGRectGetWidth(containerRect)-size.width);
            CGFloat diffOffset = padding + i * (fixedSize + padding);
            CGPoint origin = horizontally ? CGPointMake(diffOffset, sameOffset) : CGPointMake(sameOffset, diffOffset);
            if (horizontally) {
                origin.x += CGRectGetMinX(containerRect);
                if (@available(iOS 15.0, *)) {
                    // iOS 15+: Use UIButtonConfiguration
                    UIButtonConfiguration *config = button.configuration ?: [UIButtonConfiguration plainButtonConfiguration];
                    
                    // Position image and text
                    config.imagePlacement = NSDirectionalRectEdgeLeading;
                    config.imagePadding = 8;
                    
                    UIImage *image = button.imageView.image;
                    config.contentInsets = NSDirectionalEdgeInsetsMake(0, 0, image.baselineOffsetFromBottom, 0);
                    
                    button.configuration = config;
                    
                } else if (@available(iOS 13.0, *)) {
                    UIImage *image = button.imageView.image;
                    button.imageEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, image.baselineOffsetFromBottom, 0.0);
                }
            } else {
                origin.y += CGRectGetMinY(containerRect);
            }
            button.frame = (CGRect){origin, size};
        }
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
    else if (button == self.rotateCounterclockwiseButton && self.rotateCounterclockwiseButtonTapped) {
        self.rotateCounterclockwiseButtonTapped();
    }
    else if (button == self.rotateClockwiseButton && self.rotateClockwiseButtonTapped) {
        self.rotateClockwiseButtonTapped();
    }
    else if (button == self.clampButton && self.clampButtonTapped) {
        self.clampButtonTapped();
        return;
    }
    else if (button == self.flipHorizontalButton && self.flipHorizontalButtonTapped) {
        self.flipHorizontalButtonTapped();
        return;
    }
    else if (button == self.flipVerticalButton && self.flipVerticalButtonTapped) {
        self.flipVerticalButtonTapped();
        return;
    }
}

- (CGRect)clampButtonFrame
{
    return self.clampButton.frame;
}

- (void)setReverseContentLayout:(BOOL)reverseContentLayout {
    if (_reverseContentLayout == reverseContentLayout)
        return;

    _reverseContentLayout = reverseContentLayout;
    [self setNeedsLayout];
}

- (void)setClampButtonHidden:(BOOL)clampButtonHidden {
    if (_clampButtonHidden == clampButtonHidden)
        return;
    
    _clampButtonHidden = clampButtonHidden;
    [self setNeedsLayout];
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

- (void)setRotateCounterClockwiseButtonHidden:(BOOL)rotateButtonHidden
{
    if (_rotateCounterclockwiseButtonHidden == rotateButtonHidden)
        return;
    
    _rotateCounterclockwiseButtonHidden = rotateButtonHidden;
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

- (void)setDoneButtonHidden:(BOOL)doneButtonHidden {
    if (_doneButtonHidden == doneButtonHidden)
        return;
    
    _doneButtonHidden = doneButtonHidden;
    [self setNeedsLayout];
}

- (void)setCancelButtonHidden:(BOOL)cancelButtonHidden {
    if (_cancelButtonHidden == cancelButtonHidden)
        return;
    
    _cancelButtonHidden = cancelButtonHidden;
    [self setNeedsLayout];
}

- (CGRect)doneButtonFrame
{
    if (self.doneIconButton.hidden == NO)
        return self.doneIconButton.frame;
    
    return self.doneTextButton.frame;
}

- (void)setShowOnlyIcons:(BOOL)showOnlyIcons {
    if (_showOnlyIcons == showOnlyIcons)
        return;

    _showOnlyIcons = showOnlyIcons;
    [_doneIconButton sizeToFit];
    [_cancelIconButton sizeToFit];
    [self setNeedsLayout];
}

- (void)setCancelTextButtonTitle:(NSString *)cancelTextButtonTitle {
    _cancelTextButtonTitle = cancelTextButtonTitle;
    [_cancelTextButton setTitle:_cancelTextButtonTitle forState:UIControlStateNormal];
    [_cancelTextButton sizeToFit];
}

- (void)setDoneTextButtonTitle:(NSString *)doneTextButtonTitle {
    _doneTextButtonTitle = doneTextButtonTitle;
    [_doneTextButton setTitle:_doneTextButtonTitle forState:UIControlStateNormal];
    [_doneTextButton sizeToFit];
}

- (void)setCancelButtonColor:(UIColor *)cancelButtonColor {
    // Default color is app tint color
    if (cancelButtonColor == _cancelButtonColor) { return; }
    _cancelButtonColor = cancelButtonColor;
    [_cancelTextButton setTitleColor:_cancelButtonColor forState:UIControlStateNormal];
    [_cancelIconButton setTintColor:_cancelButtonColor];
    [_cancelTextButton sizeToFit];
}

- (void)setDoneButtonColor:(UIColor *)doneButtonColor {
    // Set the default color when nil is specified
    if (doneButtonColor == nil) {
        doneButtonColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1.0];
    }

    if (doneButtonColor == _doneButtonColor) { return; }

    _doneButtonColor = doneButtonColor;
    [_doneTextButton setTitleColor:_doneButtonColor forState:UIControlStateNormal];
    [_doneIconButton setTintColor:_doneButtonColor];
    [_doneTextButton sizeToFit];
}

#pragma mark - Image Generation -
+ (UIImage *)doneImage
{
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"checkmark"
                       withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]];
    }
    return [UIImage imageNamed:@"checkmark"];
}

+ (UIImage *)cancelImage
{
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"xmark"
                       withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]];
    }
    return [UIImage imageNamed:@"xmark"];
}

+ (UIImage *)rotateCCWImage
{
    if (@available(iOS 13.0, *)) {
        return [[UIImage systemImageNamed:@"rotate.left.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]]
                imageWithBaselineOffsetFromBottom:4];
    }
    return [UIImage imageNamed:@"rotate.left.fill"];
}

+ (UIImage *)rotateCWImage
{
    if (@available(iOS 13.0, *)) {
        return [[UIImage systemImageNamed:@"rotate.right.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]]
                imageWithBaselineOffsetFromBottom:4];
    }
    return [UIImage imageNamed:@"rotate.right.fill"];
}

+ (UIImage *)flipHImage
{
    UIImage* image;
    if (@available(iOS 14.0, *)) {
        image = [UIImage systemImageNamed:@"arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]];
    } else {
        return [UIImage imageNamed:@"arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right.fill"];
    }
    if (@available(iOS 13.0, *)) {
        return [image imageWithBaselineOffsetFromBottom:4];
    } else {
        return image;
    }
}

+ (UIImage *)flipVImage
{
    UIImage* image;
    if (@available(iOS 14.0, *)) {
        image = [UIImage systemImageNamed:@"arrow.up.and.down.righttriangle.up.fill.righttriangle.down.fill"
                        withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]];
    } else {
        image = [UIImage imageNamed:@"arrow.trianglehead.up.and.down.righttriangle.up.righttriangle.down.fill"];
    }
    if (@available(iOS 13.0, *)) {
        return [image imageWithBaselineOffsetFromBottom:4];
    } else {
        return image;
    }
}

+ (UIImage *)resetImage
{
    if (@available(iOS 13.0, *)) {
        return [[UIImage systemImageNamed:@"arrow.counterclockwise"
                       withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]]
                imageWithBaselineOffsetFromBottom:1];
    }
    return [UIImage imageNamed:@"arrow.counterclockwise"];
}

+ (UIImage *)clampImage
{
    if (@available(iOS 13.1, *)) {
        return [[UIImage systemImageNamed:@"aspectratio.fill"
                       withConfiguration:[UIImageSymbolConfiguration configurationWithWeight:UIImageSymbolWeightSemibold]]
                imageWithBaselineOffsetFromBottom:0];
    }
    return [UIImage imageNamed:@"aspectratio.fill"];
}

#pragma mark - Accessors -

- (void)setRotateClockwiseButtonHidden:(BOOL)rotateClockwiseButtonHidden
{
    if (_rotateClockwiseButtonHidden == rotateClockwiseButtonHidden) {
        return;
    }
    
    _rotateClockwiseButtonHidden = rotateClockwiseButtonHidden;
    
    [self setNeedsLayout];
}

- (void)setResetButtonHidden:(BOOL)resetButtonHidden
{
    if (_resetButtonHidden == resetButtonHidden) {
        return;
    }
    
    _resetButtonHidden = resetButtonHidden;
    
    [self setNeedsLayout];
}
- (UIButton *)rotateButton
{
    return self.rotateCounterclockwiseButton;
}

- (void)setStatusBarHeightInset:(CGFloat)statusBarHeightInset
{
    _statusBarHeightInset = statusBarHeightInset;
    [self setNeedsLayout];
}

- (UIView *)visibleCancelButton
{
    if (self.cancelIconButton.hidden == NO) {
        return self.cancelIconButton;
    }

    return self.cancelTextButton;
}

@end
