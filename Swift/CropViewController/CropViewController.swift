//
//  CropViewController.swift
//  CropViewControllerExample
//
//  Created by Tim Oliver on 18/11/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

import UIKit
import TOCropViewController

class CropViewController: UIViewController {
    
    public var image: UIImage?
    private let toCropViewController: TOCropViewController!
    
    init(image: UIImage) {
        self.image = image
        self.toCropViewController = TOCropViewController(image: image)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
