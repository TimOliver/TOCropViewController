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

#import <UIKit/UIKit.h>

@interface TOCropToolbar : UIView

/* Button feedback handler blocks */
@property (nonatomic, copy) void (^cancelButtonTapped)(void);
@property (nonatomic, copy) void (^doneButtonTapped)(void);
@property (nonatomic, copy) void (^rotateButtonTapped)(void);
@property (nonatomic, copy) void (^clampButtonTapped)(void);
@property (nonatomic, copy) void (^resetButtonTapped)(void);

/* Aspect ratio button settings */
@property (nonatomic, assign) BOOL clampButtonGlowing;
@property (nonatomic, readonly) CGRect clampButtonFrame;

/* Disable the rotate button */
@property (nonatomic, assign) BOOL rotateButtonHidden;

/* Enable the reset button */
@property (nonatomic, assign) BOOL resetButtonEnabled;

/* Done button frame for popover controllers */
@property (nonatomic, readonly) CGRect doneButtonFrame;

@end
