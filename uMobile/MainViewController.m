//
//  MainViewController.m
//  uMobile
//
//  Created by Andrew Clissold & Skye Schneider on 11/20/13.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "MainViewController.h"

#import "Authenticator.h"
#import "HeaderView.h"
#import "PortletViewController.h"
#import "Reachability.h"
#import "JSON.h"

@interface MainViewController ()

@property (nonatomic, strong) NSMutableArray *sectionContents;
@property (nonatomic, strong) NSMutableArray *sectionTitles;

@property (nonatomic, getter = shouldConfigureViewNextApperance) BOOL configureViewNextAppearance;
@property (nonatomic, strong) NSIndexPath *mostRecentlySelectedIndexPath;

@property (nonatomic, strong) UIBarButtonItem *activityIndicatorBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *loggingInBarButtonItem;

@property (nonatomic, strong) Reachability *networkReachability;

@end

@implementation MainViewController

#pragma mark - View Controller Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    if (self.mostRecentlySelectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:self.mostRecentlySelectedIndexPath animated:YES];
    }

    if ([self shouldConfigureViewNextApperance]) {
        [self configureView];
        self.configureViewNextAppearance = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    self.mostRecentlySelectedIndexPath = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.mostRecentlySelectedIndexPath) {
        [self.tableView selectRowAtIndexPath:self.mostRecentlySelectedIndexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
    }
}

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

    self.navigationItem.title = kTitle;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.networkReachability = [Reachability reachabilityForInternetConnection];
    [self.networkReachability startNotifier];

    [self registerWithNotificationCenter];

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

    if ([[Authenticator sharedAuthenticator] hasStoredCredentials]) {
        if (!self.splitViewController) {
            // Add a loading indication to the navigation bar
            NSArray *loggingInItems = @[self.loggingInBarButtonItem, self.activityIndicatorBarButtonItem];
            self.navigationItem.rightBarButtonItems = loggingInItems;
            [[Authenticator sharedAuthenticator] logInWithStoredCredentials];
            // implicitly call configureView after a login success notification
        }
    } else {
        [self configureView];
    }

}

- (void)configureView {
    [JSON downloadLayoutJSON];
    NSDictionary *dictJSON = [JSON getLayoutJSON];
    if (!dictJSON) { return; } // network unreachable

    // Build the rows of the table view from the JSON feed
    NSDictionary *layout = dictJSON[@"layout"];
    NSArray *folders = (NSArray *) layout[@"folders"];
    self.sectionTitles = [[NSMutableArray alloc] initWithCapacity:[folders count]];
    self.sectionContents = [[NSMutableArray alloc] init];

    if (!self.splitViewController) {
        if ([dictJSON[@"user"] isEqualToString:@"guest"]) {
            [self configureLogInButton];
        } else {
            [self configureLogOutButton];
        }
    } else {
        UINavigationController *navigationController = self.splitViewController.viewControllers[1];
        PortletViewController *portletViewController = [navigationController.childViewControllers firstObject];
        if ([dictJSON[@"user"] isEqualToString:@"guest"]) {
            [portletViewController configureLogInButton];
        } else {
            [portletViewController configureLogOutButton];
        }
    }

    for (NSDictionary *folder in folders) {
        NSMutableArray *cellContents = [NSMutableArray new];
        NSArray *portlets = folder[@"portlets"];
        for (NSDictionary *portlet in portlets) {
            NSString *thumbnailName = [NSString stringWithFormat:@"%@", portlet[@"fname"]];
            NSString *title = portlet[@"title"];
            NSString *description = portlet[@"description"];
            NSString *url = [NSString stringWithFormat:@"%@%@", kBaseURL, portlet[@"url"]];

            NSDictionary *cellContent = @{@"thumbnail": thumbnailName, @"title": title, @"description": description, @"url": url};
            [cellContents addObject:cellContent];
        }
        [self.sectionContents addObject:cellContents];
        [self.sectionTitles addObject:folder[@"title"]];
    }

    NSString *otherServicesPlist = [[NSBundle mainBundle] pathForResource:@"Other Services Portlets" ofType:@"plist"];
    NSArray *otherServicesContents = [NSArray arrayWithContentsOfFile:otherServicesPlist];

    [self.sectionContents addObject:otherServicesContents];
    [self.sectionTitles addObject:@"Other Services"];

    [self.tableView reloadData];

    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];

    // Select the first portlet by default on iPad
    if (self.delegate) {
        NSDictionary *portletInfo = self.sectionContents[0][0];
        [self.delegate selectedPortlet:portletInfo];
    }
}

