//
//  CropViewController.swift
//
//  Copyright 2017-2018 Timothy Oliver. All rights reserved.
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

/**
 An enum containing all of the aspect ratio presets that this view controller supports
 */
public typealias CropViewControllerAspectRatioPreset = TOCropViewControllerAspectRatioPreset

/**
 An enum denoting whether the control tool bar is drawn at the top, or the bottom of the screen in portrait mode
 */
public typealias CropViewControllerToolbarPosition = TOCropViewControllerToolbarPosition

/**
 The type of cropping style for this view controller (ie a square or a circle cropping region)
 */
public typealias CropViewCroppingStyle = TOCropViewCroppingStyle

///------------------------------------------------
/// @name Delegate
///------------------------------------------------

@objc public protocol CropViewControllerDelegate: NSObjectProtocol {
    /**
     Called when the user has committed the crop action, and provides
     just the cropping rectangle.
     
     @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
     @param angle The angle of the image when it was cropped
     */
    @objc optional func cropViewController(_ cropViewController: CropViewController, didCropImageToRect rect: CGRect, angle: Int)
    
    /**
     Called when the user has committed the crop action, and provides
     both the original image with crop co-ordinates.
     
     @param image The newly cropped image.
     @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
     @param angle The angle of the image when it was cropped
     */
    @objc optional func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int)
    
    /**
     If the cropping style is set to circular, implementing this delegate will return a circle-cropped version of the selected
     image, as well as it's cropping co-ordinates
     
     @param image The newly cropped image, clipped to a circle shape
     @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
     @param angle The angle of the image when it was cropped
     */
    @objc optional func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int)
    
    /**
     If implemented, when the user hits cancel, or completes a
     UIActivityViewController operation, this delegate will be called,
     giving you a chance to manually dismiss the view controller
     
     @param cancelled Whether a cropping action was actually performed, or if the user explicitly hit 'Cancel'
     
     */
    @objc optional func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool)
}

///------------------------------------------------
/// @name Class
///------------------------------------------------

open class CropViewController: UIViewController, TOCropViewControllerDelegate {
    
    /**
     The original, uncropped image that was passed to this controller.
     */
    public var image: UIImage { return self.toCropViewController.image }
    
    /**
     The view controller's delegate that will receive the resulting
     cropped image, as well as crop information.
    */
    public var delegate: CropViewControllerDelegate? {
        didSet { self.setUpDelegateHandlers() }
    }
    
    /**
     Set the title text that appears at the top of the view controller
    */
    override open var title: String? {
        set { toCropViewController.title = newValue }
        get { return toCropViewController.title }
    }
    
    /**
     If true, when the user hits 'Done', a UIActivityController will appear
     before the view controller ends.
     */
    public var showActivitySheetOnDone: Bool {
        set { toCropViewController.showActivitySheetOnDone = newValue }
        get { return toCropViewController.showActivitySheetOnDone }
    }
    
    /**
     In the coordinate space of the image itself, the region that is currently
     being highlighted by the crop box.
     
     This property can be set before the controller is presented to have
     the image 'restored' to a previous cropping layout.
     */
    public var imageCropFrame: CGRect {
        set { toCropViewController.imageCropFrame = newValue }
        get { return toCropViewController.imageCropFrame }
    }
    
    /**
     The angle in which the image is rotated in the crop view.
     This can only be in 90 degree increments (eg, 0, 90, 180, 270).
     
     This property can be set before the controller is presented to have
     the image 'restored' to a previous cropping layout.
     */
    public var angle: Int {
        set { toCropViewController.angle = newValue }
        get { return toCropViewController.angle }
    }
    
    /**
     The cropping style of this particular crop view controller
     */
    public var croppingStyle: CropViewCroppingStyle {
        return toCropViewController.croppingStyle
    }
    
    /**
      A choice from one of the pre-defined aspect ratio presets
    */
    public var aspectRatioPreset: CropViewControllerAspectRatioPreset {
        set { toCropViewController.aspectRatioPreset = newValue }
        get { return toCropViewController.aspectRatioPreset }
    }
    
