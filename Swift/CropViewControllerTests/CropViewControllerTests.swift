//
//  CropViewControllerTests.swift
//  CropViewControllerTests
//
//  Copyright 2017-2025 Timothy Oliver. All rights reserved.
//

import XCTest

#if canImport(TOCropViewController)
import TOCropViewController
#endif

// Delegates implementing different subsets of the optional protocol methods, so that
// the per-selector behaviour of the closure bridge can be observed.

private class ImageCroppingDelegate: NSObject, CropViewControllerDelegate {
    var receivedImageCrops = 0
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage,
                            withRect cropRect: CGRect, angle: Int) {
        receivedImageCrops += 1
    }
}

private class CancellationDelegate: NSObject, CropViewControllerDelegate {
    var receivedCancellations = 0
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {
        receivedCancellations += 1
    }
}

private class DoneTapDelegate: NSObject, CropViewControllerDelegate {
    var receivedDoneTaps = 0
    func cropViewControllerDidTapDone(_ cropViewController: CropViewController) {
        receivedDoneTaps += 1
    }
}

/// A delegate that owns its controller, which is the arrangement that turns a strongly
/// captured delegate into a leak of both objects (and the full-resolution image).
private class OwningDelegate: NSObject, CropViewControllerDelegate {
    var cropViewController: CropViewController?
    func cropViewController(_ cropViewController: CropViewController, didFinishCancelled cancelled: Bool) {}
}

@MainActor
final class CropViewControllerTests: XCTestCase {

    // MARK: - Helpers -

    private func testImage(size: CGSize = CGSize(width: 40, height: 20)) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeController() -> CropViewController {
        CropViewController(image: testImage())
    }

    // MARK: - Delegate Bridging -

    func testBridgeOnlyInstallsClosuresForImplementedSelectors() {
        let controller = makeController()
        let delegate = ImageCroppingDelegate()
        controller.delegate = delegate

        XCTAssertNotNil(controller.onDidCropToRect)
        XCTAssertNil(controller.onDidCropImageToRect)
        XCTAssertNil(controller.onDidCropToCircleImage)
        XCTAssertNil(controller.onDidFinishCancelled)
        XCTAssertNil(controller.onDidTapDone)
    }

    func testDoneTapBridgeIsInstalledAndTornDown() {
        let controller = makeController()
        let doneDelegate = DoneTapDelegate()
        controller.delegate = doneDelegate
        XCTAssertNotNil(controller.onDidTapDone)

        controller.onDidTapDone?()
        XCTAssertEqual(doneDelegate.receivedDoneTaps, 1)

        // Replacing it with a delegate that doesn't implement the selector must
        // release the slot, so the old delegate stops being notified
        controller.delegate = CancellationDelegate()
        XCTAssertNil(controller.onDidTapDone)
        XCTAssertEqual(doneDelegate.receivedDoneTaps, 1)
    }

    func testDoneTapBridgeIsANoOpOnceTheDelegateIsGone() {
        let controller = makeController()
        autoreleasepool { controller.delegate = DoneTapDelegate() }

        // Unlike the crop callbacks, this one fires *alongside* them rather than
        // instead of them, so a deallocated delegate must not trigger a dismissal
        // that the crop callbacks are also going to perform
        XCTAssertNotNil(controller.onDidTapDone)
        XCTAssertNoThrow(controller.onDidTapDone?())
    }

    func testBridgedClosureReachesTheDelegate() {
        let controller = makeController()
        let delegate = ImageCroppingDelegate()
        controller.delegate = delegate

        controller.onDidCropToRect?(testImage(), .zero, 0)
        XCTAssertEqual(delegate.receivedImageCrops, 1)
    }

    func testReplacingTheDelegateTearsDownItsBridges() {
        let controller = makeController()
        let imageDelegate = ImageCroppingDelegate()
        controller.delegate = imageDelegate
        XCTAssertNotNil(controller.onDidCropToRect)

        // The replacement implements a different selector, so the slot the previous
        // delegate claimed must be released rather than left pointing at it
        let cancelDelegate = CancellationDelegate()
        controller.delegate = cancelDelegate

        XCTAssertNil(controller.onDidCropToRect)
        XCTAssertNotNil(controller.onDidFinishCancelled)

        controller.onDidFinishCancelled?(true)
        XCTAssertEqual(cancelDelegate.receivedCancellations, 1)
        XCTAssertEqual(imageDelegate.receivedImageCrops, 0)
    }

    func testClearingTheDelegateTearsDownItsBridges() {
        let controller = makeController()
        controller.delegate = CancellationDelegate()
        XCTAssertNotNil(controller.onDidFinishCancelled)

        controller.delegate = nil
        XCTAssertNil(controller.onDidFinishCancelled)
    }

    func testDirectlyAssignedClosuresSurviveDelegateChanges() {
        let controller = makeController()
        var directCallCount = 0
        controller.onDidCropToRect = { _, _, _ in directCallCount += 1 }

        // This delegate doesn't implement didCropToImage, so it has no claim on that slot
        let delegate = CancellationDelegate()
        controller.delegate = delegate
        XCTAssertNotNil(controller.onDidCropToRect)

        controller.delegate = nil
        XCTAssertNotNil(controller.onDidCropToRect)

        controller.onDidCropToRect?(testImage(), .zero, 0)
        XCTAssertEqual(directCallCount, 1)
    }

