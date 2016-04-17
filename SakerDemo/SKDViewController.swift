//
//  ViewController.swift
//  SakerDemo
//
//  Created by Thomas Morrell on 17/04/2016.
//  Copyright © 2016 thomasmorrell. All rights reserved.
//

import UIKit

class SKDContentViewController: UIViewController {
    
    // Properties
    
    // Storyboard outlet properties
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var callToActionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.alpha = 0.0
        bodyLabel.alpha = 0.0
        callToActionLabel.alpha = 0.0
        imageView.alpha = 0.0
        
        let frame = imageView.frame
        imageView.frame = CGRectOffset(frame, 20.0, -20.0)
        
        UIView.animateWithDuration(1.0, delay: 0.0, options: [.CurveEaseOut], animations: { [weak self] in
            
            self?.imageView.frame = frame
            }, completion: nil)
        
        UIView.animateWithDuration(0.6, delay: 0.4, options: [.CurveEaseOut], animations: { [weak self] in
            
            self?.imageView.alpha = 1.0
            self?.titleLabel.alpha = 1.0
            self?.bodyLabel.alpha = 1.0
            self?.callToActionLabel.alpha = 1.0
            }, completion: nil)
    }
}

