//
//  TOCropToolbar.h
//
//  Copyright 2015-2016 Timothy Oliver. All rights reserved.
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

/* The 'Done' buttons to commit the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonatomic, strong, readonly) UIButton *doneTextButton;
@property (nonatomic, strong, readonly) UIButton *doneIconButton;

/* The 'Cancel' buttons to cancel the crop. The text button is displayed
 in portrait mode and the icon one, in landscape. */
@property (nonatomic, strong, readonly) UIButton *cancelTextButton;
@property (nonatomic, strong, readonly) UIButton *cancelIconButton;

/* The cropper control buttons */
@property (nonatomic, strong, readonly) UIButton *rotateCounterclockwiseButton;
@property (nonatomic, strong, readonly) UIButton *clampButton;
@property (nonatomic, strong, readonly) UIButton *rotateClockwiseButton;

@property (nonatomic, readonly) UIButton *rotateButton; // Points to `rotateCounterClockwiseButton`

/* Button feedback handler blocks */
@property (nonatomic, copy) void (^cancelButtonTapped)(void);
@property (nonatomic, copy) void (^doneButtonTapped)(void);
@property (nonatomic, copy) void (^rotateCounterclockwiseButtonTapped)(void);
@property (nonatomic, copy) void (^rotateClockwiseButtonTapped)(void);
@property (nonatomic, copy) void (^clampButtonTapped)(void);

/* Aspect ratio button settings */
@property (nonatomic, assign) BOOL clampButtonHidden;
@property (nonatomic, assign) BOOL clampButtonGlowing;
@property (nonatomic, readonly) CGRect clampButtonFrame;

@property (nonatomic, assign) BOOL rotateCounterClockwiseButtonHidden;
@property (nonatomic, assign) BOOL rotateClockwiseButtonHidden;

/* Enable the reset button */
@property (nonatomic, assign) BOOL resetButtonEnabled;

/* Done button frame for popover controllers */
@property (nonatomic, readonly) CGRect doneButtonFrame;


@end
