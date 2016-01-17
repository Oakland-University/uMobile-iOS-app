//
//  HeaderView.swift
//  uMobile
//
//  Created by Andrew Clissold on 1/2/16.
//  Copyright © 2016 Oakland University. All rights reserved.
//

import UIKit

/// A `UIView` subclass that displays a label over a slight gradient background.
class HeaderView: UIView {

    @IBOutlet weak var label: UILabel!

    /// Creates a new header view with header text `text`.
    init(text: String) {
        let screenWidth = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let screenHeight = CGRectGetHeight(UIScreen.mainScreen().bounds)
        let statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication().statusBarFrame)
        let navigationBarHeight: CGFloat = 44 // can't call self.navigationController.navigationBar.height before init
        var frameWidth = max(screenWidth, screenHeight)
        frameWidth += statusBarHeight + navigationBarHeight

        let frame = CGRect(x: 0, y: 0, width: frameWidth, height: 30)
        let labelFrame = CGRect(x: 6, y: 0, width: frameWidth - 6, height: 30)

        super.init(frame: frame)

        let label = UILabel(frame: labelFrame)
        label.backgroundColor = UIColor.clearColor()
        label.font = UIFont.systemFontOfSize(22)
        label.text = text

        backgroundColor = UIColor.clearColor()

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = layer.bounds
        gradientLayer.colors = gradient(baseColor: ThemeColors.primary, delta: 0.06)

        layer.addSublayer(gradientLayer)
        addSubview(label)
    }

    /// Computes two color stops from `baseColor` by brightening and darkening it by `delta / 1.0`.
    private func gradient(baseColor baseColor: UIColor, delta: CGFloat) -> [CGColorRef] {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
        ThemeColors.primary.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

        let alpha: CGFloat = 0.95
        let brighter = min(brightness + delta, 1)
        let darker = max(brightness - delta, 0)

        let start = UIColor(hue: hue, saturation: saturation, brightness: brighter, alpha: alpha)
        let end = UIColor(hue: hue, saturation: saturation, brightness: darker, alpha: alpha)

        return [start.CGColor, end.CGColor]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