    /**
     A CGSize value representing a custom aspect ratio, not listed in the presets.
     E.g. A ratio of 4:3 would be represented as (CGSize){4.0f, 3.0f}
     */
    public var customAspectRatio: CGSize {
        set { toCropViewController.customAspectRatio = newValue }
        get { return toCropViewController.customAspectRatio }
    }
    
    /**
     Title label which can be used to show instruction on the top of the crop view controller
     */
    public var titleLabel: UILabel? {
        return toCropViewController.titleLabel
    }
    
    /**
     If true, while it can still be resized, the crop box will be locked to its current aspect ratio.
     
     If this is set to YES, and `resetAspectRatioEnabled` is set to NO, then the aspect ratio
     button will automatically be hidden from the toolbar.
     
     Default is false.
     */
    public var aspectRatioLockEnabled: Bool {
        set { toCropViewController.aspectRatioLockEnabled = newValue }
        get { return toCropViewController.aspectRatioLockEnabled }
    }
    
    /**
     If true, a custom aspect ratio is set, and the aspectRatioLockEnabled is set to true, the crop box will swap it's dimensions depending on portrait or landscape sized images.  This value also controls whether the dimensions can swap when the image is rotated.
     
     Default is false.
     */
    public var aspectRatioLockDimensionSwapEnabled: Bool {
        set { toCropViewController.aspectRatioLockDimensionSwapEnabled = newValue }
        get { return toCropViewController.aspectRatioLockDimensionSwapEnabled }
    }
    
    /**
     If true, tapping the reset button will also reset the aspect ratio back to the image
     default ratio. Otherwise, the reset will just zoom out to the current aspect ratio.
     
     If this is set to false, and `aspectRatioLockEnabled` is set to YES, then the aspect ratio
     button will automatically be hidden from the toolbar.
     
     Default is true
     */
    public var resetAspectRatioEnabled: Bool {
        set { toCropViewController.resetAspectRatioEnabled = newValue }
        get { return toCropViewController.resetAspectRatioEnabled }
    }
    
    /**
     The position of the Toolbar the default value is `TOCropViewControllerToolbarPositionBottom`.
     */
    public var toolbarPosition: CropViewControllerToolbarPosition {
        set { toCropViewController.toolbarPosition = newValue }
        get { return toCropViewController.toolbarPosition }
    }
    
    /**
     When disabled, an additional rotation button that rotates the canvas in
     90-degree segments in a clockwise direction is shown in the toolbar.
     
     Default is false.
     */
    public var rotateClockwiseButtonHidden: Bool {
        set { toCropViewController.rotateClockwiseButtonHidden = newValue }
        get { return toCropViewController.rotateClockwiseButtonHidden }
    }
    
    /**
     When enabled, hides the rotation button, as well as the alternative rotation
     button visible when `showClockwiseRotationButton` is set to true.
     
     Default is false.
     */
    public var rotateButtonsHidden: Bool {
        set { toCropViewController.rotateButtonsHidden = newValue }
        get { return toCropViewController.rotateButtonsHidden }
    }
    /**
     When enabled, hides the 'Reset' button on the toolbar.

     Default is false.
     */
    public var resetButtonHidden: Bool {
        set { toCropViewController.resetButtonHidden = newValue }
        get { return toCropViewController.resetButtonHidden }
    }
    
    /**
     When enabled, hides the 'Aspect Ratio Picker' button on the toolbar.
     
     Default is false.
     */
    public var aspectRatioPickerButtonHidden: Bool {
        set { toCropViewController.aspectRatioPickerButtonHidden = newValue }
        get { return toCropViewController.aspectRatioPickerButtonHidden }
    }
    
    /**
     If `showActivitySheetOnDone` is true, then these activity items will
     be supplied to that UIActivityViewController in addition to the
     `TOActivityCroppedImageProvider` object.
     */
    public var activityItems: [Any]? {
        set { toCropViewController.activityItems = newValue }
        get { return toCropViewController.activityItems }
    }
    
