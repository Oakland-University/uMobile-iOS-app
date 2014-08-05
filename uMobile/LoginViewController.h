//
//  LoginViewController.h
//  uMobile
//
//  Controls a login view, with standard UIButton and UITextFields. These views are
//  all embedded within a UIScrollView whose size changes depending on if the
//  keyboard is onscreen or not, enabling panning if the content doesn't fit in the
//  space between the navigation bar and the keyboard.
//
//  The heavy lifting for authentication with CAS is in the Authenticator class.
//
//  Created by Andrew Clissold & Skye Schneider on 2/26/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginIndicator;

@end
