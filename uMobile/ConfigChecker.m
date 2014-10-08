//
//  ConfigChecker.m
//  uMobile
//
//  Created by Andrew Clissold on 9/30/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import "ConfigChecker.h"
#import "Constants.h"

@interface ConfigChecker ()

@property (nonatomic, strong) NSURL *configURL;
@property (nonatomic, strong) NSDictionary *configJSON;

@end

@implementation ConfigChecker

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = info[@"CFBundleVersion"];
        NSString *configURLString = [NSString stringWithFormat:@"%@%@%@/config",
                                     kBaseURL, kConfigWebappPath, appVersion];
        self.configURL = [NSURL URLWithString:configURLString];
        self.configJSON = [self getAndParseConfigJSON];
    }
    return self;
}

#pragma mark - Config Checking

- (void)check {
    if (!kShouldRunConfigCheck) { return; }

    [self checkUpgradeRequired];
}

- (void)checkUpgradeRequired {
    BOOL updateRequired = [(NSNumber *)self.configJSON[@"upgradeRequired"] boolValue];
    if (updateRequired) {
        NSLog(@"required");
    } else {
        NSLog(@"not required");
    }
}

#pragma mark - JSON Handling

// Returns configJSON, or nil if an error is encountered.
- (NSDictionary *)getAndParseConfigJSON {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.configURL];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    NSError *error;
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];

    if (error) {
        // Internet connection offline?
        NSLog(@"Error getting response: %@", [error localizedDescription]);
        return nil;
    }

    NSDictionary *configJSON = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];

    if (error) {
        NSLog(@"JSON parse error: %@", [error localizedDescription]);
        return nil;
    }

    return configJSON;
}

@end
