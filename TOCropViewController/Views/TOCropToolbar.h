//
//  TOCropToolbar.h
//
//  Copyright 2015-2017 Timothy Oliver. All rights reserved.
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

@interface TOCropToolbar : UIView

/* In horizontal mode, offsets all of the buttons vertically by 20 points. */
@property (nonatomic, assign) BOOL statusBarVisible;

/* The 'Done' buttons to commit the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonnull, nonatomic, strong, readonly) UIButton *doneTextButton;
@property (nonnull, nonatomic, strong, readonly) UIButton *doneIconButton;

/* The 'Cancel' buttons to cancel the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonnull, nonatomic, strong, readonly) UIButton *cancelTextButton;
@property (nonnull, nonatomic, strong, readonly) UIButton *cancelIconButton;

/* The cropper control buttons */
@property (nonnull, nonatomic, strong, readonly) UIButton *rotateCounterclockwiseButton;
@property (nonnull, nonatomic, strong, readonly) UIButton *resetButton;
@property (nonnull, nonatomic, strong, readonly) UIButton *clampButton;
@property (nonnull, nonatomic, strong, readonly) UIButton *rotateClockwiseButton;

@property (nonnull, nonatomic, readonly) UIButton *rotateButton; // Points to `rotateCounterClockwiseButton`

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

/* Enable the reset button */
@property (nonatomic, assign) BOOL resetButtonEnabled;

/* Done button frame for popover controllers */
@property (nonatomic, readonly) CGRect doneButtonFrame;


@end