    /**
     If `showActivitySheetOnDone` is true, then you may specify any
     custom activities your app implements in this array. If your activity requires
     access to the cropping information, it can be accessed in the supplied
     `TOActivityCroppedImageProvider` object
     */
    public var applicationActivities: [UIActivity]? {
        set { toCropViewController.applicationActivities = newValue }
        get { return toCropViewController.applicationActivities }
    }
    
    /**
     If `showActivitySheetOnDone` is true, then you may expliclty
     set activities that won't appear in the share sheet here.
     */
    public var excludedActivityTypes: [UIActivity.ActivityType]? {
        set { toCropViewController.excludedActivityTypes = newValue }
        get { return toCropViewController.excludedActivityTypes }
    }
    
    /**
     When the user hits cancel, or completes a
     UIActivityViewController operation, this block will be called,
     giving you a chance to manually dismiss the view controller
     */
    public var onDidFinishCancelled: ((Bool) -> (Void))? {
        set { toCropViewController.onDidFinishCancelled = newValue }
        get { return toCropViewController.onDidFinishCancelled }
    }
    
    /**
     Called when the user has committed the crop action, and provides
     just the cropping rectangle.
     
     @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
     @param angle The angle of the image when it was cropped
     */
    public var onDidCropImageToRect: ((CGRect, Int) -> (Void))? {
        set { toCropViewController.onDidCropImageToRect = newValue }
        get { return toCropViewController.onDidCropImageToRect }
    }
    
    /**
     Called when the user has committed the crop action, and provides
     both the cropped image with crop co-ordinates.
     
     @param image The newly cropped image.
     @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
     @param angle The angle of the image when it was cropped
     */
    public var onDidCropToRect: ((UIImage, CGRect, NSInteger) -> (Void))? {
        set { toCropViewController.onDidCropToRect = newValue }
        get { return toCropViewController.onDidCropToRect }
    }
    
    /**
     If the cropping style is set to circular, this block will return a circle-cropped version of the selected
     image, as well as it's cropping co-ordinates
     
     @param image The newly cropped image, clipped to a circle shape
     @param cropRect A rectangle indicating the crop region of the image the user chose (In the original image's local co-ordinate space)
     @param angle The angle of the image when it was cropped
     */
    public var onDidCropToCircleImage: ((UIImage, CGRect, NSInteger) -> (Void))? {
        set { toCropViewController.onDidCropToCircleImage = newValue }
        get { return toCropViewController.onDidCropToCircleImage }
    }

    /**
     The crop view managed by this view controller.
     */
    public var cropView: TOCropView {
        return toCropViewController.cropView
    }
    
    /**
     The toolbar managed by this view controller.
     */
    public var toolbar: TOCropToolbar {
        return toCropViewController.toolbar
    }

    /*
     If this controller is embedded in UINavigationController its navigation bar is hidden by default. Set this property to false to show the navigation bar. This must be set before this controller is presented.
     */
    public var hidesNavigationBar: Bool {
        set { toCropViewController.hidesNavigationBar = newValue }
        get { return toCropViewController.hidesNavigationBar }
    }
    
    /**
     Title for the 'Done' button.
     Setting this will override the Default which is a localized string for "Done".
     */
    public var doneButtonTitle: String! {
        set { toCropViewController.doneButtonTitle = newValue }
        get { return toCropViewController.doneButtonTitle }
    }
    
    /**
     Title for the 'Cancel' button.
     Setting this will override the Default which is a localized string for "Cancel".
     */
    public var cancelButtonTitle: String! {
        set { toCropViewController.cancelButtonTitle = newValue }
        get { return toCropViewController.cancelButtonTitle }
    }
    
    /**
     This class internally manages and abstracts access to a `TOCropViewController` instance
     :nodoc:
     */
    internal let toCropViewController: TOCropViewController!
    
    /**
     Forward status bar status style changes to the crop view controller
     :nodoc:
     */
    open override var childForStatusBarStyle: UIViewController? {
        return toCropViewController
    }
    
