//
//  TableActivityIndicatorView.h
//  uMobile
//
//  A UIView that contains a UIActivityIndicatorView, intended to be displayed over a UITableView
//  before its contents are ready.
//
//  Created by Andrew Clissold on 10/31/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableActivityIndicatorView : UIView

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color;

@end
