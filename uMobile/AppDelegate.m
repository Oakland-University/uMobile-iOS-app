//
//  AppDelegate.m
//  uMobile
//
//  Created by Andrew Clissold & Skye Schneider 11/20/13.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "AppDelegate.h"

#import "MainViewController.h"
#import "PortletViewController.h"
#import "Config.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set the global tint color
    if ([self.window respondsToSelector:@selector(setTintColor:)]) {
        self.window.tintColor = kPrimaryTintColor;
        [UINavigationBar appearance].barTintColor = kSecondaryTintColor;
    } else {
        self.window.backgroundColor = kPrimaryTintColor;
        [UINavigationBar appearance].backgroundColor = kSecondaryTintColor;
    }

    // Configure split view on iPad
    UIViewController *viewController = self.window.rootViewController;
    if ([viewController isKindOfClass:UISplitViewController.class]) {
        // Set up the view controllers found in the Main_iPad storyboard
        UISplitViewController *splitViewController = (UISplitViewController *)viewController;
        splitViewController.view.backgroundColor = kPrimaryTintColor;
        UINavigationController *navigationController = splitViewController.viewControllers[0];
        MainViewController *mainViewController = (MainViewController *)navigationController.topViewController;
        PortletViewController *portletViewController = (PortletViewController *)
            ((UINavigationController *)splitViewController.viewControllers[1]).topViewController;
        mainViewController.delegate = portletViewController;
        splitViewController.delegate = portletViewController;
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    // Perform the same check that happens on startup.
    Config *config = [Config sharedConfig];
    [config check];
    if (config.unrecoverableError) {
        UIViewController *errorViewController =
        [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:kErrorNavigationControllerIdentifier];
        [self.window.rootViewController presentViewController:errorViewController animated:YES completion:nil];
    } else if (config.upgradeRecommended) {
        [config showUpgradeRecommendedAlert];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
