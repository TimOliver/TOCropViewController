//
//  TOCropView.m
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

#import "TOCropView.h"
#import "TOCropOverlayView.h"
#import "TOCropScrollView.h"

#define TOCROPVIEW_BACKGROUND_COLOR [UIColor colorWithWhite:0.12f alpha:1.0f]

static const CGFloat kTOCropViewPadding = 14.0f;
static const NSTimeInterval kTOCropTimerDuration = 0.8f;
static const CGFloat kTOCropViewMinimumBoxSize = 42.0f;
static const CGFloat kTOCropViewCircularPathRadius = 300.0f;

/* When the user taps down to resize the box, this state is used
 to determine where they tapped and how to manipulate the box */
typedef NS_ENUM(NSInteger, TOCropViewOverlayEdge) {
    TOCropViewOverlayEdgeNone,
    TOCropViewOverlayEdgeTopLeft,
    TOCropViewOverlayEdgeTop,
    TOCropViewOverlayEdgeTopRight,
    TOCropViewOverlayEdgeRight,
    TOCropViewOverlayEdgeBottomRight,
    TOCropViewOverlayEdgeBottom,
    TOCropViewOverlayEdgeBottomLeft,
    TOCropViewOverlayEdgeLeft
};

@interface TOCropView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, assign, readwrite) TOCropViewCroppingStyle croppingStyle;

/* Views */
@property (nonatomic, strong) UIImageView *backgroundImageView;     /* The main image view, placed within the scroll view */
@property (nonatomic, strong) UIView *backgroundContainerView;      /* A view which contains the background image view, to separate its transforms from the scroll view. */
@property (nonatomic, strong) UIImageView *foregroundImageView;     /* A copy of the background image view, placed over the dimming views */
@property (nonatomic, strong) UIView *foregroundContainerView;      /* A container view that clips the foreground image view to the crop box frame */
@property (nonatomic, strong) TOCropScrollView *scrollView;         /* The scroll view in charge of panning/zooming the image. */
@property (nonatomic, strong) UIView *overlayView;                  /* A semi-transparent grey view, overlaid on top of the background image */
@property (nonatomic, strong) UIView *translucencyView;             /* A blur view that is made visible when the user isn't interacting with the crop view */
@property (nonatomic, strong) id translucencyEffect;                /* The dark blur visual effect applied to the visual effect view. */
@property (nonatomic, strong, readwrite) TOCropOverlayView *gridOverlayView;   /* A grid view overlaid on top of the foreground image view's container. */
@property (nonatomic, strong) CAShapeLayer *circularMaskLayer;      /* Managing the clipping of the foreground container into a circle */

/* Gesture Recognizers */
@property (nonatomic, strong) UIPanGestureRecognizer *gridPanGestureRecognizer; /* The gesture recognizer in charge of controlling the resizing of the crop view */

/* Crop box handling */
@property (nonatomic, assign) BOOL applyInitialCroppedImageFrame; /* No by default, when setting initialCroppedImageFrame this will be set to YES, and set back to NO after first application - so it's only done once */
@property (nonatomic, assign) TOCropViewOverlayEdge tappedEdge; /* The edge region that the user tapped on, to resize the cropping region */
@property (nonatomic, assign) CGRect cropOriginFrame;     /* When resizing, this is the original frame of the crop box. */
@property (nonatomic, assign) CGPoint panOriginPoint;     /* The initial touch point of the pan gesture recognizer */
@property (nonatomic, assign, readwrite) CGRect cropBoxFrame;  /* The frame, in relation to to this view where the grid, and crop container view are aligned */
@property (nonatomic, strong) NSTimer *resetTimer;  /* The timer used to reset the view after the user stops interacting with it */
@property (nonatomic, assign) BOOL editing;         /* Used to denote the active state of the user manipulating the content */
@property (nonatomic, assign) BOOL disableForgroundMatching; /* At times during animation, disable matching the forground image view to the background */

/* Pre-screen-rotation state information */
@property (nonatomic, assign) CGPoint rotationContentOffset;
@property (nonatomic, assign) CGSize  rotationContentSize;
@property (nonatomic, assign) CGSize  rotationBoundSize;

/* View State information */
@property (nonatomic, readonly) CGRect contentBounds; /* Give the current screen real-estate, the frame that the scroll view is allowed to use */
@property (nonatomic, readonly) CGSize imageSize;     /* Given the current rotation of the image, the size of the image */
@property (nonatomic, readonly) BOOL hasAspectRatio;  /* True if an aspect ratio was explicitly applied to this crop view */

/* 90-degree rotation state data */
@property (nonatomic, assign) BOOL applyInitialRotatedAngle; /* No by default, when setting initialRotatedAngle this will be set to YES, and set back to NO after first application - so it's only done once */
@property (nonatomic, assign) CGSize cropBoxLastEditedSize; /* When performing 90-degree rotations, remember what our last manual size was to use that as a base */
@property (nonatomic, assign) NSInteger cropBoxLastEditedAngle; /* Remember which angle we were at when we saved the editing size */
@property (nonatomic, assign) CGFloat cropBoxLastEditedZoomScale; /* Remember the zoom size when we last edited */
@property (nonatomic, assign) CGFloat cropBoxLastEditedMinZoomScale; /* Remember the minimum size when we last edited. */
@property (nonatomic, assign) BOOL rotateAnimationInProgress;   /* Disallow any input while the rotation animation is playing */

/* Reset state data */
@property (nonatomic, assign) CGSize originalCropBoxSize; /* Save the original crop box size so we can tell when the content has been edited */
@property (nonatomic, assign) CGPoint originalContentOffset; /* Save the original content offset so we can tell if it's been scrolled. */
@property (nonatomic, assign, readwrite) BOOL canBeReset;

/* In iOS 9, a new dynamic blur effect became available. */
@property (nonatomic, assign) BOOL dynamicBlurEffect;

/* If restoring to  a previous crop setting, these properties hang onto the
 values until the view is configured for the first time. */
@property (nonatomic, assign) NSInteger restoreAngle;
@property (nonatomic, assign) CGRect    restoreImageCropFrame;

- (void)setup;

/* Image layout */
- (void)layoutInitialImage;
- (void)matchForegroundToBackground;

/* Crop box handling */
- (TOCropViewOverlayEdge)cropEdgeForPoint:(CGPoint)point;
- (void)updateCropBoxFrameWithGesturePoint:(CGPoint)point;
- (void)toggleTranslucencyViewVisible:(BOOL)visible;
- (void)updateToImageCropFrame:(CGRect)imageCropframe;

/* Editing state */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)startEditing;

/* Timer handling */
- (void)startResetTimer;
- (void)timerTriggered;
- (void)cancelResetTimer;

/* Gesture Recognizers */
- (void)gridPanGestureRecognized:(UIPanGestureRecognizer *)recognizer;
- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)recognizer;

/* Reset state */
- (void)checkForCanReset;

/* Capture rotation state (for 90-degree rotation) */
- (void)captureStateForImageRotation;

@end

@implementation TOCropView