    func testDelegateIsNotRetainedByTheBridge() {
        weak var weakController: CropViewController?
        weak var weakDelegate: OwningDelegate?

        autoreleasepool {
            let delegate = OwningDelegate()
            let controller = CropViewController(image: testImage())
            controller.delegate = delegate

            // Close the loop: the delegate owns the controller, as a presenting view
            // controller typically would
            delegate.cropViewController = controller

            weakController = controller
            weakDelegate = delegate
        }

        XCTAssertNil(weakController)
        XCTAssertNil(weakDelegate)
    }

    func testBridgedClosureToleratesADeallocatedDelegate() {
        let controller = makeController()
        autoreleasepool {
            controller.delegate = ImageCroppingDelegate()
        }

        // The delegate is gone but the closure is still installed; it should fall back
        // to the default dismissal rather than trapping on a nil delegate
        XCTAssertNotNil(controller.onDidCropToRect)
        XCTAssertNoThrow(controller.onDidCropToRect?(testImage(), .zero, 0))
    }

    // MARK: - Property Forwarding -

    func testValuesForwardToTheUnderlyingController() {
        let controller = makeController()
        let inner = controller.toCropViewController!

        controller.aspectRatioPreset = CGSize(width: 16, height: 9)
        XCTAssertTrue(controller.aspectRatioPreset == CGSize(width: 16, height: 9))
        XCTAssertTrue(inner.aspectRatioPreset == CGSize(width: 16, height: 9))

        controller.aspectRatioLockEnabled = true
        XCTAssertTrue(inner.aspectRatioLockEnabled)

        controller.aspectRatioLockDimensionSwapEnabled = true
        XCTAssertTrue(inner.aspectRatioLockDimensionSwapEnabled)

        controller.resetAspectRatioEnabled = false
        XCTAssertFalse(inner.resetAspectRatioEnabled)

        controller.toolbarPosition = .top
        XCTAssertEqual(inner.toolbarPosition, .top)

        controller.rotateClockwiseButtonHidden = true
        XCTAssertTrue(inner.rotateClockwiseButtonHidden)

        controller.rotateButtonsHidden = true
        XCTAssertTrue(inner.rotateButtonsHidden)

        controller.resetButtonHidden = true
        XCTAssertTrue(inner.resetButtonHidden)

        controller.doneButtonHidden = true
        XCTAssertTrue(inner.doneButtonHidden)

        controller.cancelButtonHidden = true
        XCTAssertTrue(inner.cancelButtonHidden)

        controller.doneButtonTitle = "Save"
        XCTAssertEqual(inner.doneButtonTitle, "Save")

        controller.cancelButtonTitle = "Back"
        XCTAssertEqual(inner.cancelButtonTitle, "Back")

        controller.doneButtonColor = .systemPink
        XCTAssertEqual(inner.doneButtonColor, .systemPink)

        controller.cancelButtonColor = .systemTeal
        XCTAssertEqual(inner.cancelButtonColor, .systemTeal)

        controller.minimumAspectRatio = 0.5
        XCTAssertEqual(inner.minimumAspectRatio, 0.5)

        controller.hidesNavigationBar = false
        XCTAssertFalse(inner.hidesNavigationBar)

        controller.showActivitySheetOnDone = true
        XCTAssertTrue(inner.showActivitySheetOnDone)

        controller.showCancelConfirmationDialog = true
        XCTAssertTrue(inner.showCancelConfirmationDialog)

        controller.reverseContentLayout = true
        XCTAssertTrue(inner.reverseContentLayout)

        controller.aspectRatioPickerButtonHidden = true
        XCTAssertTrue(inner.aspectRatioPickerButtonHidden)

        // Not asserted against the value that was set: the toolbar is permanently
        // icon-only from iOS 26 on, so this only has to agree with what it wraps
        controller.showOnlyIcons = true
        XCTAssertEqual(controller.showOnlyIcons, inner.showOnlyIcons)
    }

    func testTitleForwardsToTheUnderlyingController() {
        let controller = makeController()
        XCTAssertNil(controller.titleLabel)

        controller.title = "Crop Your Photo"
        XCTAssertEqual(controller.title, "Crop Your Photo")
        XCTAssertEqual(controller.toCropViewController.title, "Crop Your Photo")
        XCTAssertEqual(controller.titleLabel?.text, "Crop Your Photo")
    }

    func testImageAndCroppingStyleComeFromTheInitialiser() {
        let image = testImage()

        let defaultController = CropViewController(image: image)
        XCTAssertIdentical(defaultController.image, image)
        XCTAssertEqual(defaultController.croppingStyle, .default)
        XCTAssertEqual(defaultController.cropView.croppingStyle, .default)

        let circularController = CropViewController(croppingStyle: .circular, image: image)
        XCTAssertEqual(circularController.croppingStyle, .circular)
        XCTAssertEqual(circularController.cropView.croppingStyle, .circular)
    }

    func testChildViewControllerRelationshipIsEstablished() {
        let controller = makeController()
        XCTAssertTrue(controller.children.contains(controller.toCropViewController))
        XCTAssertIdentical(controller.childForStatusBarStyle, controller.toCropViewController)
        XCTAssertIdentical(controller.childForStatusBarHidden, controller.toCropViewController)
    }
}
