//
//  CropViewController.swift
//  CropViewControllerExample
//
//  Created by Tim Oliver on 18/11/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

import UIKit
import TOCropViewController

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



public protocol CropViewControllerDelegate {
    
}

public class CropViewController: UIViewController, TOCropViewControllerDelegate {
    
    /**
     The original, uncropped image that was passed to this controller.
     */
    public var image: UIImage { return self.toCropViewController.image }
    
    /**
     The view controller's delegate that will receive the resulting
     cropped image, as well as crop information.
    */
    public var delegate: CropViewControllerDelegate?
    
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
     Title for the 'Done' button.
     Setting this will override the Default which is a localized string for "Done".
     */
    public var doneButtonTitle: String? {
        set { toCropViewController.doneButtonTitle = newValue }
        get { return toCropViewController.doneButtonTitle }
    }
    
    /**
     Title for the 'Cancel' button.
     Setting this will override the Default which is a localized string for "Cancel".
     */
    public var cancelButtonTitle: String? {
        set { toCropViewController.cancelButtonTitle = newValue }
        get { return toCropViewController.cancelButtonTitle }
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
    public var excludedActivityTypes: [UIActivityType]? {
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
    
    /**
     This class internally manages and abstracts access to a `TOCropViewController` instance
     :nodoc:
     */
    internal let toCropViewController: TOCropViewController!
    
    // MARK: - Class Instantiation -
    
    init(image: UIImage) {
        self.toCropViewController = TOCropViewController(image: image)
        super.init(nibName: nil, bundle: nil)
        addChildViewController(self.toCropViewController)
    }
    
    init(image: UIImage, croppingStyle: CropViewCroppingStyle) {
        self.toCropViewController = TOCropViewController(croppingStyle: croppingStyle, image: image)
        super.init(nibName: nil, bundle: nil)
        addChildViewController(self.toCropViewController)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        toCropViewController.view.frame = view.frame
        toCropViewController.delegate = self
        view.addSubview(toCropViewController.view)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
