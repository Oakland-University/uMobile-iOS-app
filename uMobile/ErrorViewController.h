//
//  ErrorViewController.h
//  uMobile
//
//  Shown when the umobile-global-config checker (the Config class) encounters a fatal error.
//
//  This will render the app unusable, so it should only ever be shown if an upgrade is
//  required or the global config JSON feed could not be acquired (the app isn't functional
//  if there's no Internet connection anyway).
//
//  Created by Andrew Clissold on 10/8/14.
//  Copyright (c) 2014 uMobile. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ErrorViewController : UIViewController

@end