    /**
     Forward status bar status visibility changes to the crop view controller
     :nodoc:
     */
    open override var childForStatusBarHidden: UIViewController? {
        return toCropViewController
    }
    
    open override var prefersStatusBarHidden: Bool {
        return false
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return toCropViewController.preferredStatusBarStyle
    }
    
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        if #available(iOS 11.0, *) {
            return toCropViewController.preferredScreenEdgesDeferringSystemGestures
        }
        
        return UIRectEdge.all
    }
    
    ///------------------------------------------------
    /// @name Object Creation
    ///------------------------------------------------
    
    /**
     Creates a new instance of a crop view controller with the supplied image
     
     @param image The image that will be used to crop.
     */
    public init(image: UIImage) {
        self.toCropViewController = TOCropViewController(image: image)
        super.init(nibName: nil, bundle: nil)
        setUpCropController()
    }
    
    /**
     Creates a new instance of a crop view controller with the supplied image and cropping style
     
     @param style The cropping style that will be used with this view controller (eg, rectangular, or circular)
     @param image The image that will be cropped
     */
    public init(croppingStyle: CropViewCroppingStyle, image: UIImage) {
        self.toCropViewController = TOCropViewController(croppingStyle: croppingStyle, image: image)
        super.init(nibName: nil, bundle: nil)
        setUpCropController()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Defer adding the view until we're about to be presented
        if toCropViewController.view.superview == nil {
            view.addSubview(toCropViewController.view)
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toCropViewController.view.frame = view.bounds
        toCropViewController.viewDidLayoutSubviews()
    }
    
    /**
    Resets object of TOCropViewController class as if user pressed reset button in the bottom bar themself
    */
    public func resetCropViewLayout() {
        toCropViewController.resetCropViewLayout()
    }

    /**
    Set the aspect ratio to be one of the available preset options. These presets have specific behaviour
    such as swapping their dimensions depending on portrait or landscape sized images.

    @param aspectRatioPreset The aspect ratio preset
    @param animated Whether the transition to the aspect ratio is animated
    */
    public func setAspectRatioPreset(_ aspectRatio: CropViewControllerAspectRatioPreset, animated: Bool) {
        toCropViewController.setAspectRatioPresent(aspectRatio, animated: animated)
    }
    
    /**
    Play a custom animation of the target image zooming to its position in
    the crop controller while the background fades in.

    @param viewController The parent controller that this view controller would be presenting from.
    @param fromView A view that's frame will be used as the origin for this animation. Optional if `fromFrame` has a value.
    @param fromFrame In the screen's coordinate space, the frame from which the image should animate from. Optional if `fromView` has a value.
    @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
    @param completion A block that is called once the transition animation is completed.
    */
    public func presentAnimatedFrom(_ viewController: UIViewController, fromView view: UIView?, fromFrame frame: CGRect,
                                    setup: (() -> (Void))?, completion: (() -> (Void))?)
    {
        toCropViewController.presentAnimatedFrom(viewController, view: view, frame: frame, setup: setup, completion: completion)
    }
    
    /**
     Play a custom animation of the target image zooming to its position in
     the crop controller while the background fades in. Additionally, if you're
     'restoring' to a previous crop setup, this method lets you provide a previously
     cropped copy of the image, and the previous crop settings to transition back to
     where the user would have left off.

     @param viewController The parent controller that this view controller would be presenting from.
     @param image The previously cropped image that can be used in the transition animation.
     @param fromView A view that's frame will be used as the origin for this animation. Optional if `fromFrame` has a value.
     @param fromFrame In the screen's coordinate space, the frame from which the image should animate from.
     @param angle The rotation angle in which the image was rotated when it was originally cropped.
     @param toFrame In the image's coordinate space, the previous crop frame that created the previous crop
     @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
     @param completion A block that is called once the transition animation is completed.
    */
    public func presentAnimatedFrom(_ viewController: UIViewController, fromImage image: UIImage?,
                                    fromView: UIView?, fromFrame: CGRect, angle: Int, toImageFrame toFrame: CGRect,
                                    setup: (() -> (Void))?, completion:(() -> (Void))?)
    {
        toCropViewController.presentAnimatedFrom(viewController, fromImage: image, fromView: fromView,
                                                 fromFrame: fromFrame, angle: angle, toFrame: toFrame,
                                                 setup: setup, completion: completion)
    }
    
    /**
     Play a custom animation of the supplied cropped image zooming out from
     the cropped frame to the specified frame as the rest of the content fades out.
     If any view configurations need to be done before the animation starts,

     @param viewController The parent controller that this view controller would be presenting from.
     @param toView A view who's frame will be used to establish the destination frame
     @param frame The target frame that the image will animate to
     @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
     @param completion A block that is called once the transition animation is completed.
    */
    public func dismissAnimatedFrom(_ viewController: UIViewController, toView: UIView?, toFrame: CGRect,
                                    setup: (() -> (Void))?, completion:(() -> (Void))?)
    {
        toCropViewController.dismissAnimatedFrom(viewController, toView: toView, toFrame: toFrame, setup: setup, completion: completion)
    }
    
    /**
     Play a custom animation of the supplied cropped image zooming out from
     the cropped frame to the specified frame as the rest of the content fades out.
     If any view configurations need to be done before the animation starts,

     @param viewController The parent controller that this view controller would be presenting from.
     @param image The resulting 'cropped' image. If supplied, will animate out of the crop box zone. If nil, the default image will entirely zoom out
     @param toView A view who's frame will be used to establish the destination frame
     @param frame The target frame that the image will animate to
     @param setup A block that is called just before the transition starts. Recommended for hiding any necessary image views.
     @param completion A block that is called once the transition animation is completed.
     */
    public func dismissAnimatedFrom(_ viewController: UIViewController, withCroppedImage croppedImage: UIImage?, toView: UIView?,
                                    toFrame: CGRect, setup: (() -> (Void))?, completion:(() -> (Void))?)
    {
        toCropViewController.dismissAnimatedFrom(viewController, croppedImage: croppedImage, toView: toView,
                                                 toFrame: toFrame, setup: setup, completion: completion)
    }
}

