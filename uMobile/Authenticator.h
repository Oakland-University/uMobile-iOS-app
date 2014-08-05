//
//  Authenticator.h
//  uMobile
//
//  Does the heavy lifting for authentication with CAS. After simply calling
//  authenticateUsingUsername:password:, any request in a UIWebView to a CAS-
//  protected page will succeed.
//
//  See the implementation file for a description of how it works internally.
//
//  Created by Andrew Clissold on 4/30/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Authenticator : UIView <UIWebViewDelegate>

@property (nonatomic, strong) NSString *JSESSIONURL;

+ (instancetype)sharedAuthenticator;

- (void)authenticateUsingUsername:(NSString *)username
                         password:(NSString *)password
                   updateKeychain:(BOOL)updateKeychain;

- (void)logOut;

- (BOOL)hasStoredCredentials;
- (void)logInWithStoredCredentials;

@end
