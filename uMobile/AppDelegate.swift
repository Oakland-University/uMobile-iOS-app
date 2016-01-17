//
//  AppDelegate.swift
//  uMobile
//
//  Created by Andrew Clissold on 1/1/16.
//  Copyright © 2016 Oakland University. All rights reserved.
//

import UIKit

//  This singleton object provides the ability to perform custom tasks if any of the events
//  handled by the UIApplicationDelegate protocol occur, such as low memory warnings or
//  state restoration.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: UIApplicationDelegate

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        theme()
        configureSplitView()
        return true
    }

    func applicationWillEnterForeground(application: UIApplication) {
        checkConfig()
    }

    // MARK: Implementation

    func theme() {
        window?.tintColor = ThemeColors.primary
        UINavigationBar.appearance().barTintColor = ThemeColors.secondary
    }

    func configureSplitView() {
        let splitViewController = window?.rootViewController as? UISplitViewController
        guard splitViewController?.viewControllers.count > 0 else { return }
        let navigationController = splitViewController?.viewControllers[1] as? UINavigationController
        let portletViewController = navigationController?.topViewController as? PortletViewController

        splitViewController?.view.backgroundColor = ThemeColors.primary
        splitViewController?.delegate = portletViewController
    }

    func checkConfig() {
        let config = Config.sharedConfig()
        config.checkWithCompletion {
            if config.unrecoverableError {
                if let errorViewController = self.window?.rootViewController?.storyboard?.instantiateViewControllerWithIdentifier(.ErrorNavigationController) {
                    self.window?.rootViewController?.presentViewController(errorViewController, animated: true, completion: nil)
                }
            } else if config.upgradeRecommended {
                config.showUpgradeRecommendedAlert()
            }
        }
    }

}
