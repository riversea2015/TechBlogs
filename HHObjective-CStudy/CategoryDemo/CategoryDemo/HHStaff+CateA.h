//
//  HHStaff+CateA.h
//  CategoryDemo
//
//  Created by hehai on 2019/2/11.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "HHStaff.h"

NS_ASSUME_NONNULL_BEGIN

@interface HHStaff (CateA)
<
NSCopying,
NSCoding
>

/// 姓名
@property (nonatomic, copy) NSString *name;
/// 工号
@property (nonatomic, assign) NSInteger num;

- (void)methodA1;
- (void)methodA2;

+ (void)classMethodA1;
+ (void)classMethodA2;

@end

NS_ASSUME_NONNULL_END
