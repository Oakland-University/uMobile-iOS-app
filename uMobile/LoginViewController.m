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
#import "LayoutJSON.h"

@interface LoginViewController ()

@property (nullable, strong, nonatomic) UITextField *activeTextField;

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

    self.navigationController.navigationBar.barTintColor = kSecondaryTintColor;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: kTextTintColor};
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.activeTextField resignFirstResponder];
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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
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

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* info = notification.userInfo;
    CGSize keyboardSize = [info[UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)forgotPassword:(id)sender {
    NSURL *URL = [NSURL URLWithString:kForgotPasswordURL];
    [[UIApplication sharedApplication] openURL:URL];
}

@end
