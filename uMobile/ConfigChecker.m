//
//  ConfigChecker.m
//  uMobile
//
//  Created by Andrew Clissold on 9/30/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import "ConfigChecker.h"

@implementation ConfigChecker

- (void)check {
    [self checkVersion];
}

- (void)checkVersion {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = info[@"CFBundleVersion"];
    NSLog(@"Checking %@", appVersion);
}

@end
