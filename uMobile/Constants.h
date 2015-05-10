//
//  Constants.h
//  uMobile
//
//  Contains shared NSString constants used throughout the app to avoid typos and aid in refactoring.
//
//  Created by Andrew Clissold & Skye Schneider on 3/13/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#ifndef uMobile_Constants_h
#define uMobile_Constants_h

// ==================== Global Theme Colors ====================

#define kPrimaryTintColor [UIColor colorWithRed:245/255.0f green:148/255.0f blue:73/255.0f alpha:1.0]
#define kSecondaryTintColor [UIColor colorWithRed:98/255.0f green:136/255.0f blue:196/255.0f alpha:1.0]
#define kTextTintColor [UIColor whiteColor]

// See Constants.m for these
FOUNDATION_EXPORT NSString *const kTitle;
FOUNDATION_EXPORT NSString *const kBaseURL;
FOUNDATION_EXPORT NSString *const kCasServer;
FOUNDATION_EXPORT NSString *const kForgotPasswordURL;
FOUNDATION_EXPORT NSString *const kUsernamePlaceholder;
FOUNDATION_EXPORT NSString *const kLayoutPath;
FOUNDATION_EXPORT NSString *const kRestletPath;
FOUNDATION_EXPORT NSString *const kLoginService;
FOUNDATION_EXPORT NSString *const kLogoutService;
FOUNDATION_EXPORT NSString *const kMainPageURL;
FOUNDATION_EXPORT NSString *const kConfigWebappPath;
FOUNDATION_EXPORT NSString *const kLoginSuccessNotification;
FOUNDATION_EXPORT NSString *const kLoginFailureNotification;
FOUNDATION_EXPORT NSString *const kRememberMeFailureNotification;
FOUNDATION_EXPORT NSString *const kLogoutSuccessNotification;
FOUNDATION_EXPORT NSString *const kLogoutFailureNotification;
FOUNDATION_EXPORT NSString *const kAppStoreURL;
FOUNDATION_EXPORT NSString *const kUserAgent;
FOUNDATION_EXPORT NSString *const kUPortalCredentials;
FOUNDATION_EXPORT NSString *const kLoggingInText;
FOUNDATION_EXPORT NSString *const kGoToAppStoreTitle;
FOUNDATION_EXPORT NSString *const kErrorNavigationControllerIdentifier;
FOUNDATION_EXPORT NSString *const kCasLogin;
FOUNDATION_EXPORT BOOL const kShouldRunConfigCheck;
FOUNDATION_EXPORT NSString *const kConfigUnavailableMessage;
FOUNDATION_EXPORT NSString *const kUpgradeRecommendedMessage;
FOUNDATION_EXPORT NSString *const kUpgradeRequiredMessage;

#endif