extension CropViewController {
    fileprivate func setUpCropController() {
        addChild(toCropViewController)
        transitioningDelegate = (toCropViewController as! UIViewControllerTransitioningDelegate)
        toCropViewController.delegate = self
        toCropViewController.didMove(toParent: self)
    }
    
    fileprivate func setUpDelegateHandlers() {
        guard let delegate = self.delegate else {
            onDidCropToRect = nil
            onDidCropImageToRect = nil
            onDidCropToCircleImage = nil
            onDidFinishCancelled = nil
            return
        }
        
        if delegate.responds(to: #selector(CropViewControllerDelegate.cropViewController(_:didCropImageToRect:angle:))) {
            self.onDidCropImageToRect = {[unowned self] rect, angle in
                delegate.cropViewController!(self, didCropImageToRect: rect, angle: angle)
            }
        }
        
        if delegate.responds(to: #selector(CropViewControllerDelegate.cropViewController(_:didCropToImage:withRect:angle:))) {
            self.onDidCropToRect = {[unowned self] image, rect, angle in
                delegate.cropViewController!(self, didCropToImage: image, withRect: rect, angle: angle)
            }
        }
        
        if delegate.responds(to: #selector(CropViewControllerDelegate.cropViewController(_:didCropToCircularImage:withRect:angle:))) {
            self.onDidCropToCircleImage = {[unowned self] image, rect, angle in
                delegate.cropViewController!(self, didCropToCircularImage: image, withRect: rect, angle: angle)
            }
        }
        
        if delegate.responds(to: #selector(CropViewControllerDelegate.cropViewController(_:didFinishCancelled:))) {
            self.onDidFinishCancelled = {[unowned self] finished in
                delegate.cropViewController!(self, didFinishCancelled: finished)
            }
        }
    }
}

