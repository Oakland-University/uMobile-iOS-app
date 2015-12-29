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

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) NJKWebViewProgress *progressProxy;

@property (nonatomic) int webViewLoads;

// Only used when in a split view controller
@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;

@property (nonatomic, weak) IBOutlet UIToolbar *navigationToolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *stopButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *refreshButton;

// iPad-only properties
@property (nonatomic, strong) UIView *coverView;
@property (nonatomic, strong) UITapGestureRecognizer *tapOutGestureRecognizer;

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

- (void)selectedPortlet:(NSDictionary *)portletInfo {
    self.portletInfo = portletInfo;
    [self configureView];
}

- (void)setPortletInfo:(NSDictionary *)portletInfo {
    if (_portletInfo != portletInfo) {
        _portletInfo = portletInfo;
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self performInitialSetup];
    [self logInOrConfigureView];
}

- (void)performInitialSetup {
    // Set up the UIBarButtonItems
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    activityIndicatorView.color = kPrimaryTintColor;
    [activityIndicatorView startAnimating];

    self.activityIndicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];

    self.loggingInBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:kLoggingInText
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:nil
                                                                  action:nil];
    self.loggingInBarButtonItem.enabled = NO;

    [self configureSplitViewAppearance];
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(rememberMeFailure)
                                                name:kRememberMeFailureNotification object:nil];

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

-(void)logInOrConfigureView {
    if (self.splitViewController && [[Authenticator sharedAuthenticator] hasStoredCredentials]) {
        // Add a loading indication to the navigation bar
        NSArray *loggingInItems = @[self.loggingInBarButtonItem, self.activityIndicatorBarButtonItem];
        self.navigationItem.rightBarButtonItems = loggingInItems;
        [[Authenticator sharedAuthenticator] logInWithStoredCredentials];
        // implicitly call configureView after a login success notification
    } else {
        [self configureView];
    }
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

    if (self.splitViewController && !self.tapOutGestureRecognizer && !self.presentingViewController) {

        // Cancel if Config should show ErrorViewController to avoid making that controller dismissable.
        if ([Config sharedConfig].unrecoverableError) { return; }

        self.tapOutGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                               action:@selector(tapOutDetected:)];
        self.tapOutGestureRecognizer.numberOfTapsRequired = 1;
        self.tapOutGestureRecognizer.cancelsTouchesInView = NO; // to still allow interaction in the presented view

        [self.view.window addGestureRecognizer:self.tapOutGestureRecognizer];
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
    // Use the info dictionary to set up the view's contents
    if (self.portletInfo) {
        // Set the title
        NSString *portletName = (self.portletInfo)[@"title"];
        self.navigationItem.title = portletName;
        self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        self.navigationItem.leftItemsSupplementBackButton = YES;

        self.webView.scalesPageToFit = YES; // enable zoom

        // Load the web page
        NSString *urlString = (self.portletInfo)[@"url"];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        self.progressView.progress = 0.0;
        [self.webView loadRequest:request];
    }
}

- (void)configureSplitViewAppearance {
    // Set the bar tint on iPad since this view controller has its own UINavigationController
    self.navigationController.navigationBar.barTintColor = kSecondaryTintColor;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: kTextTintColor};

    // Place a solid-color view over the UISplitViewController divider line to "hide" it.
    self.coverView = [[UIView alloc] initWithFrame:CGRectMake(320, 0, 1, 64)];
    self.coverView.backgroundColor = kSecondaryTintColor;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        self.coverView.hidden = YES;
    }
    [self.splitViewController.view addSubview:self.coverView];
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

- (void)configureLogInButton {
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Log In"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(logIn:)]];
}

- (void)configureLogOutButton {
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithTitle:@"Log Out"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(logOut:)]];
}

#pragma mark - Responding to Orientation Changes

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.splitViewController) {
        if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
            self.coverView.hidden = YES;
        } else {
            self.coverView.hidden = NO;
        }
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateTopOffset];

    if (self.splitViewController) {
        [self zoomWebView];
    }
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

- (void)zoomWebView {
    CGSize contentSize = self.webView.scrollView.contentSize;
    CGRect rect = CGRectMake(0, 0, contentSize.width, self.webView.bounds.size.height);
    [self.webView.scrollView zoomToRect:rect animated:YES];
}

- (void)tapOutDetected:(UITapGestureRecognizer *)sender {
    // Dismiss modal view controllers on iPad when tapped outside their bounds.
    if (sender.state == UIGestureRecognizerStateEnded) {
        UIViewController *mainViewController = [self.splitViewController.viewControllers firstObject];
        UIViewController *infoViewController = mainViewController.presentedViewController;
        if (infoViewController) {
            CGPoint point = [sender locationInView:nil]; // returns coordinates in window
            CGPoint convertedPoint = [infoViewController.view convertPoint:point fromView:self.view.window];
            if (![infoViewController.view pointInside:convertedPoint withEvent:nil]) {
                [infoViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
}

// Called when a login success notification occurs.
- (void)reloadRequestNextAppearance:(NSNotification *)notification {
    self.reloadRequestNextAppearance = YES;
}

- (void)resetProgressView {
    self.progressView.alpha = 0.0;
    self.progressView.progress = 0.0;
}

- (void)rememberMeFailure {
    if (self.splitViewController) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failure"
                                                        message:@"Unfortunately, you could not be logged in automatically "
                                                                 "with your saved credentials. Please try logging in again."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [self configureLogInButton];
        [self configureView];
    }
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
    self.webViewLoads--;

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self configureNavigationToolbar];

    if (self.webViewLoads == 0 && (self.splitViewController || self.presentingViewController)) {
        [self zoomWebView];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    self.webViewLoads++;

    // start a spinner for the user to know that the page is loading
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.progressView.alpha = 1.0;
    self.stopButton.enabled = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.webViewLoads = 0;

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

#pragma mark - Actions

- (IBAction)logOut:(id)sender {
    // Show and animate the activity indicator
    UIBarButtonItem *disabledLogOutButton = [[UIBarButtonItem alloc] init];
    disabledLogOutButton.title = @"Log Out";
    disabledLogOutButton.enabled = NO;

    self.navigationItem.rightBarButtonItems = @[disabledLogOutButton, self.activityIndicatorBarButtonItem];
    [[Authenticator sharedAuthenticator] logOut];
}

- (IBAction)logIn:(id)sender {
    [self performSegueWithIdentifier:@"LogInFromPortlet" sender:self];
}

@end
