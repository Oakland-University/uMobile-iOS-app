//
//  PortletViewController.h
//  uMobile
//
//  Contains not much more than a UIWebView that loads the mobile view of a portlet.
//
//  The information needed to populate this view's contents are stored in an NSDictionary
//  that gets created in MainViewController's prepareForSegue: method.
//
//  In addition to a UIWebView, the interface also contains a UIProgressView at the top
//  and a UIToolbar with forward, back, stop, and reload buttons at the bottom.
//
//  The CGFloat offset properties and the scrollingDown bool are all used in conjunction
//  with the UIScrollViewDelegate methods to animate the hiding and showing of the bottom
//  toolbar.
//
//  As for the UIWebViewDelegate, webViewDidStartLoad: and webView:didFailLoadWithError:
//  are simply used to hide and show a network indicator in the status bar, and show the
//  UIProgressView on iOS 7, respectively. (There's also some set-up code for
//  the UIProgressView in viewDidLoad.)
//
//  Created by Andrew Clissold & Skye Schneider on 11/20/13.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NJKWebViewProgress.h"
#import "PortletSelectionDelegate.h"

@interface PortletViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, UISplitViewControllerDelegate, PortletSelectionDelegate>

@property (nonatomic, strong) NSDictionary *portletInfo;
@property (nonatomic, strong) UIBarButtonItem *loggingInBarButtonItem;
@property (nonatomic, strong) UIPopoverController *pc;

- (void)configureLogInButton;
- (void)configureLogOutButton;

@end
