//
//  UpgradeRequiredViewController.m
//  uMobile
//
//  Created by Andrew Clissold on 10/8/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import "UpgradeRequiredViewController.h"

@interface UpgradeRequiredViewController ()

@end

@implementation UpgradeRequiredViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
        // iOS >= 7
        self.navigationController.navigationBar.barTintColor = kSecondaryTintColor;
        self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: kTextTintColor};
    } else {
        // iOS < 7
        self.navigationController.navigationBar.tintColor = kSecondaryTintColor;
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: kTextTintColor}];
    }
    
    self.title = kTitle;
}

@end
