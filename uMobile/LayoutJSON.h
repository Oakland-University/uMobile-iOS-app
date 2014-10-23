//
//  GrabJSON.h
//  uMobile
//
//  Handles retrieval of the layout.json file used to render the list of portlets. Notice
//  that they are class methods--downloadLayoutJSON will download the file and parse it into
//  an NSDictionary, and getLayoutJSON is a simple accessor for that dictionary, neither of
//  which require instantiation.
//
//  Created by Andrew Clissold & Skye Schneider on 3/21/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LayoutJSON : NSObject
+ (void)downloadLayoutJSON;
+ (NSDictionary *)getLayoutJSON;
@end
