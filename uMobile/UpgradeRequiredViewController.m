//
//  UpgradeRequiredViewController.m
//  uMobile
//
//  Created by Andrew Clissold on 10/8/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import "UpgradeRequiredViewController.h"

@interface UpgradeRequiredViewController ()

@property (weak, nonatomic) IBOutlet UIButton *appStoreButton;
@property (weak, nonatomic) IBOutlet UITextView *upgradeRequiredTextView;

@end

@implementation UpgradeRequiredViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.appStoreButton setTitleColor:kPrimaryTintColor forState:UIControlStateNormal];
    self.view.backgroundColor = kSecondaryTintColor;

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
    if ([self.upgradeRequiredTextView respondsToSelector:@selector(setTextContainerInset:)]) {
        // iOS 7+
        self.upgradeRequiredTextView.textContainerInset = UIEdgeInsetsZero;
    }
}

- (IBAction)goToAppStoreTapped:(UIButton *)sender {
    NSURL *url = [NSURL URLWithString:kAppStoreURL];
    [[UIApplication sharedApplication] openURL:url];
}

@end
