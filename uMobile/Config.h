//
//  Config.h
//  uMobile
//
//  Connects to the umobile-global-config webapp to respond to server-side configuration settings.
//
//  Created by Andrew Clissold on 9/30/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Config : NSObject<UIAlertViewDelegate>

@property (nonatomic, getter=isAvailable) BOOL available;
@property (nonatomic, getter=isUpgradeRecommended) BOOL upgradeRecommended;
@property (nonatomic, getter=isUpgradeRequired) BOOL upgradeRequired;

// To help determine if ErrorViewController should be presented.
@property (nonatomic, getter=hasUnrecoverableError) BOOL unrecoverableError;

@property (nonatomic, strong) NSArray *disabledPortlets;
@property (nonatomic, strong) NSArray *disabledFolders;

+ (instancetype)sharedConfig;

typedef void (^completion)(void); // crash-course on working with blocks: http://goo.gl/jJzNLr
- (void)checkWithCompletion:(completion)completion;
- (void)showUpgradeRecommendedAlert;

@end