- (instancetype)initWithCroppingStyle:(TOCropViewCroppingStyle)style image:(UIImage *)image
{
    if (self = [super init]) {
        _image = image;
        _croppingStyle = style;
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    return [self initWithCroppingStyle:TOCropViewCroppingStyleDefault image:image];
}

- (void)setup
{
    __weak typeof(self) weakSelf = self;
    
    BOOL circularMode = (self.croppingStyle == TOCropViewCroppingStyleCircular);
    
    //View properties
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.backgroundColor = TOCROPVIEW_BACKGROUND_COLOR;
    self.cropBoxFrame = CGRectZero;
    self.applyInitialCroppedImageFrame = NO;
    self.editing = NO;
    self.cropBoxResizeEnabled = !circularMode;
    self.aspectRatio = circularMode ? (CGSize){1.0f, 1.0f} : CGSizeZero;
    self.resetAspectRatioEnabled = !circularMode;
    self.restoreImageCropFrame = CGRectZero;
    self.restoreAngle = 0;
    
    /* Dynamic animation blurring is only possible on iOS 9, however since the API was available on iOS 8,
     we'll need to manually check the system version to ensure that it's available. */
    self.dynamicBlurEffect = ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending);
    
    //Scroll View properties
    self.scrollView = [[TOCropScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    [self addSubview:self.scrollView];

    self.scrollView.touchesBegan = ^{ [weakSelf startEditing]; };
    self.scrollView.touchesEnded = ^{ [weakSelf startResetTimer]; };
    
    //Background Image View
    self.backgroundImageView = [[UIImageView alloc] initWithImage:self.image];

    //Background container view
    self.backgroundContainerView = [[UIView alloc] initWithFrame:self.backgroundImageView.frame];
    [self.backgroundContainerView addSubview:self.backgroundImageView];
    [self.scrollView addSubview:self.backgroundContainerView];
    
    //Grey transparent overlay view
    self.overlayView = [[UIView alloc] initWithFrame:self.bounds];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.overlayView.backgroundColor = [self.backgroundColor colorWithAlphaComponent:0.35f];
    self.overlayView.hidden = NO;
    self.overlayView.userInteractionEnabled = NO;
    [self addSubview:self.overlayView];
    
    //Translucency View
    if (NSClassFromString(@"UIVisualEffectView")) {
        self.translucencyEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.translucencyView = [[UIVisualEffectView alloc] initWithEffect:self.translucencyEffect];
        self.translucencyView.frame = self.bounds;
    }
    else {
        UIToolbar *toolbar = [[UIToolbar alloc] init];
        toolbar.barStyle = UIBarStyleBlack;
        self.translucencyView = toolbar;
        self.translucencyView.frame = CGRectInset(self.bounds, -1.0f, -1.0f);
    }
    self.translucencyView.hidden = NO;
    self.translucencyView.userInteractionEnabled = NO;
    self.translucencyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.translucencyView];
    
    // The forground container that holds the foreground image view
    self.foregroundContainerView = [[UIView alloc] initWithFrame:(CGRect){0,0,200,200}];
    self.foregroundContainerView.clipsToBounds = YES;
    self.foregroundContainerView.userInteractionEnabled = NO;
    [self addSubview:self.foregroundContainerView];
    
    self.foregroundImageView = [[UIImageView alloc] initWithImage:self.image];
    [self.foregroundContainerView addSubview:self.foregroundImageView];
    
    // The following setup isn't needed during circular cropping
    if (circularMode) {
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:(CGRect){0,0,kTOCropViewCircularPathRadius, kTOCropViewCircularPathRadius}];
        self.circularMaskLayer = [[CAShapeLayer alloc] init];
        self.circularMaskLayer.path = circlePath.CGPath;
        self.foregroundContainerView.layer.mask = self.circularMaskLayer;
        
        return;
    }
    
    // The white grid overlay view
    self.gridOverlayView = [[TOCropOverlayView alloc] initWithFrame:self.foregroundContainerView.frame];
    self.gridOverlayView.userInteractionEnabled = NO;
    self.gridOverlayView.gridHidden = YES;
    [self addSubview:self.gridOverlayView];
    
    // The pan controller to recognize gestures meant to resize the grid view
    self.gridPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gridPanGestureRecognized:)];
    self.gridPanGestureRecognizer.delegate = self;
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.gridPanGestureRecognizer];
    [self addGestureRecognizer:self.gridPanGestureRecognizer];
}

#pragma mark - View Layout -
- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    //Since this also gets called when getting removed from the superview
    if (self.superview == nil) {
        return;
    }
    
    //Perform the initial layout of the image
    [self layoutInitialImage];
    
    // -- State Restoration --
    
    //If the angle value was previously set before this point, apply it now
    if (self.restoreAngle != 0) {
        self.angle = self.restoreAngle;
        self.restoreAngle = 0;
    }
    
    //If an image crop frame was also specified before creation, apply it now
    if (!CGRectIsEmpty(self.restoreImageCropFrame)) {
        self.imageCropFrame = self.restoreImageCropFrame;
        self.restoreImageCropFrame = CGRectZero;
    }
    
    //Check if we performed any resetabble modifications
    [self checkForCanReset];
}

- (void)layoutInitialImage
{
    CGSize imageSize = self.imageSize;
    self.scrollView.contentSize = imageSize;
    
    CGRect bounds = self.contentBounds;
    CGSize boundsSize = bounds.size;

    //work out the minimum scale of the object
    CGFloat scale = 0.0f;
    
    // Work out the size of the image to fit into the content bounds
    scale = MIN(CGRectGetWidth(bounds)/imageSize.width, CGRectGetHeight(bounds)/imageSize.height);
    CGSize scaledImageSize = (CGSize){floorf(imageSize.width * scale), floorf(imageSize.height * scale)};
    
    // If an aspect ratio was pre-applied to the crop view, use that to work out the minimum scale the image needs to be to fit
    CGSize cropBoxSize = CGSizeZero;
    if (self.hasAspectRatio) {
        CGFloat ratioScale = (self.aspectRatio.width / self.aspectRatio.height); //Work out the size of the width in relation to height
        CGSize fullSizeRatio = (CGSize){boundsSize.height * ratioScale, boundsSize.height};
        CGFloat fitScale = MIN(boundsSize.width/fullSizeRatio.width, boundsSize.height/fullSizeRatio.height);
        cropBoxSize = (CGSize){fullSizeRatio.width * fitScale, fullSizeRatio.height * fitScale};
        
        scale = MAX(cropBoxSize.width/imageSize.width, cropBoxSize.height/imageSize.height);
    }

    //Whether aspect ratio, or original, the final image size we'll base the rest of the calculations off
    CGSize scaledSize = (CGSize){floorf(imageSize.width * scale), floorf(imageSize.height * scale)};
    
    // Configure the scroll view
    self.scrollView.minimumZoomScale = scale;
    self.scrollView.maximumZoomScale = 15.0f;

    //Set the crop box to the size we calculated and align in the middle of the screen
    CGRect frame = CGRectZero;
    frame.size = self.hasAspectRatio ? cropBoxSize : scaledSize;
    frame.origin.x = bounds.origin.x + floorf((CGRectGetWidth(bounds) - frame.size.width) * 0.5f);
    frame.origin.y = bounds.origin.y + floorf((CGRectGetHeight(bounds) - frame.size.height) * 0.5f);
    self.cropBoxFrame = frame;
    
    //set the fully zoomed out state initially
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
    self.scrollView.contentSize = scaledSize;
    
    // If we ended up with a smaller crop box than the content, offset it in the middle
    if (frame.size.width < scaledSize.width - FLT_EPSILON || frame.size.height < scaledSize.height - FLT_EPSILON) {
        CGPoint offset = CGPointZero;
        offset.x = -floorf((CGRectGetWidth(self.scrollView.frame) - scaledSize.width) * 0.5f);
        offset.y = -floorf((CGRectGetHeight(self.scrollView.frame) - scaledSize.height) * 0.5f);
        self.scrollView.contentOffset = offset;
    }

    //save the current state for use with 90-degree rotations
    self.cropBoxLastEditedAngle = 0;
    [self captureStateForImageRotation];
    
    //save the size for checking if we're in a resettable state
    self.originalCropBoxSize = self.resetAspectRatioEnabled ? scaledImageSize : cropBoxSize;
    self.originalContentOffset = self.scrollView.contentOffset;
    
    [self checkForCanReset];
    [self matchForegroundToBackground];
}

- (void)prepareforRotation
{
    self.rotationContentOffset = self.scrollView.contentOffset;
    self.rotationContentSize   = self.scrollView.contentSize;
    self.rotationBoundSize     = self.scrollView.bounds.size;
}

