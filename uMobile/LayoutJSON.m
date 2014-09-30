//
//  GrabJSON.m
//  uMobile
//
//  Created by Andrew Clissold & Skye Schneider on 3/21/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "LayoutJSON.h"

@implementation LayoutJSON

static NSDictionary *dictJSON;

+ (NSDictionary *)getLayoutJSON {
    return dictJSON;
}

+ (void)downloadLayoutJSON {
    // Get the JSON feed to dynamically build the list of portlets
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kBaseURL, kLayoutPath]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
    NSError *error;
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    if (error) {
        // Internet connection offline?
        NSLog(@"Error getting response: %@", [error localizedDescription]);
        // TODO: Replace the table view with a nice "Internet Connection Offline" image rather than using an alert
    }
    else if (response) {
        dictJSON = [NSJSONSerialization JSONObjectWithData:response options:0 error:&error];
        if (error) {
            NSLog(@"JSON parse error: %@", [error localizedDescription]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"An Error Has Occurred"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        [self downloadImagesIfNeeded];
    }
}

+ (void)downloadImagesIfNeeded {
    NSDictionary *layout = dictJSON[@"layout"];
    NSArray *folders = (NSArray *) layout[@"folders"];

    for (NSDictionary *folder in folders) {
        NSArray *portlets = folder[@"portlets"];
        for (NSDictionary *portlet in portlets) {
            NSString *thumbnailName = [NSString stringWithFormat:@"%@", portlet[@"fname"]];
            NSString *iconUrl = [NSString stringWithFormat:@"%@%@", kBaseURL, portlet[@"iconUrl"]];

            NSURL *headerUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", iconUrl]];
            NSURLRequest *request = [NSURLRequest requestWithURL: headerUrl];
            NSHTTPURLResponse *response;
            [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: nil];
            NSString *etag;
            if ([response respondsToSelector:@selector(allHeaderFields)]) {
                NSDictionary *dictionary = [response allHeaderFields];
                etag = dictionary[@"Etag"];
            }

            // Get filepath of image on device
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [paths[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", thumbnailName]];
            NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];

            // Getting the modified date of image
            NSDate *date = [attributes fileModificationDate];
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            NSInteger intDate = (NSInteger)timeInterval;

            if (etag) {
                NSRange range = [etag rangeOfString:@"-"];
                etag = [etag substringFromIndex:range.location + 1];
                etag = [etag substringToIndex:etag.length - 4];
            }
            NSInteger etagInt = [etag integerValue];

            if(!intDate || etagInt > intDate) {

                // Download image from server
                UIImage * image;
                NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:iconUrl]];
                image = [UIImage imageWithData:data];

                // Save image
                [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
            }
        }
    }
}

@end
