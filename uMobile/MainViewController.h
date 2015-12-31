//
//  MainViewController.h
//  uMobile
//
//  This is the controller for the Main view. This is the entry point for the app.
//
//  If you're new to this codebase, now would be a good time to take a look at the storyboard
//  file--there is an arrow (that can be moved to any other view controller to aid in debugging)
//  indicating that this controller is the entry point. On the storyboard, you can visually see
//  that this app makes use of a Master-Detail design pattern, with MainViewController being the
//  Master view controller and the PortletViewController providing the Detail for any tapped cell
//  (read: portlet).
//
//  When this object is instantiated for the first time, viewDidLoad: gets called. The key
//  effects of this is the downloading and parsing of layout.json, which is used to set up the list
//  of portlets as cells in the table view. The configureView method may be called again to perform
//  this step again, for example when the user logs in.
//
//  Other than configureView, view controller lifecycle methods, and the UITableViewDelegate methods,
//  the only methods left are those that get called when the UI is interacted with. Specifically, any
//  method with a "return value" of IBAction (which is really void) gets called when the corresponding
//  UIView in the storyboard attached to it is interacted with.
//
//  Created by Andrew Clissold & Skye Schneider on 11/20/13.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TableCell.h"

@interface MainViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@end