- (void)performRelayoutForRotation
{
    CGRect cropFrame = self.cropBoxFrame;
    CGRect contentFrame = self.contentBounds;
 
    CGFloat scale = MIN(contentFrame.size.width / cropFrame.size.width, contentFrame.size.height / cropFrame.size.height);
    self.scrollView.minimumZoomScale *= scale;
    self.scrollView.zoomScale *= scale;
    
    //Work out the centered, upscaled version of the crop rectangle
    cropFrame.size.width  = floorf(cropFrame.size.width * scale);
    cropFrame.size.height = floorf(cropFrame.size.height * scale);
    cropFrame.origin.x    = floorf(contentFrame.origin.x + ((contentFrame.size.width - cropFrame.size.width) * 0.5f));
    cropFrame.origin.y    = floorf(contentFrame.origin.y + ((contentFrame.size.height - cropFrame.size.height) * 0.5f));
    self.cropBoxFrame = cropFrame;
    
    [self captureStateForImageRotation];
    
    //Work out the center point of the content before we rotated
    CGPoint oldMidPoint = (CGPoint){self.rotationBoundSize.width * 0.5f, self.rotationBoundSize.height * 0.5f};
    CGPoint contentCenter = (CGPoint){self.rotationContentOffset.x + oldMidPoint.x, self.rotationContentOffset.y + oldMidPoint.y};
    
    //Normalize it to a percentage we can apply to different sizes
    CGPoint normalizedCenter = CGPointZero;
    normalizedCenter.x = contentCenter.x / self.rotationContentSize.width;
    normalizedCenter.y = contentCenter.y / self.rotationContentSize.height;
    
    //Work out the new content offset by applying the normalized values to the new layout
    CGPoint newMidPoint = (CGPoint){self.scrollView.bounds.size.width * 0.5f,
                                    self.scrollView.bounds.size.height * 0.5f};
    
    CGPoint translatedContentOffset = CGPointZero;
    translatedContentOffset.x = self.scrollView.contentSize.width * normalizedCenter.x;
    translatedContentOffset.y = self.scrollView.contentSize.height * normalizedCenter.y;
    
    CGPoint offset = CGPointZero;
    offset.x = floorf(translatedContentOffset.x - newMidPoint.x);
    offset.y = floorf(translatedContentOffset.y - newMidPoint.y);
    
    //Make sure it doesn't overshoot the top left corner of the crop box
    offset.x = MAX(-self.scrollView.contentInset.left, offset.x);
    offset.y = MAX(-self.scrollView.contentInset.top, offset.y);

    //Nor undershoot the bottom right corner
    CGPoint maximumOffset = CGPointZero;
    maximumOffset.x = (self.bounds.size.width - self.scrollView.contentInset.right) + self.scrollView.contentSize.width;
    maximumOffset.y = (self.bounds.size.height - self.scrollView.contentInset.bottom) + self.scrollView.contentSize.height;
    offset.x = MIN(offset.x, maximumOffset.x);
    offset.y = MIN(offset.y, maximumOffset.y);
    self.scrollView.contentOffset = offset;
    
    //Line up the background instance of the image
    [self matchForegroundToBackground];
}

- (void)matchForegroundToBackground
{
    if (self.disableForgroundMatching)
        return;
    
    //We can't simply match the frames since if the images are rotated, the frame property becomes unusable
    self.foregroundImageView.frame = [self.backgroundContainerView.superview convertRect:self.backgroundContainerView.frame toView:self.foregroundContainerView];
}

