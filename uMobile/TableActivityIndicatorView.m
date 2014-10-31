//
//  TableActivityIndicatorView.m
//  uMobile
//
//  Created by Andrew Clissold on 10/31/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "TableActivityIndicatorView.h"

@implementation TableActivityIndicatorView

- (instancetype)initWithFrame:(CGRect)frame color:(UIColor *)color {
    self = [super initWithFrame:frame];
    if (self) {
        UIActivityIndicatorView *activityIndicatorView =
        [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicatorView.center = self.center;
        activityIndicatorView.color = color;
        [activityIndicatorView startAnimating];

        [self addSubview:activityIndicatorView];
    }
    return self;
}

@end
