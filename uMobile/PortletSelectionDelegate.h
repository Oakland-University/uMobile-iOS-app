//
//  PortletSelectionDelegate.h
//  uMobile
//
//  Created by Andrew Clissold on 7/2/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PortletSelectionDelegate <NSObject>
@required
- (void)selectedPortlet:(NSDictionary *)portletInfo;
@end