- (void)updateCropBoxFrameWithGesturePoint:(CGPoint)point
{
    CGRect frame = self.cropBoxFrame;
    CGRect originFrame = self.cropOriginFrame;
    CGRect contentFrame = self.contentBounds;
    
    point.x = MAX(contentFrame.origin.x, point.x);
    point.y = MAX(contentFrame.origin.y, point.y);
    
    //The delta between where we first tapped, and where our finger is now
    CGFloat xDelta = ceilf(point.x - self.panOriginPoint.x);
    CGFloat yDelta = ceilf(point.y - self.panOriginPoint.y);
    
    //Current aspect ratio of the crop box in case we need to clamp it
    CGFloat aspectRatio = (originFrame.size.width / originFrame.size.height);

    //Note whether we're being aspect transformed horizontally or vertically
    BOOL aspectHorizontal = NO, aspectVertical = NO;
    
    //Depending on which corner we drag from, set the appropriate min flag to
    //ensure we can properly clamp the XY value of the box if it overruns the minimum size
    //(Otherwise the image itself will slide with the drag gesture)
    BOOL clampMinFromTop = NO, clampMinFromLeft = NO;
    
    switch (self.tappedEdge) {
        case TOCropViewOverlayEdgeLeft:
            if (self.aspectRatioLockEnabled) {
                aspectHorizontal = YES;
                xDelta = MAX(xDelta, 0);
                CGPoint scaleOrigin = (CGPoint){CGRectGetMaxX(originFrame), CGRectGetMidY(originFrame)};
                frame.size.height = frame.size.width / aspectRatio;
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5f);
            }
            
            frame.origin.x   = originFrame.origin.x + xDelta;
            frame.size.width = originFrame.size.width - xDelta;
            
            clampMinFromLeft = YES;
            
            break;
        case TOCropViewOverlayEdgeRight:
            if (self.aspectRatioLockEnabled) {
                aspectHorizontal = YES;
                CGPoint scaleOrigin = (CGPoint){CGRectGetMinX(originFrame), CGRectGetMidY(originFrame)};
                frame.size.height = frame.size.width / aspectRatio;
                frame.origin.y = scaleOrigin.y - (frame.size.height * 0.5f);
                frame.size.width = originFrame.size.width + xDelta;
                frame.size.width = MIN(frame.size.width, contentFrame.size.height * aspectRatio);
            }
            else {
                frame.size.width = originFrame.size.width + xDelta;
            }
            
            break;
        case TOCropViewOverlayEdgeBottom:
            if (self.aspectRatioLockEnabled) {
                aspectVertical = YES;
                CGPoint scaleOrigin = (CGPoint){CGRectGetMidX(originFrame), CGRectGetMinY(originFrame)};
                frame.size.width = frame.size.height * aspectRatio;
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5f);
                frame.size.height = originFrame.size.height + yDelta;
                frame.size.height = MIN(frame.size.height, contentFrame.size.width / aspectRatio);
            }
            else {
                frame.size.height = originFrame.size.height + yDelta;
            }
            break;
        case TOCropViewOverlayEdgeTop:
            if (self.aspectRatioLockEnabled) {
                aspectVertical = YES;
                yDelta = MAX(0,yDelta);
                CGPoint scaleOrigin = (CGPoint){CGRectGetMidX(originFrame), CGRectGetMaxY(originFrame)};
                frame.size.width = frame.size.height * aspectRatio;
                frame.origin.x = scaleOrigin.x - (frame.size.width * 0.5f);
                frame.origin.y    = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
            }
            else {
                frame.origin.y    = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
            }
            
            clampMinFromTop = YES;
            
            break;
        case TOCropViewOverlayEdgeTopLeft:
            if (self.aspectRatioLockEnabled) {
                xDelta = MAX(xDelta, 0);
                yDelta = MAX(yDelta, 0);
                
                CGPoint distance;
                distance.x = 1.0f - (xDelta / CGRectGetWidth(originFrame));
                distance.y = 1.0f - (yDelta / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                frame.origin.x = originFrame.origin.x + (CGRectGetWidth(originFrame) - frame.size.width);
                frame.origin.y = originFrame.origin.y + (CGRectGetHeight(originFrame) - frame.size.height);
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                frame.origin.x   = originFrame.origin.x + xDelta;
                frame.size.width = originFrame.size.width - xDelta;
                frame.origin.y   = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
            }
            
            clampMinFromTop = YES;
            clampMinFromLeft = YES;
            
            break;
        case TOCropViewOverlayEdgeTopRight:
            if (self.aspectRatioLockEnabled) {
                xDelta = MIN(xDelta, 0);
                yDelta = MAX(yDelta, 0);
                
                CGPoint distance;
                distance.x = 1.0f - ((-xDelta) / CGRectGetWidth(originFrame));
                distance.y = 1.0f - ((yDelta) / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                frame.origin.y = originFrame.origin.y + (CGRectGetHeight(originFrame) - frame.size.height);
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                frame.size.width  = originFrame.size.width + xDelta;
                frame.origin.y    = originFrame.origin.y + yDelta;
                frame.size.height = originFrame.size.height - yDelta;
            }
            
            clampMinFromTop = YES;
            
            break;
        case TOCropViewOverlayEdgeBottomLeft:
            if (self.aspectRatioLockEnabled) {
                CGPoint distance;
                distance.x = 1.0f - (xDelta / CGRectGetWidth(originFrame));
                distance.y = 1.0f - (-yDelta / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                frame.origin.x = CGRectGetMaxX(originFrame) - frame.size.width;
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                frame.size.height = originFrame.size.height + yDelta;
                frame.origin.x    = originFrame.origin.x + xDelta;
                frame.size.width  = originFrame.size.width - xDelta;
            }
            
            clampMinFromLeft = YES;
            
            break;
        case TOCropViewOverlayEdgeBottomRight:
            if (self.aspectRatioLockEnabled) {
                
                CGPoint distance;
                distance.x = 1.0f - ((-1 * xDelta) / CGRectGetWidth(originFrame));
                distance.y = 1.0f - ((-1 * yDelta) / CGRectGetHeight(originFrame));
                
                CGFloat scale = (distance.x + distance.y) * 0.5f;
                
                frame.size.width = ceilf(CGRectGetWidth(originFrame) * scale);
                frame.size.height = ceilf(CGRectGetHeight(originFrame) * scale);
                
                aspectVertical = YES;
                aspectHorizontal = YES;
            }
            else {
                frame.size.height = originFrame.size.height + yDelta;
                frame.size.width = originFrame.size.width + xDelta;
            }
            break;
        case TOCropViewOverlayEdgeNone: break;
    }
    
    //The absolute max/min size the box may be in the bounds of the crop view
    CGSize minSize = (CGSize){kTOCropViewMinimumBoxSize, kTOCropViewMinimumBoxSize};
    CGSize maxSize = (CGSize){CGRectGetWidth(contentFrame), CGRectGetHeight(contentFrame)};
    
    //clamp the box to ensure it doesn't go beyond the bounds we've set
    if (self.aspectRatioLockEnabled && aspectHorizontal) {
        maxSize.height = contentFrame.size.width / aspectRatio;
        minSize.width = kTOCropViewMinimumBoxSize * aspectRatio;
    }
        
    if (self.aspectRatioLockEnabled && aspectVertical) {
        maxSize.width = contentFrame.size.height * aspectRatio;
        minSize.height = kTOCropViewMinimumBoxSize / aspectRatio;
    }
    
    //Clamp the minimum size
    frame.size.width  = MAX(frame.size.width, minSize.width);
    frame.size.height = MAX(frame.size.height, minSize.height);
    
    //Clamp the maximum size
    frame.size.width  = MIN(frame.size.width, maxSize.width);
    frame.size.height = MIN(frame.size.height, maxSize.height);
    
    //Clamp the X position of the box to the interior of the cropping bounds
    frame.origin.x = MAX(frame.origin.x, CGRectGetMinX(contentFrame));
    frame.origin.x = MIN(frame.origin.x, CGRectGetMaxX(contentFrame) - minSize.width);

    //Clamp the Y postion of the box to the interior of the cropping bounds
    frame.origin.y = MAX(frame.origin.y, CGRectGetMinY(contentFrame));
    frame.origin.y = MIN(frame.origin.y, CGRectGetMaxY(contentFrame) - minSize.height);
    
    //Once the box is completely shrunk, clamp its ability to move
    if (clampMinFromLeft && frame.size.width <= minSize.width + FLT_EPSILON) {
        frame.origin.x = CGRectGetMaxX(originFrame) - minSize.width;
    }
    
    //Once the box is completely shrunk, clamp its ability to move
    if (clampMinFromTop && frame.size.height <= minSize.height + FLT_EPSILON) {
        frame.origin.y = CGRectGetMaxY(originFrame) - minSize.height;
    }
    
    self.cropBoxFrame = frame;
    
    [self checkForCanReset];
}

- (void)resetLayoutToDefaultAnimated:(BOOL)animated
{
    // If resetting the crop view includes resetting the aspect ratio,
    // reset it to zero here. But set the ivar directly since there's no point
    // in performing the relayout calculations right before a reset.
    if (self.hasAspectRatio && self.resetAspectRatioEnabled) {
        _aspectRatio = CGSizeZero;
    }
    
    if (animated == NO || self.angle != 0) {
        //Reset all of the rotation transforms
        _angle = 0;

        //Set the scroll to 1.0f to reset the transform scale
        self.scrollView.zoomScale = 1.0f;
        
        CGRect imageRect = (CGRect){CGPointZero, self.image.size};
        
        //Reset everything about the background container and image views
        self.backgroundImageView.transform = CGAffineTransformIdentity;
        self.backgroundContainerView.transform = CGAffineTransformIdentity;
        self.backgroundImageView.frame = imageRect;
        self.backgroundContainerView.frame = imageRect;

        //Reset the transform ans size of just the foreground image
        self.foregroundImageView.transform = CGAffineTransformIdentity;
        self.foregroundImageView.frame = imageRect;
        
        //Reset the layout
        [self layoutInitialImage];
        
        //Enable / Disable the reset button
        [self checkForCanReset];
        
        return;
    }

    //If we were in the middle of a reset timer, cancel it as we'll
    //manually perform a restoration animation here
    if (self.resetTimer) {
        [self cancelResetTimer];
        [self setEditing:NO animated:NO];
    }
   
    [self setSimpleRenderMode:YES animated:NO];
    
    //Perform an animation of the image zooming back out to its original size
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:1.0f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self layoutInitialImage];
        } completion:^(BOOL complete) {
            [self setSimpleRenderMode:NO animated:YES];
        }];
    });
}

- (void)toggleTranslucencyViewVisible:(BOOL)visible
{
    if (self.dynamicBlurEffect == NO) {
        self.translucencyView.alpha = visible ? 1.0f : 0.0f;
    }
    else {
        [(UIVisualEffectView *)self.translucencyView setEffect:visible ? self.translucencyEffect : nil];
    }
}

- (void)updateToImageCropFrame:(CGRect)imageCropframe
{
    //Convert the image crop frame's size from image space to the screen space
    CGFloat minimumSize = self.scrollView.minimumZoomScale;
    CGPoint scaledOffset = (CGPoint){imageCropframe.origin.x * minimumSize, imageCropframe.origin.y * minimumSize};
    CGSize scaledCropSize = (CGSize){imageCropframe.size.width * minimumSize, imageCropframe.size.height * minimumSize};
    
    // Work out the scale necessary to upscale the crop size to fit the content bounds of the crop bound
    CGRect bounds = self.contentBounds;
    CGFloat scale = MIN(bounds.size.width / scaledCropSize.width, bounds.size.height / scaledCropSize.height);
    
    // Zoom into the scroll view to the appropriate size
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale * scale;
    
    // Work out the size and offset of the upscaed crop box
    CGRect frame = CGRectZero;
    frame.size = (CGSize){scaledCropSize.width * scale, scaledCropSize.height * scale};
    
    //set the crop box
    CGRect cropBoxFrame = CGRectZero;
    cropBoxFrame.size = frame.size;
    cropBoxFrame.origin.x = (self.bounds.size.width - frame.size.width) * 0.5f;
    cropBoxFrame.origin.y = (self.bounds.size.height - frame.size.height) * 0.5f;
    self.cropBoxFrame = cropBoxFrame;
    
    frame.origin.x = (scaledOffset.x * scale) - self.scrollView.contentInset.left;
    frame.origin.y = (scaledOffset.y * scale) - self.scrollView.contentInset.top;
    self.scrollView.contentOffset = frame.origin;
}

#pragma mark - Gesture Recognizer -
- (void)gridPanGestureRecognized:(UIPanGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self startEditing];
        self.panOriginPoint = point;
        self.cropOriginFrame = self.cropBoxFrame;
        self.tappedEdge = [self cropEdgeForPoint:self.panOriginPoint];
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
        [self startResetTimer];
    
    [self updateCropBoxFrameWithGesturePoint:point];
}

- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
        [self.gridOverlayView setGridHidden:NO animated:YES];
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
        [self.gridOverlayView setGridHidden:YES animated:YES];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer != self.gridPanGestureRecognizer)
        return YES;
    
    CGPoint tapPoint = [gestureRecognizer locationInView:self];
    
    CGRect frame = self.gridOverlayView.frame;
    CGRect innerFrame = CGRectInset(frame, 22.0f, 22.0f);
    CGRect outerFrame = CGRectInset(frame, -22.0f, -22.0f);
    
    if (CGRectContainsPoint(innerFrame, tapPoint) || !CGRectContainsPoint(outerFrame, tapPoint))
        return NO;
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.gridPanGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        return NO;
    }
    return YES;
}

#pragma mark - Timer -
- (void)startResetTimer
{
    if (self.resetTimer)
        return;
    
    self.resetTimer = [NSTimer scheduledTimerWithTimeInterval:kTOCropTimerDuration target:self selector:@selector(timerTriggered) userInfo:nil repeats:NO];
}

- (void)timerTriggered
{
    [self setEditing:NO animated:YES];
    [self.resetTimer invalidate];
    self.resetTimer = nil;
}

- (void)cancelResetTimer
{
    [self.resetTimer invalidate];
    self.resetTimer = nil;
}

- (TOCropViewOverlayEdge)cropEdgeForPoint:(CGPoint)point
{
    CGRect frame = self.cropBoxFrame;
    
    //account for padding around the box
    frame = CGRectInset(frame, -32.0f, -32.0f);
    
    //Make sure the corners take priority
    CGRect topLeftRect = (CGRect){frame.origin, {64,64}};
    if (CGRectContainsPoint(topLeftRect, point))
        return TOCropViewOverlayEdgeTopLeft;
    
    CGRect topRightRect = topLeftRect;
    topRightRect.origin.x = CGRectGetMaxX(frame) - 64.0f;
    if (CGRectContainsPoint(topRightRect, point))
        return TOCropViewOverlayEdgeTopRight;
    
    CGRect bottomLeftRect = topLeftRect;
    bottomLeftRect.origin.y = CGRectGetMaxY(frame) - 64.0f;
    if (CGRectContainsPoint(bottomLeftRect, point))
        return TOCropViewOverlayEdgeBottomLeft;
    
    CGRect bottomRightRect = topRightRect;
    bottomRightRect.origin.y = bottomLeftRect.origin.y;
    if (CGRectContainsPoint(bottomRightRect, point))
        return TOCropViewOverlayEdgeBottomRight;
    
    //Check for edges
    CGRect topRect = (CGRect){frame.origin, {CGRectGetWidth(frame), 64.0f}};
    if (CGRectContainsPoint(topRect, point))
        return TOCropViewOverlayEdgeTop;
    
    CGRect bottomRect = topRect;
    bottomRect.origin.y = CGRectGetMaxY(frame) - 64.0f;
    if (CGRectContainsPoint(bottomRect, point))
        return TOCropViewOverlayEdgeBottom;
    
    CGRect leftRect = (CGRect){frame.origin, {64.0f, CGRectGetHeight(frame)}};
    if (CGRectContainsPoint(leftRect, point))
        return TOCropViewOverlayEdgeLeft;
    
    CGRect rightRect = leftRect;
    rightRect.origin.x = CGRectGetMaxX(frame) - 64.0f;
    if (CGRectContainsPoint(rightRect, point))
        return TOCropViewOverlayEdgeRight;
    
    return TOCropViewOverlayEdgeNone;
}

#pragma mark - Scroll View Delegate -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView { return self.backgroundContainerView; }
- (void)scrollViewDidScroll:(UIScrollView *)scrollView            { [self matchForegroundToBackground]; }

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self startEditing];
    self.canBeReset = YES;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    [self startEditing];
    self.canBeReset = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self startResetTimer];
    [self checkForCanReset];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [self startResetTimer];
    [self checkForCanReset];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    if (scrollView.isTracking) {
        self.cropBoxLastEditedZoomScale = scrollView.zoomScale;
        self.cropBoxLastEditedMinZoomScale = scrollView.minimumZoomScale;
    }
    
    [self matchForegroundToBackground];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        [self startResetTimer];
}

#pragma mark - Accessors -

- (void)setCropBoxResizeEnabled:(BOOL)panResizeEnabled {
    _cropBoxResizeEnabled = panResizeEnabled;
    self.gridPanGestureRecognizer.enabled = _cropBoxResizeEnabled;
}

- (void)setCropBoxFrame:(CGRect)cropBoxFrame
{
    if (CGRectEqualToRect(cropBoxFrame, _cropBoxFrame))
        return;
    
    //Upon init, sometimes the box size is still 0, which can result in CALayer issues
    if (cropBoxFrame.size.width < FLT_EPSILON || cropBoxFrame.size.height < FLT_EPSILON)
        return;
    
    //clamp the cropping region to the inset boundaries of the screen
    CGRect contentFrame = self.contentBounds;
    CGFloat xOrigin = ceilf(contentFrame.origin.x);
    CGFloat xDelta = cropBoxFrame.origin.x - xOrigin;
    cropBoxFrame.origin.x = floorf(MAX(cropBoxFrame.origin.x, xOrigin));
    if (xDelta < -FLT_EPSILON) //If we clamp the x value, ensure we compensate for the subsequent delta generated in the width (Or else, the box will keep growing)
        cropBoxFrame.size.width += xDelta;
    
    CGFloat yOrigin = ceilf(contentFrame.origin.y);
    CGFloat yDelta = cropBoxFrame.origin.y - yOrigin;
    cropBoxFrame.origin.y = floorf(MAX(cropBoxFrame.origin.y, yOrigin));
    if (yDelta < -FLT_EPSILON)
        cropBoxFrame.size.height += yDelta;
    
    //given the clamped X/Y values, make sure we can't extend the crop box beyond the edge of the screen in the current state
    CGFloat maxWidth = (contentFrame.size.width + contentFrame.origin.x) - cropBoxFrame.origin.x;
    cropBoxFrame.size.width = floorf(MIN(cropBoxFrame.size.width, maxWidth));
    
    CGFloat maxHeight = (contentFrame.size.height + contentFrame.origin.y) - cropBoxFrame.origin.y;
    cropBoxFrame.size.height = floorf(MIN(cropBoxFrame.size.height, maxHeight));
    
    //Make sure we can't make the crop box too small
    cropBoxFrame.size.width  = MAX(cropBoxFrame.size.width, kTOCropViewMinimumBoxSize);
    cropBoxFrame.size.height = MAX(cropBoxFrame.size.height, kTOCropViewMinimumBoxSize);
    
    _cropBoxFrame = cropBoxFrame;
    
    self.foregroundContainerView.frame = _cropBoxFrame; //set the clipping view to match the new rect
    self.gridOverlayView.frame = _cropBoxFrame; //set the new overlay view to match the same region
    
    // If the mask layer is present, adjust its transform to fit the new container view size
    if (self.circularMaskLayer) {
        CGFloat scale = _cropBoxFrame.size.width / kTOCropViewCircularPathRadius;
        self.circularMaskLayer.transform = CATransform3DScale(CATransform3DIdentity, scale, scale, 1.0f);
    }
    
    //reset the scroll view insets to match the region of the new crop rect
    self.scrollView.contentInset = (UIEdgeInsets){CGRectGetMinY(_cropBoxFrame),
                                                    CGRectGetMinX(_cropBoxFrame),
                                                    CGRectGetMaxY(self.bounds) - CGRectGetMaxY(_cropBoxFrame),
                                                    CGRectGetMaxX(self.bounds) - CGRectGetMaxX(_cropBoxFrame)};

    //if necessary, work out the new minimum size of the scroll view so it fills the crop box
    CGSize imageSize = self.backgroundContainerView.bounds.size;
    CGFloat scale = MAX(cropBoxFrame.size.height/imageSize.height, cropBoxFrame.size.width/imageSize.width);
    self.scrollView.minimumZoomScale = scale;
    
    //make sure content isn't smaller than the crop box
    CGSize size = self.scrollView.contentSize;
    size.width = floorf(size.width);
    size.height = floorf(size.height);
    //self.backgroundContainerView.frame = (CGRect){CGPointZero, size};
    self.scrollView.contentSize = size;
    
    //IMPORTANT: Force the scroll view to update its content after changing the zoom scale
    self.scrollView.zoomScale = self.scrollView.zoomScale;
    
    [self matchForegroundToBackground]; //re-align the background content to match
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setSimpleRenderMode:(BOOL)simpleMode
{
    [self setSimpleRenderMode:simpleMode animated:NO];
}

- (BOOL)cropBoxAspectRatioIsPortrait
{
    CGRect cropFrame = self.cropBoxFrame;
    return CGRectGetWidth(cropFrame) < CGRectGetHeight(cropFrame);
}

- (CGRect)imageCropFrame
{
    CGSize imageSize = self.imageSize;
    CGSize contentSize = self.scrollView.contentSize;
    CGRect cropBoxFrame = self.cropBoxFrame;
    CGPoint contentOffset = self.scrollView.contentOffset;
    UIEdgeInsets edgeInsets = self.scrollView.contentInset;
    
    CGRect frame = CGRectZero;
    frame.origin.x = floorf((contentOffset.x + edgeInsets.left) * (imageSize.width / contentSize.width));
    frame.origin.x = MAX(0, frame.origin.x);
    
    frame.origin.y = floorf((contentOffset.y + edgeInsets.top) * (imageSize.height / contentSize.height));
    frame.origin.y = MAX(0, frame.origin.y);
    
    frame.size.width = ceilf(cropBoxFrame.size.width * (imageSize.width / contentSize.width));
    frame.size.width = MIN(imageSize.width, frame.size.width);
    
    frame.size.height = ceilf(cropBoxFrame.size.height * (imageSize.height / contentSize.height));
    frame.size.height = MIN(imageSize.height, frame.size.height);
    
    return frame;
}

- (void)setImageCropFrame:(CGRect)imageCropFrame
{
    if (self.superview == nil) {
        self.restoreImageCropFrame = imageCropFrame;
        return;
    }
    
    [self updateToImageCropFrame:imageCropFrame];
}

- (void)setCroppingViewsHidden:(BOOL)hidden
{
    [self setCroppingViewsHidden:hidden animated:NO];
}

- (void)setCroppingViewsHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_croppingViewsHidden == hidden)
        return;
        
    _croppingViewsHidden = hidden;
    
    CGFloat alpha = hidden ? 0.0f : 1.0f;
    
    if (animated == NO) {
        self.backgroundImageView.alpha = alpha;
        self.foregroundContainerView.alpha = alpha;
        self.gridOverlayView.alpha = alpha;

        [self toggleTranslucencyViewVisible:!hidden];
        
        return;
    }
    
    self.foregroundContainerView.alpha = alpha;
    self.backgroundImageView.alpha = alpha;
    
    [UIView animateWithDuration:0.4f animations:^{
        [self toggleTranslucencyViewVisible:!hidden];
        self.gridOverlayView.alpha = alpha;
    }];
}

