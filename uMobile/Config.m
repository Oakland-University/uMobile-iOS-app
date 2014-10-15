//
//  Config.m
//  uMobile
//
//  Created by Andrew Clissold on 9/30/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import "Config.h"
#import "Constants.h"

@interface Config ()

@property (nonatomic, strong) NSURL *configURL;
@property (nonatomic, strong) NSDictionary *configJSON;

@end

@implementation Config

+ (instancetype)sharedConfig {
    static Config *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[self alloc] init];
        if (config) {
            NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
            NSString *appVersion = info[@"CFBundleVersion"];
            NSString *configURLString = [NSString stringWithFormat:@"%@%@%@/config",
                                         kBaseURL, kConfigWebappPath, appVersion];
            config.configURL = [NSURL URLWithString:configURLString];

            // Initialize properties to sensible defaults in
            // case kShouldRunConfigCheck has disabled checking.
            config.available = YES;
            config.upgradeRecommended = NO;
            config.upgradeRequired = NO;
            config.unrecoverableError = NO;
        }
    });
    return config;
}

#pragma mark - Config Checking

- (void)check {
    if (!kShouldRunConfigCheck) { return; } // no-op if this hasn't been set to YES in Constants.m

    [self getAndParseConfigJSON];

    [self checkAvailability];
    if (![self isAvailable]) { return; }

    [self checkUpgradeRecommended];
    [self checkUpgradeRequired];
}

- (void)checkAvailability {
    if (!self.configJSON) {
        self.available = NO;
        self.unrecoverableError = YES;
    }
}

- (void)checkUpgradeRecommended {
    self.upgradeRecommended = [(NSNumber *)self.configJSON[@"upgradeRecommended"] boolValue];
}

- (void)checkUpgradeRequired {
    self.upgradeRequired = [(NSNumber *)self.configJSON[@"upgradeRequired"] boolValue];
    if (self.upgradeRequired) {
        self.unrecoverableError = YES;
    }
}

#pragma mark - JSON Handling

// Returns configJSON, or nil if an error is encountered.
- (void)getAndParseConfigJSON {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.configURL];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    NSError *error;
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];

    if (error) {
        // Internet connection offline?
        NSLog(@"Error getting configJSON: %@", [error localizedDescription]);
        return;
    }

    NSDictionary *configJSON = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];

    if (error) {
        NSLog(@"configJSON parse error: %@", [error localizedDescription]);
        return;
    }

    // No errors encountered; assign the constructed dictionary.
    self.configJSON = configJSON;
}

@end
