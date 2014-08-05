//
//  Authenticator.m
//  uMobile
//
//  How this class performs authentication:
//      1. authenticateUsingUsername:password: performs a GET on the uPortal login page
//      2. The HTML response is parsed by parsePostDataFromResponse, combing the username,
//         password, and all other relevant information needed to perform an auth POST to CAS
//      3. The POST that would be performed by clicking "Sign In" on a desktop browser is performed
//         by sendPostToURL. This has some weird code in it--although Authenticator can be considered
//         a Controller object, it performs this task by loading the POST into an invisible UIWebView.
//         Doing this has the side effects that UIWebView normally gives you--such as cookie management--
//         allowing other UIWebView objects to "magically" still be authenticated with CAS.
//      4. One of two events occur:
//         a. UIWebViewDelegate's webView:shouldStartLoadWithRequest: method notices that the webview has
//            successfully logged in because it's attempting to load render.uP, at which point the webview
//            is told to stop loading and a login success notification is broadcast. This causes LoginViewController
//            to dismiss itself and the app returns to the view is was previously on.
//         b. webViewDidFinishLoad: with a page containing the string "errors," implying the authentication failed.
//            An alert is shown and the user has the option to fix their credentials and try again.
//
//  Created by Andrew Clissold on 4/30/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "Authenticator.h"

#import "KeychainItemWrapper.h"
#import "LoginViewController.h"
#import "NSString+URLEncoding.h"

@interface Authenticator ()

@property NSString *username;
@property NSString *password;

@property (nonatomic, strong) KeychainItemWrapper *keychain;

@property (nonatomic, getter = isLoggingIn) BOOL loggingIn;
@property (nonatomic, getter = shouldUpdateKeychain) BOOL updateKeychain;

@end

@implementation Authenticator

+ (instancetype)sharedAuthenticator {
    static Authenticator *sharedAuthenticator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAuthenticator = [[self alloc] init];
    });
    return sharedAuthenticator;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kUPortalCredentials accessGroup:nil];
        self.JSESSIONURL = [NSString stringWithFormat:@"%@%@%@%@", kCasServer, kCasLogin, kBaseURL, kLoginService];
    }
    return self;
}

- (BOOL)hasStoredCredentials {
    NSString *username = (NSString *)[self.keychain objectForKey:(__bridge id)(kSecAttrAccount)];
    if ([username length]) {
        return YES;
    }
    return NO;
}

- (void)deleteStoredCredentials {
    [self.keychain setObject:@"" forKey:(__bridge id)kSecAttrAccount];
    [self.keychain setObject:@"" forKey:(__bridge id)kSecValueData];
}

- (void)logOut {
    NSString *logoutURL = [kBaseURL stringByAppendingString:kLogoutService];
    NSURL *url = [NSURL URLWithString:logoutURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    NSError *error;
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
         if (statusCode != 200 || connectionError) {
             if (connectionError) {
                 NSLog(@"Error sending logout request: %@", [error localizedDescription]);
             }
             NSLog(@"A logout failure occured with HTTP status code %ld.", (long)statusCode);
             [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutFailureNotification object:nil];
             return;
         }

         // Purge the old session cookie
         NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:self.JSESSIONURL]];
         for (NSHTTPCookie *cookie in cookies) {
             if ([cookie.name isEqualToString:@"JSESSIONID"]) {
                 [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
             }
         }

         [self deleteStoredCredentials];
         [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutSuccessNotification object:nil];
     }];
}

- (void)logInWithStoredCredentials {
    NSString *username = (NSString *)[self.keychain objectForKey:(__bridge id)(kSecAttrAccount)];
    if ([username length]) {
        NSData *passwordData = [self.keychain objectForKey:(__bridge id)(kSecValueData)];
        NSString *password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
        [self authenticateUsingUsername:username password:password updateKeychain:NO];
    } else {
        NSLog(@"Error: logInWithStoredCredentials called, but no credentials were found in the keychain");
    }
}

