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
    self.available = self.configJSON != nil;
    self.unrecoverableError = !self.available;
}

- (void)checkUpgradeRecommended {
    self.upgradeRecommended = [(NSNumber *)self.configJSON[@"upgradeRecommended"] boolValue];
}

- (void)checkUpgradeRequired {
    self.upgradeRequired = [(NSNumber *)self.configJSON[@"upgradeRequired"] boolValue];
    self.unrecoverableError = self.upgradeRequired;
}

#pragma mark - Alerts

- (void)showUpgradeRecommendedAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kUpgradeRecommendedMessage
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Later"
                                          otherButtonTitles:kGoToAppStoreTitle, nil];
    alert.delegate = self;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:kGoToAppStoreTitle]) {
        NSURL *URL = [NSURL URLWithString:kAppStoreURL];
        [[UIApplication sharedApplication] openURL:URL];
    }
}


#pragma mark - JSON Handling

// Returns configJSON, or nil if an error is encountered.
- (void)getAndParseConfigJSON {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.configURL];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] init];
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (response.statusCode != 200) {
        NSLog(@"Error getting configJSON (received status code %ld)", response.statusCode);
        if (error) { NSLog(@"%@", [error localizedDescription]); }
        return;
    }

    NSDictionary *configJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (error) {
        NSLog(@"configJSON parse error: %@", [error localizedDescription]);
        return;
    }

    // No errors encountered; assign the constructed dictionary.
    self.configJSON = configJSON;
}

@end
