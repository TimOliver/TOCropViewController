//
//  TOCropToolbar.h
//
//  Copyright 2015-2018 Timothy Oliver. All rights reserved.
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

#import <UIKit/UIKit.h>
#import "TOCropViewConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface TOCropToolbar : UIView

/* In horizontal mode, offsets all of the buttons vertically by height of status bar. */
@property (nonatomic, assign) CGFloat statusBarHeightInset;

/* Set an inset that will expand the background view beyond the bounds. */
@property (nonatomic, assign) UIEdgeInsets backgroundViewOutsets;

/* The 'Done' buttons to commit the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonatomic, strong, readonly) UIButton *doneTextButton;
@property (nonatomic, strong, readonly) UIButton *doneIconButton;
@property (nonatomic, copy) NSString *doneTextButtonTitle;


/* The 'Cancel' buttons to cancel the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonatomic, strong, readonly) UIButton *cancelTextButton;
@property (nonatomic, strong, readonly) UIButton *cancelIconButton;
@property (nonatomic, readonly) UIView *visibleCancelButton;
@property (nonatomic, copy) NSString *cancelTextButtonTitle;

/* The cropper control buttons */
@property (nonatomic, strong, readonly)  UIButton *rotateCounterclockwiseButton;
@property (nonatomic, strong, readonly)  UIButton *resetButton;
@property (nonatomic, strong, readonly)  UIButton *clampButton;
@property (nullable, nonatomic, strong, readonly) UIButton *rotateClockwiseButton;

@property (nonatomic, readonly) UIButton *rotateButton; // Points to `rotateCounterClockwiseButton`

/* Button feedback handler blocks */
@property (nullable, nonatomic, copy) void (^cancelButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^doneButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^rotateCounterclockwiseButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^rotateClockwiseButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^clampButtonTapped)(void);
@property (nullable, nonatomic, copy) void (^resetButtonTapped)(void);

/* State management for the 'clamp' button */
@property (nonatomic, assign) BOOL clampButtonGlowing;
@property (nonatomic, readonly) CGRect clampButtonFrame;

/* Aspect ratio button visibility settings */
@property (nonatomic, assign) BOOL clampButtonHidden;
@property (nonatomic, assign) BOOL rotateCounterclockwiseButtonHidden;
@property (nonatomic, assign) BOOL rotateClockwiseButtonHidden;
@property (nonatomic, assign) BOOL resetButtonHidden;
@property (nonatomic, assign) BOOL doneButtonHidden;
@property (nonatomic, assign) BOOL cancelButtonHidden;

/* Enable the reset button */
@property (nonatomic, assign) BOOL resetButtonEnabled;

/* Done button frame for popover controllers */
@property (nonatomic, readonly) CGRect doneButtonFrame;

@end

NS_ASSUME_NONNULL_END
