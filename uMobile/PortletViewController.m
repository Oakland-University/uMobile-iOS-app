//
//  PortletViewController.m
//  uMobile
//
//  Created by Andrew Clissold & Skye Schneider on 11/20/13.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "PortletViewController.h"

#import "Authenticator.h"
#import "LoginViewController.h"
#import "MainViewController.h"
#import "NJKWebViewProgress.h"
#import "Reachability.h"
#import "KeychainItemWrapper.h"
#import "Config.h"
#import "LayoutJSON.h"

@interface PortletViewController ()

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIImageView *placeholderImageView;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) NJKWebViewProgress *progressProxy;

// Only used when in a split view controller
@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;

@property (nonatomic, weak) IBOutlet UIToolbar *navigationToolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *stopButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *refreshButton;

@property (nonatomic) CGFloat lastOffset;
@property (nonatomic) CGFloat topOffset;
@property (nonatomic) CGFloat bottomOffset;
@property (nonatomic, getter = isScrollingDown) BOOL scrollingDown;
@property (nonatomic, getter = shouldReloadRequestNextApperance) BOOL reloadRequestNextAppearance;

@property (nonatomic, getter = isInDomain) BOOL inDomain;
@property (nonatomic) NSURLRequest *URLRequestToReload;

@property (nonatomic, strong) Reachability *networkReachability;
@property (nonatomic, strong) KeychainItemWrapper *keychain;

- (void)configureView;

@end

@implementation PortletViewController

#pragma mark - Detail Item Configuration

- (void)setPortletInfo:(NSDictionary *)portletInfo {
    if (_portletInfo != portletInfo) {
        _portletInfo = portletInfo;
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self performInitialSetup];
    [self configureView];
}

- (void)performInitialSetup {
    // Set up the UIBarButtonItems
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    activityIndicatorView.color = kPrimaryTintColor;
    [activityIndicatorView startAnimating];

    self.activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];

    self.navigationController.navigationBar.barTintColor = kSecondaryTintColor;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: kTextTintColor};

    [self updateTopOffset];

    self.webView.scalesPageToFit = YES;
    self.webView.scrollView.delegate = self;
    self.inDomain = YES;

    self.progressProxy = [[NJKWebViewProgress alloc] init];
    self.webView.delegate = self.progressProxy;
    self.progressProxy.webViewProxyDelegate = self;

    // Register with the notification center to reload the page if an unexpected login occurs
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(reloadRequestNextAppearance:)
                                                name:kLoginSuccessNotification object:nil];

    // Set up progress bar
    [self.progressView setHidden:NO];
    __weak PortletViewController *weakSelf = self;
    [self.view bringSubviewToFront:self.progressView];
    self.progressProxy.progressBlock = ^(float progress) {
        [weakSelf.progressView setProgress:progress animated:YES];
        if (progress >= 0.9f) {
            [weakSelf pauseAndHideProgressView];
        }
    };

    self.networkReachability = [Reachability reachabilityForInternetConnection];
    self.keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kUPortalCredentials accessGroup:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    if (!self.splitViewController) {
        if ([self.networkReachability currentReachabilityStatus] == NotReachable) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"The Internet connection appears to be offline."
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // This check is important because it will catch umobile-global-config unrecoverable errors
    // (such as upgrade required) if the callback occurs when another view controller is on-screen.
    if (self.splitViewController && [Config sharedConfig].unrecoverableError) { // iPad
        [self presentErrorViewController];
    }

    if ([self shouldReloadRequestNextApperance]) {
        self.reloadRequestNextAppearance = NO;
        [self.webView loadRequest:self.URLRequestToReload];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - View Configuration

- (void)configureView {
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;

    // Use the info dictionary to set up the view's contents
    if (self.portletInfo) {
        // Set the title
        NSString *portletName = (self.portletInfo)[@"title"];
        self.navigationItem.title = portletName;

        self.webView.scalesPageToFit = YES; // enable zoom

        // Load the web page
        NSString *urlString = (self.portletInfo)[@"url"];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        self.progressView.progress = 0.0;
        [self.webView loadRequest:request];
    } else {
        self.placeholderImageView.hidden = NO;
    }
}

- (void)configureNavigationToolbar {
    // Show the navigation toolbar only when outside of the uPortal domain.
    if ([[self.webView.request.URL absoluteString] rangeOfString:kBaseURL].location == NSNotFound) {
        self.inDomain = NO;
        self.navigationToolbar.alpha = 1;
    } else {
        self.inDomain = YES;
        self.navigationToolbar.alpha = 0;
    }

    self.backButton.enabled = [self.webView canGoBack];
    self.forwardButton.enabled = [self.webView canGoForward];
    self.stopButton.enabled = [self.webView isLoading];
}

#pragma mark - Responding to Orientation Changes

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateTopOffset];
}

