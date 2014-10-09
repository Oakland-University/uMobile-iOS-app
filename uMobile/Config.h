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

@interface Config : NSObject

@property (nonatomic, getter=isUpgradeRequired) BOOL upgradeRequired;
@property (nonatomic, getter=isAvailable) BOOL available;

// To help determine if ErrorViewController should be presented.
@property (nonatomic, getter=hasUnrecoverableError) BOOL unrecoverableError;

+ (instancetype)sharedConfig;

- (void)check;

@end
