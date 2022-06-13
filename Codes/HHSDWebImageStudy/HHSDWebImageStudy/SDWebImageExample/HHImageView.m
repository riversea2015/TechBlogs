//
//  HHImageView.m
//  HHSDWebImageStudy
//
//  Created by hehai on 2018/10/23.
//  Copyright © 2018 hehai. All rights reserved.
//

#import "HHImageView.h"
#import <SDWebImage/SDWebImageCodersManager.h>
#import <SDWebImage/SDWebImageGIFCoder.h>

@implementation HHImageView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [[SDWebImageCodersManager sharedInstance] addCoder:[SDWebImageGIFCoder sharedCoder]];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[SDWebImageCodersManager sharedInstance] addCoder:[SDWebImageGIFCoder sharedCoder]];
    }
    return self;
}

@end
