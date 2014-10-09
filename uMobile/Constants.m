//
//  Constants.m
//  uMobile
//
//  Created by Andrew Clissold & Skye Schneider on 4/22/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "Constants.h"

// ==================== Customizable Properties ====================

// These can be customized to fit your particular implementation.

// App title
NSString *const kTitle = @"uMobile";

// Main uPortal URL
NSString *const kBaseURL = @"http://mockuportal.appspot.com";

// Main CAS URL
NSString *const kCasServer = @"http://login.example.edu";

// Forgot password URL to open in Safari
NSString *const kForgotPasswordURL = @"http://forgot.example.edu";

// Username placeholder text for the Login view
NSString *const kUsernamePlaceholder = @"Username";

// Whether or not to check against the umobile-global-config webapp
BOOL const kShouldRunConfigCheck = YES;

// ==================== Fixed Properties ====================

// These shouldn't need to be modified.

// Path to layout.json relative to the root of kBaseURL
NSString *const kLayoutPath = @"/uPortal/layout.json";

// CAS restlet location relative to kCasServer
NSString *const kRestletPath = @"/cas/v1/tickets/";

// Login/logout relative to kBaseURL
NSString *const kLoginService = @"/uPortal/Login";
NSString *const kLogoutService = @"/uPortal/Logout";

// Main page URL to be intercepted if necessary
NSString *const kMainPageURL = @"/uPortal/normal/render.uP";

// umobile-global-config webapp path
NSString *const kConfigWebappPath = @"/umobile-global-config/iOS/";

// Notification center strings
NSString *const kLoginSuccessNotification = @"Login Successful";
NSString *const kLoginFailureNotification = @"Login Failure";
NSString *const kRememberMeFailureNotification = @"Remember Me Failure";
NSString *const kLogoutSuccessNotification = @"Logout Successful";
NSString *const kLogoutFailureNotification = @"Logout Failure";

// The link to your application on the App Store for ErrorViewController
NSString *const kAppStoreURL = @"http://example.edu";

// The URL associated with the JSESSIONID cookie
NSString *const kCasLogin = @"/cas/login?service=";

// Other
NSString *const kUserAgent = @"iPhone";
NSString *const kUPortalCredentials = @"uPortalCredentials";
NSString *const kLoggingInText = @"Logging In";
NSString *const kGoToAppStoreTitle = @"Go To App Store";
NSString *const kErrorNavigationControllerIdentifier = @"errorNavigationController";

// ==================== Config Messages ====================

NSString *const kConfigUnavailableMessage = @"Unfortunately, an error has occured. "
    "Please check your Internet connection and try again, or visit the website for "
    "more information.";
NSString *const kUpgradeRecommendedMessage = @"The current version of "
    "this app is out of date and we strongly recommended upgrading. Would you "
    "like to do this now?";
NSString *const kUpgradeRequiredMessage = @"Unfortunately, the current version of "
    "this app is out of date and must be updated. Please visit the App Store to "
    "download the new version.";
