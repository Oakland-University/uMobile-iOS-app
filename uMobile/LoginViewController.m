//
//  LoginViewController.m
//  uMobile
//
//  Created by Andrew Clissold & Skye Schneider on 2/26/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "LoginViewController.h"

#import "Authenticator.h"
#import "KeychainItemWrapper.h"
#import "PortletViewController.h"
#import "JSON.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UISwitch *rememberMeSwitch;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end

@implementation LoginViewController

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
    self.navigationItem.title = @"Log In";

    // Theming
    self.rememberMeSwitch.onTintColor = kPrimaryTintColor;
    [self.signInButton setTitleColor:kTextTintColor forState:UIControlStateNormal];
    [self.signInButton setTitleColor:kTextTintColor forState:UIControlStateSelected];
    self.activityIndicatorView.color = kPrimaryTintColor;
    self.view.backgroundColor = kSecondaryTintColor;
    self.usernameTextField.placeholder = kUsernamePlaceholder;

    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismiss)
                                                 name:kLoginSuccessNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginFailure)
                                                 name:kLoginFailureNotification
                                               object:nil];

    [self prepareScrollView];
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginFailure {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.loginIndicator stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid credentials, please try again."
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self login:nil];
        [textField resignFirstResponder];
    }
    return YES;
}

- (IBAction)login:(UIButton *)sender {
    [self.view endEditing:YES];

    [self.loginIndicator startAnimating];

    dispatch_async(dispatch_get_main_queue(), ^{
        self.signInButton.titleLabel.textColor = kTextTintColor;
    });

    [[Authenticator sharedAuthenticator] authenticateUsingUsername:self.usernameTextField.text
                                                          password:self.passwordTextField.text
                                                    updateKeychain:[self.rememberMeSwitch isOn]];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.scrollView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 15.0, 0.0);
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 15.0, 0.0);
    }];
}

- (void)resetScrollViewContentPosition:(NSNotification *)notification {
    [UIView animateWithDuration:0.3 animations:^{
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.contentOffset = CGPointMake(0.0, -60.0);
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareScrollView {
    CGFloat statusBarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
    CGFloat navigationBarHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0, 0.0, -(statusBarHeight + navigationBarHeight), 0.0);
    self.scrollView.contentInset = insets;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetScrollViewContentPosition:)
                                                 name:UIKeyboardWillHideNotification object:nil];

}

- (IBAction)forgotPassword:(id)sender {
    NSURL *URL = [NSURL URLWithString:kForgotPasswordURL];
    [[UIApplication sharedApplication] openURL:URL];
}

@end