#pragma mark - Miscellaneous

- (void)presentErrorViewController {
    UIViewController *errorViewController =
    [self.storyboard instantiateViewControllerWithIdentifier:kErrorNavigationControllerIdentifier];
    UINavigationController *navigationController = self.navigationController;
    [navigationController presentViewController:errorViewController animated:YES completion:nil];
}

- (void)updateTopOffset {
    // Used to determine whether or not to display the web navigation toolbar.
    CGFloat navigationAndStatusBarHeight = (CGRectGetHeight(self.navigationController.navigationBar.frame) +
                                            MIN(CGRectGetHeight([UIApplication sharedApplication].statusBarFrame),
                                                CGRectGetWidth([UIApplication sharedApplication].statusBarFrame)));
    self.topOffset = -navigationAndStatusBarHeight;
}


- (void)pauseAndHideProgressView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 400 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5 animations:^{
            self.progressView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.progressView.progress = 0;
        }];
    });
}

// Called when a login success notification occurs.
- (void)reloadRequestNextAppearance:(NSNotification *)notification {
    self.reloadRequestNextAppearance = YES;
}

- (void)resetProgressView {
    self.progressView.alpha = 0.0;
    self.progressView.progress = 0.0;
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc {
    barButtonItem.title = [NSString stringWithFormat:@"❮ %@", kTitle];
    self.navigationItem.leftBarButtonItem = barButtonItem;
    self.pc = pc;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    self.navigationItem.leftBarButtonItem = nil;
    self.pc = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)webView {
    // reset scrolling down so toolbar comes back
    self.scrollingDown = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)webView {
    [self updateLastOffsetWithScrollView:webView];
}

- (void)updateLastOffsetWithScrollView:(UIScrollView *)webView {
    if(webView.contentOffset.y > self.lastOffset && !(webView.contentOffset.y <= self.topOffset)) {
        [UIView animateWithDuration:0.5 animations:^{
            self.navigationToolbar.alpha = 0;
            self.scrollingDown = YES; // keep track of scrolling position so toolbar does not reappear after bottom bounce
        }];
    } else if(!self.scrollingDown && !self.inDomain){
        [UIView animateWithDuration:0.5 animations:^{
            self.navigationToolbar.alpha = 1;
            self.scrollingDown = NO;
        }];
    }
    self.lastOffset = webView.contentOffset.y;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self configureNavigationToolbar];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    // start a spinner for the user to know that the page is loading
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.progressView.alpha = 1.0;
    self.stopButton.enabled = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self resetProgressView];
    self.stopButton.enabled = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *url = [[request URL] absoluteString];

    // Cancel requests for uPortal's main portlet list webview and show the app's Main view instead
    NSString *portletListWebViewURLRegex = [NSString stringWithFormat:@"%@%@%@%@", @"^", kBaseURL, kMainPageURL, @"$"];
    if ([url rangeOfString:portletListWebViewURLRegex options:NSRegularExpressionSearch].location != NSNotFound) {
        [self.navigationController popViewControllerAnimated:YES];
        [self resetProgressView];
        return NO;
    }

    // Cancel requests for CAS logins and show the Login view instead
    if ([url rangeOfString:kCasServer].location != NSNotFound) {
        NSString *JSESSIONURL = [Authenticator sharedAuthenticator].JSESSIONURL;
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage]
                            cookiesForURL:[NSURL URLWithString:JSESSIONURL]];

        BOOL validSession = NO;
        for (NSHTTPCookie *cookie in cookies) {
            if ([cookie.name isEqualToString:@"JSESSIONID"]) {
                // Check if the user is still logged in by reading layout.json
                [LayoutJSON downloadLayoutJSON];
                if (![[LayoutJSON getLayoutJSON][@"username"] isEqualToString:@"guest"]) {
                    validSession = YES;
                    break;
                }
            }
        }

        if (!validSession) {
            [self performSegueWithIdentifier:@"LogInFromPortlet" sender:self];
            [self resetProgressView];
            return NO;
        }
    }

    // Force a portlet's mobile view if necessary by removing its navbar
    if ([url rangeOfString:kBaseURL].length && [url rangeOfString:@"/max/"].length) {
        NSMutableString *newURL = [NSMutableString stringWithString:url];
        [newURL replaceOccurrencesOfString:@"/max/"
                                withString:@"/detached/"
                                   options:0 range:NSMakeRange(0, newURL.length)];
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newURL]]];
        [self resetProgressView];
        return NO;
    }

    // Neither the main portlet list nor non-mobile portlet; continue to load as-is
    self.URLRequestToReload = request; // save the request in case an unexpected login occurs
    return YES;
}

@end
