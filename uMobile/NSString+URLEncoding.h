//
//  NSString+URLEncoding.h
//  uMobile
//
//  Created by Andrew Clissold on 6/27/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncoding)

- (NSString *)stringByAddingURLEscapesUsingEncoding:(NSStringEncoding)encoding;

@end
