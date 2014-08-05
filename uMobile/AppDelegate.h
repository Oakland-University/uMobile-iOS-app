//
//  AppDelegate.h
//  uMobile
//
//  This singleton object provides the ability to perform custom tasks if any of the events
//  handled by the UIApplicationDelegate protocol occur, such as low memory warnings or
//  state restoration.
//
//  Created by Andrew Clissold & Skye Schneider 11/20/13.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
