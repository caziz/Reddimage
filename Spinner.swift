//
//  Spinner.swift
//  Reddimage
//
//  Created by Christopher Aziz on 7/6/17.
//  Copyright © 2017 Christopher Aziz. All rights reserved.
//

import UIKit
class Spinner {
    let activityIndicator : UIActivityIndicatorView
    init() {}
    static func spin() {
        activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 50, 50))
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.White
        activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5)
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.sharedApplication.beginIgnoringInteractionEvents()
    }
    
    static func stopSpin() {
        activityIndicator.stopAnimating()
        UIApplication.sharedApplication.endIgnoringInteractionEvents()
    }

}

/*
 
 */
