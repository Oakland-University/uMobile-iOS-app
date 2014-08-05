//
//  NSString+URLEncoding.m
//  uMobile
//
//  Created by Andrew Clissold on 6/27/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "NSString+URLEncoding.h"

@implementation NSString (URLEncoding)

- (NSString *)stringByAddingURLEscapesUsingEncoding:(NSStringEncoding)encoding {
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (CFStringRef)self,
        NULL,
        (CFStringRef)@"!*'\"();:@&=+$,/?%#[] ",
        CFStringConvertNSStringEncodingToEncoding(encoding)));
}

@end
