//
//  MLeakedObjectProxy.m
//  MLeaksFinder
//
//  Created by 佘泽坡 on 7/15/16.
//  Copyright © 2016 zeposhe. All rights reserved.
//

#import "MLeakedObjectProxy.h"
#import "MLeaksFinder.h"
#import "MLeaksMessenger.h"
#import "NSObject+MemoryLeak.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#if _INTERNAL_MLF_RC_ENABLED
#import <FBRetainCycleDetector/FBRetainCycleDetector.h>
#endif

static NSMutableSet *leakedObjectPtrs;

@interface MLeakedObjectProxy ()<UIAlertViewDelegate>
@property (nonatomic, weak) id object;
@property (nonatomic, strong) NSNumber *objectPtr;
@property (nonatomic, strong) NSArray *viewStack;
@end

@implementation MLeakedObjectProxy

+ (BOOL)isAnyObjectLeakedAtPtrs:(NSSet *)ptrs {
    NSAssert([NSThread isMainThread], @"Must be in main thread.");
    
    // leakedObjectPtrs 是一个单例，用来存储发生内泄的对象地址(已经转成了数值，即 uintptr_t)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        leakedObjectPtrs = [[NSMutableSet alloc] init];
    });
    
    if (!ptrs.count) {
        return NO;
    }
    
    // 当 leakedObjectPtrs 中 至少有一个对象也出现在 ptrs 中时，返回 YES。
    // YES if at least one object in the receiving set is also present in otherSet, otherwise NO.
    if ([leakedObjectPtrs intersectsSet:ptrs]) {
        return YES;
    } else {
        return NO;
    }
}

+ (void)addLeakedObject:(id)object {
    NSAssert([NSThread isMainThread], @"Must be in main thread.");
    
    MLeakedObjectProxy *proxy = [[MLeakedObjectProxy alloc] init];
    proxy.object = object;
    proxy.objectPtr = @((uintptr_t)object);
    proxy.viewStack = [object viewStack];
    
    // 1.给每一个 object 关联一个代理即proxy
    static const void *const kLeakedObjectProxyKey = &kLeakedObjectProxyKey;
    objc_setAssociatedObject(object, kLeakedObjectProxyKey, proxy, OBJC_ASSOCIATION_RETAIN);
    
    // 2.存储 proxy.objectPtr 到集合 leakedObjectPtrs 里边
    [leakedObjectPtrs addObject:proxy.objectPtr];
    
    // 3.弹框：若 _INTERNAL_MLF_RC_ENABLED == 1，则弹框增加检测循环引用的选项；否则只是展示堆栈信息
#if _INTERNAL_MLF_RC_ENABLED
    [MLeaksMessenger alertWithTitle:@"Memory Leak"
                            message:[NSString stringWithFormat:@"%@", proxy.viewStack]
                           delegate:proxy
              additionalButtonTitle:@"Retain Cycle"];
#else
    [MLeaksMessenger alertWithTitle:@"Memory Leak"
                            message:[NSString stringWithFormat:@"%@", proxy.viewStack]];
#endif
}

- (void)dealloc {
    NSNumber *objectPtr = _objectPtr;
    NSArray *viewStack = _viewStack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [leakedObjectPtrs removeObject:objectPtr];
        [MLeaksMessenger alertWithTitle:@"Object Deallocated"
                                message:[NSString stringWithFormat:@"%@", viewStack]];
    });
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!buttonIndex) {
        return;
    }
    
    id object = self.object;
    if (!object) {
        return;
    }
    
#if _INTERNAL_MLF_RC_ENABLED
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        FBRetainCycleDetector *detector = [FBRetainCycleDetector new];
        [detector addCandidate:self.object];
        NSSet *retainCycles = [detector findRetainCyclesWithMaxCycleLength:20];
        
        BOOL hasFound = NO;
        for (NSArray *retainCycle in retainCycles) {
            NSInteger index = 0;
            for (FBObjectiveCGraphElement *element in retainCycle) {
                if (element.object == object) {
                    NSArray *shiftedRetainCycle = [self shiftArray:retainCycle toIndex:index];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MLeaksMessenger alertWithTitle:@"Retain Cycle"
                                                message:[NSString stringWithFormat:@"%@", shiftedRetainCycle]];
                    });
                    hasFound = YES;
                    break;
                }
                
                ++index;
            }
            if (hasFound) {
                break;
            }
        }
        if (!hasFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MLeaksMessenger alertWithTitle:@"Retain Cycle"
                                        message:@"Fail to find a retain cycle"];
            });
        }
    });
#endif
}

- (NSArray *)shiftArray:(NSArray *)array toIndex:(NSInteger)index {
    if (index == 0) {
        return array;
    }
    
    NSRange range = NSMakeRange(index, array.count - index);
    NSMutableArray *result = [[array subarrayWithRange:range] mutableCopy];
    [result addObjectsFromArray:[array subarrayWithRange:NSMakeRange(0, index)]];
    return result;
}

@end
