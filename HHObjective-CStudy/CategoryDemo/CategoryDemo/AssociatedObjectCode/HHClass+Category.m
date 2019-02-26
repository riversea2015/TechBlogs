//
//  HHClass+Category.m
//  AssociatedObjectDemo
//
//  Created by hehai on 2019/2/19.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "HHClass+Category.h"
#import <objc/runtime.h>

@interface HHClass (Category)

///
@property (nonatomic, copy) NSString *myName;

@end

static const void * MyNameKey = &MyNameKey;
@implementation HHClass (Category)

- (void)setMyName:(NSString *)myName {
    objc_setAssociatedObject(self, MyNameKey, myName, OBJC_ASSOCIATION_COPY_NONATOMIC);
//    objc_setAssociatedObject(id  _Nonnull object, const void * _Nonnull key, id  _Nullable value, objc_AssociationPolicy policy);
}

- (NSString *)myName {
    return objc_getAssociatedObject(self, MyNameKey);
//    objc_getAssociatedObject(id  _Nonnull object, const void * _Nonnull key);
}

@end