- (void)configureViewWhenPossible {
    if ((self.isViewLoaded && self.view.window) || self.splitViewController) {
        // On-screen; configure the view
        // (UI must be updated on the main queue)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureView];
        });
    } else {
        // Not on-screen; do it in viewWillAppear instead
        self.configureViewNextAppearance = YES;
    }
}

#pragma mark - Miscellaneous

- (void)registerWithNotificationCenter {
    // Reload the table view on successful login
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configureViewWhenPossible)
                                                 name:kLoginSuccessNotification object:nil];

    // Reload the table view on successful logout as well
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configureViewWhenPossible)
                                                 name:kLogoutSuccessNotification object:nil];

    // Fix the UI if a Remember Me login fails
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(rememberMeFailure)
                                                 name:kRememberMeFailureNotification object:nil];

    // Re-enable the Log Out button if logging out fails
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logoutFailure)
                                                 name:kLogoutFailureNotification object:nil];

    // Attempt to reload the table view if the Internet connection was offline, but the user left the app to fix it
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNetworkChanges)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];

    // Check if the view needs configuring when the connection state changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNetworkChanges)
                                                 name: kReachabilityChangedNotification object:nil];
}

- (BOOL)networkIsReachable {
    if ([self.networkReachability currentReachabilityStatus] == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"The Internet connection appears to be offline."
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}

- (void)handleNetworkChanges {
    // If the "logging in" bar button item is found in a navigation bar, it means the Internet connection was
    // offline when starting the app with saved credentials. Continue logging in if the network is now reachable.
    if (!self.splitViewController) {
        if ([self networkIsReachable]) {
            if ([self.navigationItem.rightBarButtonItems containsObject:self.loggingInBarButtonItem]) {
                [[Authenticator sharedAuthenticator] logInWithStoredCredentials];
            } else if ([self.navigationItem.rightBarButtonItems count] == 0) {
                // The app must have started with no Internet connection nor saved credentials; re-configure the view.
                [self configureView];
            }
        }
    } else {
        // The same logic as above but for the PortletViewController
        UINavigationController *portletNavigationController = (UINavigationController *)self.splitViewController.viewControllers[1];
        PortletViewController *portletViewController = [portletNavigationController.childViewControllers firstObject];
        if ([self networkIsReachable]) {
            if ([portletViewController.navigationItem.rightBarButtonItems
                 containsObject:portletViewController.loggingInBarButtonItem]) {
                [[Authenticator sharedAuthenticator] logInWithStoredCredentials];
            } else if ([portletViewController.navigationItem.rightBarButtonItems count] == 0) {
                [self configureView];
            }
        }
    }
}

- (void)rememberMeFailure {
    if (!self.splitViewController) {
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

- (void)logoutFailure {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Your request could not be completed at this time. Please try again."
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [self configureLogOutButton];
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

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger)[self.sectionTitles count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[self.sectionContents[(NSUInteger)section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *text = self.sectionTitles[(NSUInteger)section];
    return [[HeaderView alloc] initWithText:text];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TableCellID";
    TableCell *tableCell = (TableCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    NSDictionary *dict = self.sectionContents[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];

    tableCell.cellTitle.text = dict[@"title"];
    tableCell.cellDescription.text = dict[@"description"];

    // loading image that is saved to phone
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *imageDirectory = paths[0];
    NSString* path = [imageDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", dict[@"thumbnail"]]];
    UIImage* image = [UIImage imageWithContentsOfFile:path];
    if (!image) {
        // Check if it's an Other Services portlet
        image = [UIImage imageNamed:dict[@"thumbnail"]];

        if (!image) {
            // Still no image found; use the default
            image = [UIImage imageNamed:@"Default"];
        }
    }
    [tableCell.cellImage setImage:image];

    return tableCell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Save the indexPath for later, to avoid cells getting stuck with a gray background
    self.mostRecentlySelectedIndexPath = indexPath;

    NSDictionary *portletInfo = self.sectionContents[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];
    if (self.delegate) {
        [self.delegate selectedPortlet:portletInfo];
        PortletViewController *portletViewController = (PortletViewController *)self.delegate;
        if (portletViewController.pc) {
            [portletViewController.pc dismissPopoverAnimated:YES];
        }
    }
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
    [self performSegueWithIdentifier:@"LogInFromMain" sender:self];
}

- (IBAction)showInformation {
    [self performSegueWithIdentifier:@"ShowInformation" sender:nil];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowPortlet"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDictionary *dict = self.sectionContents[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];
        [[segue destinationViewController] setPortletInfo:dict];
    }

}

- (IBAction)unwind:(UIStoryboardSegue *)segue {
    // performed via storyboard
}

@end
