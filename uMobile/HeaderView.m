//
//  HeaderView.m
//  uMobile
//
//  Created by Andrew Clissold on 5/7/14.
//  Copyright (c) 2014 Oakland University. All rights reserved.
//

#import "HeaderView.h"

@implementation HeaderView

- (id)initWithText:(NSString *)text {
    // Find the max length of either portrait or landscape mode
    CGFloat screenWidth, screenHeight;
    screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    screenHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]);
    CGFloat frameWidth = MAX(screenWidth, screenHeight);
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navigationBarHeight = 44.0; // can't call self.navigationController.navigationBar.height before init
    frameWidth += statusBarHeight + navigationBarHeight;
    
    CGRect frame = CGRectMake(0.0, 0.0, frameWidth, 30.0);
    self = [super initWithFrame:frame];
    if (self) {
        CGRect labelFrame = CGRectMake(6.0, 0.0, frameWidth-6.0f, 30.0);
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:22.0];
        label.text = text;

        self.backgroundColor = [UIColor clearColor];

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = self.layer.bounds;

        gradientLayer.colors = [self colorsByLighteningAndDarkeningColor:kPrimaryTintColor];

        [self.layer addSublayer:gradientLayer];
        [self addSubview:label];
    }
    return self;
}

- (NSArray *)colorsByLighteningAndDarkeningColor:(UIColor *)color {
    // Note: this returns a very subtle gradient and will be barely
    // perceptible if the reference color has a brightness of 1.0.
    CGFloat hue, saturation, brightness;
    [kPrimaryTintColor getHue:&hue saturation:&saturation brightness:&brightness alpha:NULL];

    CGFloat delta = 0.06f;
    CGFloat alpha = 0.95f;
    CGFloat brighter = MIN(brightness+delta, 1.0f);
    CGFloat darker = MAX(brightness-delta, 0.0f);
    UIColor *startColor = [UIColor colorWithHue:hue saturation:saturation brightness:brighter alpha:alpha];
    UIColor *endColor = [UIColor colorWithHue:hue saturation:saturation brightness:darker alpha:alpha];

    return @[(id)startColor.CGColor, (id)endColor.CGColor];
}
@end
