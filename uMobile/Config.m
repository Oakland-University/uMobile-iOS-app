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

- (void)checkWithCompletion:(completion)completion {
    if (!kShouldRunConfigCheck) {
        // A no-op if this hasn't been set to YES in Constants.m.
        completion();
        return;
    }

    [self getAndParseConfigJSONWithCompletion:^{
        [self checkAvailability];
        if (![self isAvailable]) {
            completion();
            return;
        }

        [self checkUpgradeRecommended];
        [self checkUpgradeRequired];

        completion();
    }];
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

// Sets self.configJSON, or leaves it nil if an error is encountered.
- (void)getAndParseConfigJSONWithCompletion:(completion)completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.configURL];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;

        if (statusCode != 200) {
            NSLog(@"Error getting configJSON (received status code %ld)", (long)statusCode);
            if (connectionError) {
                NSLog(@"%@", [connectionError localizedDescription]);
            }
            completion();
            return;
        }

        NSError *error;
        NSDictionary *configJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

        if (error) {
            NSLog(@"configJSON parse error: %@", [error localizedDescription]);
            completion();
            return;
        }

        // No errors encountered; assign the constructed dictionary.
        self.configJSON = configJSON;

        completion();
    }];
}

@end
