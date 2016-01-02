//
//  ThemeColors.swift
//  uMobile
//
//  Created by Andrew Clissold on 1/1/16.
//  Copyright © 2016 Oakland University. All rights reserved.
//

import UIKit

/// Contains a global color palette and can be configured to taste.
///
/// - primary: the tint color for controls like buttons, switches, etc.
/// - secondary: the color for navigation controllers and other background views
/// - text: the color for labels and other display text
struct ThemeColors {
    static let primary = UIColor(red: 245/255, green: 148/255, blue: 73/255, alpha: 1)
    static let secondary = UIColor(red: 98/255, green: 136/255, blue: 196/255, alpha: 1)
    static let text = UIColor.whiteColor()
}
