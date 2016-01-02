//
//  StoryboardIdentifier.swift
//  uMobile
//
//  Created by Andrew Clissold on 1/1/16.
//  Copyright © 2016 uMobile. All rights reserved.
//

extension UIStoryboard {

    /// Always prefer this over the built-in version to avoid "stringly-typed" parameters.
    func instantiateViewControllerWithIdentifier(identifier: StoryboardIdentifier) -> UIViewController {
        return self.instantiateViewControllerWithIdentifier(identifier.rawValue)
    }

}

/// An enumeration of all view controller identifiers found in the storyboard.
enum StoryboardIdentifier: String {
    case ErrorNavigationController = "errorNavigationController"
}
