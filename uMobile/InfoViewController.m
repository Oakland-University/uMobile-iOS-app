//
//  InfoViewController.m
//  uMobile
//
//  Created by Andrew Clissold on 5/9/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [self.doneButton setTitleColor:kPrimaryTintColor forState:UIControlStateNormal];
    [self.doneButton setTitleColor:kPrimaryTintColor forState:UIControlStateSelected];
    self.view.backgroundColor = kSecondaryTintColor;
}

- (IBAction)dismiss:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
