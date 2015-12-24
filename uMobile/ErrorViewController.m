//
//  ErrorViewController.m
//  uMobile
//
//  Created by Andrew Clissold on 10/8/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import "ErrorViewController.h"
#import "Config.h"
#import "Constants.h"

@interface ErrorViewController ()

@property (weak, nonatomic) IBOutlet UIButton *linkButton;
@property (weak, nonatomic) IBOutlet UITextView *errorMessageTextView;

@end

@implementation ErrorViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self theme];
    [self configureView];
}

// Sets up the text view content and button text/link based on Config's state.
- (void)configureView {
    // Set the text view content.
    [self configureTextView];

    // Set up the button.
    Config *config = [Config sharedConfig];
    if (!config.available) {
        NSString *title = [NSString stringWithFormat:@"Open %@ In Safari", kTitle];
        [self.linkButton setTitle:title forState:UIControlStateNormal];
    } else if (config.upgradeRequired) {
        [self.linkButton setTitle:kGoToAppStoreTitle forState:UIControlStateNormal];
    }
}

- (void)configureTextView {
    // Temporarily enable selection as a workaround for its style disappearing otherwise.
    self.errorMessageTextView.selectable = YES;

    if (![Config sharedConfig].available) {
        self.errorMessageTextView.text = kConfigUnavailableMessage;
    } else if ([Config sharedConfig].upgradeRequired) {
        self.errorMessageTextView.text = kUpgradeRequiredMessage;
    }

    self.errorMessageTextView.selectable = NO;
}

- (IBAction)linkButtonTapped:(UIButton *)sender {
    Config *config = [Config sharedConfig];
    if (!config.available) {
        NSURL *URL = [NSURL URLWithString:kBaseURL];
        [[UIApplication sharedApplication] openURL:URL];
    } else if (config.upgradeRequired) {
        NSURL *URL = [NSURL URLWithString:kAppStoreURL];
        [[UIApplication sharedApplication] openURL:URL];
    }
}

#pragma mark - Theming

- (void)theme {
    [self.linkButton setTitleColor:kPrimaryTintColor forState:UIControlStateNormal];
    self.view.backgroundColor = kSecondaryTintColor;

    self.navigationController.navigationBar.barTintColor = kSecondaryTintColor;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: kTextTintColor};

    self.title = kTitle;
    self.errorMessageTextView.textContainerInset = UIEdgeInsetsZero;
}

@end