- (void)setBackgroundImageViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (animated == NO) {
        self.backgroundImageView.hidden = hidden;
        return;
    }
    
    CGFloat beforeAlpha = hidden ? 1.0f : 0.0f;
    CGFloat toAlpha = hidden ? 0.0f : 1.0f;
    
    self.backgroundImageView.hidden = NO;
    self.backgroundImageView.alpha = beforeAlpha;
    [UIView animateWithDuration:0.5f animations:^{
        self.backgroundImageView.alpha = toAlpha;
    }completion:^(BOOL complete) {
        if (hidden) {
            self.backgroundImageView.hidden = YES;
        }
    }];
}

- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden
{
    [self setGridOverlayHidden:_gridOverlayHidden animated:NO];
}

- (void)setGridOverlayHidden:(BOOL)gridOverlayHidden animated:(BOOL)animated
{
    _gridOverlayHidden = gridOverlayHidden;
    self.gridOverlayView.alpha = gridOverlayHidden ? 1.0f : 0.0f;
    
    [UIView animateWithDuration:0.4f animations:^{
        self.gridOverlayView.alpha = gridOverlayHidden ? 0.0f : 1.0f;
    }];
}

- (CGRect)imageViewFrame
{
    CGRect frame = CGRectZero;
    frame.origin.x = -self.scrollView.contentOffset.x;
    frame.origin.y = -self.scrollView.contentOffset.y;
    frame.size = self.scrollView.contentSize;
    return frame;
}

- (void)setCanBeReset:(BOOL)canReset
{
    if (canReset == _canBeReset) {
        return;
    }
    
    _canBeReset = canReset;
    
    if (canReset) {
        if ([self.delegate respondsToSelector:@selector(cropViewDidBecomeResettable:)])
            [self.delegate cropViewDidBecomeResettable:self];
    }
    else  {
        if ([self.delegate respondsToSelector:@selector(cropViewDidBecomeNonResettable:)])
            [self.delegate cropViewDidBecomeNonResettable:self];
    }
}

- (void)setAngle:(NSInteger)angle
{
    //The initial layout would not have been performed yet.
    //Save the value and it will be applied when it has
    NSInteger newAngle = angle;
    if (angle % 90 != 0) {
        newAngle = 0;
    }
    
    if (self.superview == nil) {
        self.restoreAngle = newAngle;
        return;
    }
    
    while (labs(self.angle) != labs(newAngle)) {
        [self rotateImageNinetyDegreesAnimated:NO];
    }
}

#pragma mark - Editing Mode -
- (void)startEditing
{
    [self cancelResetTimer];
    [self setEditing:YES animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (editing == _editing)
        return;
    
    _editing = editing;
    
    [self.gridOverlayView setGridHidden:!editing animated:animated];
    
    if (editing == NO) {
        [self moveCroppedContentToCenterAnimated:animated];
        [self captureStateForImageRotation];
        self.cropBoxLastEditedAngle = self.angle;
    }
    
    if (animated == NO) {
        [self toggleTranslucencyViewVisible:!editing];
        return;
    }
    
    CGFloat duration = editing ? 0.05f : 0.35f;
    CGFloat delay = editing? 0.0f : 0.35f;
    
    if (self.croppingStyle == TOCropViewCroppingStyleCircular) {
        delay = 0.0f;
    }
    
    [UIView animateKeyframesWithDuration:duration delay:delay options:0 animations:^{
        [self toggleTranslucencyViewVisible:!editing];
    } completion:nil];
}

- (void)moveCroppedContentToCenterAnimated:(BOOL)animated
{
    if (self.internalLayoutDisabled)
        return;
    
    CGRect contentRect = self.contentBounds;
    CGRect cropFrame = self.cropBoxFrame;
    
    // Ensure we only proceed after the crop frame has been setup for the first time
    if (cropFrame.size.width < FLT_EPSILON || cropFrame.size.height < FLT_EPSILON) {
        return;
    }
    
    //The scale we need to scale up the crop box to fit full screen
    CGFloat scale = MIN(CGRectGetWidth(contentRect)/CGRectGetWidth(cropFrame), CGRectGetHeight(contentRect)/CGRectGetHeight(cropFrame));
    
    CGPoint focusPoint = (CGPoint){CGRectGetMidX(cropFrame), CGRectGetMidY(cropFrame)};
    CGPoint midPoint = (CGPoint){CGRectGetMidX(contentRect), CGRectGetMidY(contentRect)};
    
    cropFrame.size.width = ceilf(cropFrame.size.width * scale);
    cropFrame.size.height = ceilf(cropFrame.size.height * scale);
    cropFrame.origin.x = contentRect.origin.x + ceilf((contentRect.size.width - cropFrame.size.width) * 0.5f);
    cropFrame.origin.y = contentRect.origin.y + ceilf((contentRect.size.height - cropFrame.size.height) * 0.5f);
    
    //Work out the point on the scroll content that the focusPoint is aiming at
    CGPoint contentTargetPoint = CGPointZero;
    contentTargetPoint.x = ((focusPoint.x + self.scrollView.contentOffset.x) * scale);
    contentTargetPoint.y = ((focusPoint.y + self.scrollView.contentOffset.y) * scale);
    
    //Work out where the crop box is focusing, so we can re-align to center that point
    __block CGPoint offset = CGPointZero;
    offset.x = -midPoint.x + contentTargetPoint.x;
    offset.y = -midPoint.y + contentTargetPoint.y;
    
    //clamp the content so it doesn't create any seams around the grid
    offset.x = MAX(-cropFrame.origin.x, offset.x);
    offset.y = MAX(-cropFrame.origin.y, offset.y);
    
    __weak typeof(self) weakSelf = self;
    void (^translateBlock)() = ^{
        typeof(self) strongSelf = weakSelf;
        
        // Setting these scroll view properties will trigger
        // the foreground matching method via their delegates,
        // multiple times inside the same animation block, resulting
        // in glitchy animations.
        //
        // Disable matching for now, and explicitly update at the end.
        strongSelf.disableForgroundMatching = YES;
        {
            // Slight hack. This method needs to be called during `[UIViewController viewDidLayoutSubviews]`
            // in order for the crop view to resize itself during iPad split screen events.
            // On the first run, even though scale is exactly 1.0f, performing this multiplication introduces
            // a floating point noise that zooms the image in by about 5 pixels. This fixes that issue.
            if (scale < 1.0f - FLT_EPSILON || scale > 1.0f + FLT_EPSILON) {
                strongSelf.scrollView.zoomScale *= scale;
            }
            
            offset.x = MIN(-CGRectGetMaxX(cropFrame)+strongSelf.scrollView.contentSize.width, offset.x);
            offset.y = MIN(-CGRectGetMaxY(cropFrame)+strongSelf.scrollView.contentSize.height, offset.y);
            strongSelf.scrollView.contentOffset = offset;
            
            strongSelf.cropBoxFrame = cropFrame;
        }
        strongSelf.disableForgroundMatching = NO;
        
        //Explicitly update the matching at the end of the calculations
        [strongSelf matchForegroundToBackground];
    };
    
    if (!animated) {
        translateBlock();
        return;
    }

    [self matchForegroundToBackground];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:1.0f
              initialSpringVelocity:1.0f
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:translateBlock
                         completion:nil];
    });
}