- (void)authenticateUsingUsername:(NSString *)username
                         password:(NSString *)password
                   updateKeychain:(BOOL)updateKeychain {
    self.username = username;
    self.password = password;
    self.updateKeychain = updateKeychain;

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.JSESSIONURL]];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
         if (!connectionError) {
             if ([[response URL].lastPathComponent isEqualToString:@"render.uP"]) {
                 // If this if condition was YES, a previous call to this method must have been
                 // interrupted before the login success/failure notification could be broadcasted,
                 // possibly by poor network conditions.

                 // Broadcast a login success notification because if this method is called, the app
                 // must be waiting for one. And exit early because the following methods will be
                 // irrelevant (and even crash the app).
                 [[NSNotificationCenter defaultCenter] postNotificationName:kLoginSuccessNotification object:nil];
                 self.loggingIn = NO;
                 return;
             }
             NSData *postData = [self parsePostDataFromResponse:data];
             [self sendPostToURL:[NSURL URLWithString:self.JSESSIONURL] usingData:postData];
         } else {
             [[NSNotificationCenter defaultCenter] postNotificationName:kLoginFailureNotification object:nil];
             NSLog(@"%@", [connectionError localizedDescription]);
         }
     }];

}

- (NSData *)parsePostDataFromResponse:(NSData *)data {
    NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *lt, *execution;

    // Parse the LT and execution from the HTML response body
    NSString *ltInputTagString = @"input type=\"hidden\" name=\"lt\" value=\"";
    NSString *ltRegex = @"([a-zA-Z0-9\\-]*)?";
    NSRange ltInputTagRange = [responseBody rangeOfString:[NSString stringWithFormat:@"%@%@", ltInputTagString, ltRegex]
                                                  options:NSRegularExpressionSearch];
    NSUInteger ltPosition = ltInputTagRange.location + ltInputTagString.length;
    NSRange ltRange = NSMakeRange(ltPosition, ltInputTagRange.length - ltInputTagString.length);
    lt = [responseBody substringWithRange:ltRange];

    NSString *executionInputTagString = @"input type=\"hidden\" name=\"execution\" value=\"";
    NSString *executionRegex = ltRegex;
    NSRange executionInputTagRange = [responseBody rangeOfString:[NSString stringWithFormat:@"%@%@",
                                                                  executionInputTagString, executionRegex]
                                                         options:NSRegularExpressionSearch];
    NSUInteger executionPosition = executionInputTagRange.location + executionInputTagString.length;
    NSRange executionRange = NSMakeRange(executionPosition, executionInputTagRange.length - executionInputTagString.length);
    execution = [responseBody substringWithRange:executionRange];

    // Combine the username and password with the LT and execution to POST to CAS
    NSString *escapedPassword = [self.password stringByAddingURLEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *postData = [NSString stringWithFormat:@"username=%@&password=%@"
                          "&lt=%@&execution=%@&_eventId=submit&submit=Sign+In",
                          self.username, escapedPassword, lt, execution];
    return [postData dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)sendPostToURL:(NSURL *)url usingData:(NSData *)postData {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        webView.alpha = 0.0;
        webView.delegate = self;
        [self addSubview:webView];
        self.loggingIn = YES;
        [webView loadRequest:request];
    });
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    if ([[[request URL] lastPathComponent] isEqualToString:@"render.uP"]) {

        if ([self shouldUpdateKeychain]) {
            [self.keychain setObject:self.username forKey:(__bridge id)kSecAttrAccount];
            [self.keychain setObject:self.password forKey:(__bridge id)kSecValueData];
        }

        // Broadcast a login notification so
        //     1) MainViewController can re-parse the JSON layout feed in its viewWillAppear: method, or
        //     2) PortletViewController can intercept an unexpected login occurring from its web view
        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginSuccessNotification object:nil];
        self.loggingIn = NO;
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if ([self isLoggingIn]) {
        NSString *status = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('status').className"];
        if ([status isEqualToString:@"errors"]) {
            self.loggingIn = NO;
            [[NSNotificationCenter defaultCenter] postNotificationName:kLoginFailureNotification object:nil];
            if ([self hasStoredCredentials]) {
                [self deleteStoredCredentials];
                [[NSNotificationCenter defaultCenter] postNotificationName:kRememberMeFailureNotification object:nil];
            }
        }
    }
}

@end
