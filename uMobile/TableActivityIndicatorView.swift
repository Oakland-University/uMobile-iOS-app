//
//  TableActivityIndicatorView.swift
//  uMobile
//
//  Created by Andrew Clissold on 1/2/16.
//  Copyright © 2016 Oakland University. All rights reserved.
//

/// An activity indicator intended to be centered in a table view.
class TableActivityIndicatorView: UIView {

    /// Creates the activity indicator with the specified frame and color.
    init(frame: CGRect, color: UIColor) {
        super.init(frame: frame)

        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicatorView.center = center
        activityIndicatorView.color = color
        activityIndicatorView.startAnimating()

        addSubview(activityIndicatorView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
