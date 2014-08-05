//
//  TableCell.h
//  uMobile
//
//  The view for each cell in the Main view's table. This is used as the return value for the
//  UITableViewDelegate tableView:cellForRowAtIndexPath: method to make it easy to customize
//  the table's contents.
//
//  Created by Andrew Clissold & Skye Schneider on 11/20/13.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (weak, nonatomic) IBOutlet UILabel *cellTitle;
@property (weak, nonatomic) IBOutlet UILabel *cellDescription;

@end
