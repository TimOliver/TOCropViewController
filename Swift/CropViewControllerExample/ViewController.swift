//
//  ViewController.swift
//  CropViewControllerExample
//
//  Created by Tim Oliver on 18/11/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private let imageView = UIImageView()
    
    private var croppingStyle = CropViewCroppingStyle.default
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("TOCropViewController", comment: "")
        navigationController!.navigationBar.isTranslucent = false
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped(sender:)))
    
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        let tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(didTapImageView))
        imageView.addGestureRecognizer(tapRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc public func addButtonTapped(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let defaultAction = UIAlertAction(title: "Crop Image", style: .default) { (action) in
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        let profileAction = UIAlertAction(title: "Make Profile Picture", style: .default) { (action) in
            let imagePicker = UIImagePickerController()
            imagePicker.modalPresentationStyle = .popover
            imagePicker.preferredContentSize = CGSize(width: 320, height: 568)
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        alertController.addAction(defaultAction)
        alertController.addAction(profileAction)
        alertController.modalPresentationStyle = .popover
        
        let presentationController = alertController.popoverPresentationController
        presentationController?.barButtonItem = (sender as! UIBarButtonItem)
        present(alertController, animated: true, completion: nil)
        
    }
    
    @objc public func didTapImageView() {
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutImageView()
    }
    
    public func layoutImageView() {
        guard imageView.image != nil else { return }
        
        let padding: CGFloat = 20.0
        
        var viewFrame = self.view.bounds
        viewFrame.size.width -= (padding * 2.0)
        viewFrame.size.height -= ((padding * 2.0))
        
        var imageFrame = CGRect.zero
        imageFrame.size = imageView.image!.size;
        
        if imageView.image!.size.width > viewFrame.size.width || imageView.image!.size.height > viewFrame.size.height {
            let scale = min(viewFrame.size.width / imageFrame.size.width, viewFrame.size.height / imageFrame.size.height)
            imageFrame.size.width *= scale
            imageFrame.size.height *= scale
            imageFrame.origin.x = (self.view.bounds.size.width - imageFrame.size.width) * 0.5
            imageFrame.origin.y = (self.view.bounds.size.height - imageFrame.size.height) * 0.5
            imageView.frame = imageFrame
        }
        else {
            self.imageView.frame = imageFrame;
            self.imageView.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        }
    }
}

