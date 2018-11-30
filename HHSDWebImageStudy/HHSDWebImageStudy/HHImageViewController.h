//
//  HHImageViewController.h
//  HHSDWebImageStudy
//
//  Created by hehai on 2018/7/17.
//  Copyright © 2018 hehai. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, HHImageVCType) {
    HHImageVCTypeA = 0,
    HHImageVCTypeB,
    HHImageVCTypeC
};

@interface HHImageViewController : UIViewController

@property (nonatomic, assign) HHImageVCType type;

@end