- (void)setSimpleRenderMode:(BOOL)simpleMode animated:(BOOL)animated
{
    if (simpleMode == _simpleRenderMode)
        return;
    
    _simpleRenderMode = simpleMode;
    
    self.editing = NO;
    
    if (animated == NO) {
        [self toggleTranslucencyViewVisible:!simpleMode];
        
        return;
    }
    
    [UIView animateWithDuration:0.25f animations:^{
        [self toggleTranslucencyViewVisible:!simpleMode];
    }];
}

- (void)setAspectRatio:(CGSize)aspectRatio
{
    [self setAspectRatio:aspectRatio animated:NO];
}

- (void)setAspectRatio:(CGSize)aspectRatio animated:(BOOL)animated
{
    _aspectRatio = aspectRatio;
    
    // Will be executed automatically when added to a super view
    if (self.superview == nil) {
        return;
    }
    
    // Passing in an empty size will revert back to the image aspect ratio
    if (aspectRatio.width < FLT_EPSILON && aspectRatio.height < FLT_EPSILON) {
        aspectRatio = (CGSize){self.imageSize.width, self.imageSize.height};
    }

    CGRect boundsFrame = self.contentBounds;
    CGRect cropBoxFrame = self.cropBoxFrame;
    CGPoint offset = self.scrollView.contentOffset;
    
    BOOL cropBoxIsPortrait = NO;
    if ((NSInteger)aspectRatio.width == 1 && (NSInteger)aspectRatio.height == 1)
        cropBoxIsPortrait = self.image.size.width > self.image.size.height;
    else
        cropBoxIsPortrait = aspectRatio.width < aspectRatio.height;
    
    BOOL zoomOut = NO;
    if (cropBoxIsPortrait) {
        CGFloat newWidth = floorf(cropBoxFrame.size.height * (aspectRatio.width/aspectRatio.height));
        CGFloat delta = cropBoxFrame.size.width - newWidth;
        cropBoxFrame.size.width = newWidth;
        offset.x += (delta * 0.5f);
        
        if (delta < FLT_EPSILON)
            cropBoxFrame.origin.x = self.contentBounds.origin.x; //set to 0 to avoid accidental clamping by the crop frame sanitizer
        
        CGFloat boundsWidth = CGRectGetWidth(boundsFrame);
        if (newWidth > boundsWidth) {
            CGFloat scale = boundsWidth / newWidth;
            cropBoxFrame.size.height *= scale;
            cropBoxFrame.size.width = boundsWidth;
            zoomOut = YES;
        }
    }
    else {
        CGFloat newHeight = floorf(cropBoxFrame.size.width * (aspectRatio.height/aspectRatio.width));
        CGFloat delta = cropBoxFrame.size.height - newHeight;
        cropBoxFrame.size.height = newHeight;
        offset.y += (delta * 0.5f);
        
        if (delta < FLT_EPSILON)
            cropBoxFrame.origin.x = self.contentBounds.origin.y;
        
        CGFloat boundsHeight = CGRectGetHeight(boundsFrame);
        if (newHeight > boundsHeight) {
            CGFloat scale = boundsHeight / newHeight;
            cropBoxFrame.size.width *= scale;
            cropBoxFrame.size.height = boundsHeight;
            zoomOut = YES;
        }
    }
    
    self.cropBoxLastEditedSize = cropBoxFrame.size;
    self.cropBoxLastEditedAngle = self.angle;
    
    void (^translateBlock)() = ^{
        self.scrollView.contentOffset = offset;
        self.cropBoxFrame = cropBoxFrame;
        
        if (zoomOut)
            self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        
        [self moveCroppedContentToCenterAnimated:NO];
        [self checkForCanReset];
    };
    
    if (animated == NO) {
        translateBlock();
        return;
    }
    
    [UIView animateWithDuration:0.5f
                          delay:0.0
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.7f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:translateBlock
                     completion:nil];
}

- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated
{
    [self rotateImageNinetyDegreesAnimated:animated clockwise:NO];
}

