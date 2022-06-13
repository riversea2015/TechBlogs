//
//  HHStaff+CateA.m
//  CategoryDemo
//
//  Created by hehai on 2019/2/11.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "HHStaff+CateA.h"

@implementation HHStaff (CateA)

#pragma mark - 对象方法

- (void)methodA1 {
    NSLog(@"这是 methodA1");
}

- (void)methodA2 {
    NSLog(@"这是 methodA2");
}

#pragma mark - 类方法

+ (void)classMethodA1 {
    NSLog(@"这是 classMethodA1");
}

+ (void)classMethodA2 {
    NSLog(@"这是 classMethodA2");
}

@end