- (void)rotateImageNinetyDegreesAnimated:(BOOL)animated clockwise:(BOOL)clockwise
{
    //Only allow one rotation animation at a time
    if (self.rotateAnimationInProgress)
        return;
    
    //Cancel any pending resizing timers
    if (self.resetTimer) {
        [self cancelResetTimer];
        [self setEditing:NO animated:NO];
        
        self.cropBoxLastEditedAngle = self.angle;
        [self captureStateForImageRotation];
    }
    
    //Work out the new angle, and wrap around once we exceed 360s
    NSInteger newAngle = self.angle;
    newAngle = clockwise ? newAngle + 90 : newAngle - 90;
    if (newAngle <= -360 || newAngle >= 360)
        newAngle = 0;
    
    _angle = newAngle;
    
    //Convert the new angle to radians
    CGFloat angleInRadians = 0.0f;
    switch (newAngle) {
        case 90:    angleInRadians = M_PI_2;            break;
        case -90:   angleInRadians = -M_PI_2;           break;
        case 180:   angleInRadians = M_PI;              break;
        case -180:  angleInRadians = -M_PI;             break;
        case 270:   angleInRadians = (M_PI + M_PI_2);   break;
        case -270:  angleInRadians = -(M_PI + M_PI_2);  break;
        default:                                        break;
    }
    
    // Set up the transformation matrix for the rotation
    CGAffineTransform rotation = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
    
    //Work out how much we'll need to scale everything to fit to the new rotation
    CGRect contentBounds = self.contentBounds;
    CGRect cropBoxFrame = self.cropBoxFrame;
    CGFloat scale = MIN(contentBounds.size.width / cropBoxFrame.size.height, contentBounds.size.height / cropBoxFrame.size.width);
    
    //Work out which section of the image we're currently focusing at
    CGPoint cropMidPoint = (CGPoint){CGRectGetMidX(cropBoxFrame), CGRectGetMidY(cropBoxFrame)};
    CGPoint cropTargetPoint = (CGPoint){cropMidPoint.x + self.scrollView.contentOffset.x, cropMidPoint.y + self.scrollView.contentOffset.y};
    
    //Work out the dimensions of the crop box when rotated
    CGRect newCropFrame = CGRectZero;
    if (labs(self.angle) == labs(self.cropBoxLastEditedAngle) || (labs(self.angle)*-1) == ((labs(self.cropBoxLastEditedAngle) - 180) % 360)) {
        newCropFrame.size = self.cropBoxLastEditedSize;
        
        self.scrollView.minimumZoomScale = self.cropBoxLastEditedMinZoomScale;
        self.scrollView.zoomScale = self.cropBoxLastEditedZoomScale;
    }
    else {
        newCropFrame.size = (CGSize){floorf(self.cropBoxFrame.size.height * scale), floorf(self.cropBoxFrame.size.width * scale)};
        
        //Re-adjust the scrolling dimensions of the scroll view to match the new size
        self.scrollView.minimumZoomScale *= scale;
        self.scrollView.zoomScale *= scale;
    }
    
    newCropFrame.origin.x = floorf((CGRectGetWidth(self.bounds) - newCropFrame.size.width) * 0.5f);
    newCropFrame.origin.y = floorf((CGRectGetHeight(self.bounds) - newCropFrame.size.height) * 0.5f);
    
    //If we're animated, generate a snapshot view that we'll animate in place of the real view
    UIView *snapshotView = nil;
    if (animated) {
        snapshotView = [self.foregroundContainerView snapshotViewAfterScreenUpdates:NO];
        self.rotateAnimationInProgress = YES;
    }
    
    //Rotate the background image view, inside its container view
    self.backgroundImageView.transform = rotation;
    
    //Flip the width/height of the container view so it matches the rotated image view's size
    CGSize containerSize = self.backgroundContainerView.frame.size;
    self.backgroundContainerView.frame = (CGRect){CGPointZero, {containerSize.height, containerSize.width}};
    self.backgroundImageView.frame = (CGRect){CGPointZero, self.backgroundImageView.frame.size};

    //Rotate the foreground image view to match
    self.foregroundContainerView.transform = CGAffineTransformIdentity;
    self.foregroundImageView.transform = rotation;
    
    //Flip the content size of the scroll view to match the rotated bounds
    self.scrollView.contentSize = self.backgroundContainerView.frame.size;
    
    //assign the new crop box frame and re-adjust the content to fill it
    self.cropBoxFrame = newCropFrame;
    [self moveCroppedContentToCenterAnimated:NO];
    newCropFrame = self.cropBoxFrame;
    
    //work out how to line up out point of interest into the middle of the crop box
    cropTargetPoint.x *= scale;
    cropTargetPoint.y *= scale;
    
    //swap the target dimensions to match a 90 degree rotation (clockwise or counterclockwise)
    CGFloat swap = cropTargetPoint.x;
    if (clockwise) {
        cropTargetPoint.x = self.scrollView.contentSize.width - cropTargetPoint.y;
        cropTargetPoint.y = swap;
    } else {
        cropTargetPoint.x = cropTargetPoint.y;
        cropTargetPoint.y = self.scrollView.contentSize.height - swap;
    }
    
    //reapply the translated scroll offset to the scroll view
    CGPoint midPoint = {CGRectGetMidX(newCropFrame), CGRectGetMidY(newCropFrame)};
    CGPoint offset = CGPointZero;
    offset.x = floorf(-midPoint.x + cropTargetPoint.x);
    offset.y = floorf(-midPoint.y + cropTargetPoint.y);
    offset.x = MAX(-self.scrollView.contentInset.left, offset.x);
    offset.y = MAX(-self.scrollView.contentInset.top, offset.y);
    
    //if the scroll view's new scale is 1 and the new offset is equal to the old, will not trigger the delegate 'scrollViewDidScroll:'
    //so we should call the method manually to update the foregroundImageView's frame
    if (offset.x == self.scrollView.contentOffset.x && offset.y == self.scrollView.contentOffset.y && scale == 1) {
        [self matchForegroundToBackground];
    }
    self.scrollView.contentOffset = offset;
    
    //If we're animated, play an animation of the snapshot view rotating,
    //then fade it out over the live content
    if (animated) {
        snapshotView.center = self.scrollView.center;
        [self addSubview:snapshotView];
        
        self.backgroundContainerView.hidden = YES;
        self.foregroundContainerView.hidden = YES;
        self.translucencyView.hidden = YES;
        self.gridOverlayView.hidden = YES;
        
        [UIView animateWithDuration:0.45f delay:0.0f usingSpringWithDamping:1.0f initialSpringVelocity:0.8f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, clockwise ? M_PI_2 : -M_PI_2);
            transform = CGAffineTransformScale(transform, scale, scale);
            snapshotView.transform = transform;
        } completion:^(BOOL complete) {
            self.backgroundContainerView.hidden = NO;
            self.foregroundContainerView.hidden = NO;
            self.translucencyView.hidden = NO;
            self.gridOverlayView.hidden = NO;
            
            self.backgroundContainerView.alpha = 0.0f;
            self.gridOverlayView.alpha = 0.0f;
            
            self.translucencyView.alpha = 1.0f;
            
            [UIView animateWithDuration:0.45f animations:^{
                snapshotView.alpha = 0.0f;
                self.backgroundContainerView.alpha = 1.0f;
                self.gridOverlayView.alpha = 1.0f;
            } completion:^(BOOL complete) {
                self.rotateAnimationInProgress = NO;
                [snapshotView removeFromSuperview];
            }];
        }];
    }
    
    [self checkForCanReset];
}

- (void)captureStateForImageRotation
{
    self.cropBoxLastEditedSize = self.cropBoxFrame.size;
    self.cropBoxLastEditedZoomScale = self.scrollView.zoomScale;
    self.cropBoxLastEditedMinZoomScale = self.scrollView.minimumZoomScale;
}

#pragma mark - Resettable State -
- (void)checkForCanReset
{
    BOOL canReset = NO;
    
    if (self.angle != 0) { //Image has been rotated
        canReset = YES;
    }
    else if (self.scrollView.zoomScale > self.scrollView.minimumZoomScale + FLT_EPSILON) { //image has been zoomed in
        canReset = YES;
    }
    else if ((NSInteger)floorf(self.cropBoxFrame.size.width) != (NSInteger)floorf(self.originalCropBoxSize.width) ||
             (NSInteger)floorf(self.cropBoxFrame.size.height) != (NSInteger)floorf(self.originalCropBoxSize.height))
    { //crop box has been changed
        canReset = YES;
    }
    else if ((NSInteger)floorf(self.scrollView.contentOffset.x) != (NSInteger)floorf(self.originalContentOffset.x) ||
             (NSInteger)floorf(self.scrollView.contentOffset.y) != (NSInteger)floorf(self.originalContentOffset.y))
    {
        canReset = YES;
    }

    self.canBeReset = canReset;
}

#pragma mark - Convienience Methods -
- (CGRect)contentBounds
{
    CGRect contentRect = CGRectZero;
    contentRect.origin.x = kTOCropViewPadding + self.cropRegionInsets.left;
    contentRect.origin.y = kTOCropViewPadding + self.cropRegionInsets.top;
    contentRect.size.width = CGRectGetWidth(self.bounds) - ((kTOCropViewPadding * 2) + self.cropRegionInsets.left + self.cropRegionInsets.right);
    contentRect.size.height = CGRectGetHeight(self.bounds) - ((kTOCropViewPadding * 2) + self.cropRegionInsets.top + self.cropRegionInsets.bottom);
    return contentRect;
}

- (CGSize)imageSize
{
    if (self.angle == -90 || self.angle == -270 || self.angle == 90 || self.angle == 270)
        return (CGSize){self.image.size.height, self.image.size.width};

    return (CGSize){self.image.size.width, self.image.size.height};
}

- (BOOL)hasAspectRatio
{
    return (self.aspectRatio.width > FLT_EPSILON && self.aspectRatio.height > FLT_EPSILON);
}

@end
