//
//  NSObject+MemoryLeak.m
//  MLeaksFinder
//
//  Created by zeposhe on 12/12/15.
//  Copyright © 2015 zeposhe. All rights reserved.
//

#import "NSObject+MemoryLeak.h"
#import "MLeakedObjectProxy.h"
#import "MLeaksFinder.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#if _INTERNAL_MLF_RC_ENABLED
#import <FBRetainCycleDetector/FBRetainCycleDetector.h>
#endif

static const void *const kViewStackKey = &kViewStackKey;
static const void *const kParentPtrsKey = &kParentPtrsKey;
const void *const kLatestSenderKey = &kLatestSenderKey;

@implementation NSObject (MemoryLeak)

- (BOOL)willDealloc {
    
    // 检测白名单：检测当前对象是否在白名单中
    NSString *className = NSStringFromClass([self class]);
    if ([[NSObject classNamesWhitelist] containsObject:className])
        return NO;
    
    // fix bug : storyboard 中按钮返回事件的处理，详见 issue - 16
    NSNumber *senderPtr = objc_getAssociatedObject([UIApplication sharedApplication], kLatestSenderKey);
    if ([senderPtr isEqualToNumber:@((uintptr_t)self)])
        return NO;
    
    // *** 核心1：用弱引用 weakSelf 指向 self，延迟两秒执行 weakSelf 的 assertNotDealloc 方法，这个方法如果能够执行，则说明当前对象泄露了
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong id strongSelf = weakSelf;
        [strongSelf assertNotDealloc];
    });
    
    return YES;
}

- (void)assertNotDealloc {
    
    // 判断当前对象是否有父对象没有被释放，如果有就不往下执行了，否则把自己加进去，并打印堆栈信息
    // 另外，因为父对象的 willDealloc 会先执行，所以如果父对象真的会销毁，那么应该也是先销毁，即先从 MLeakedObjectProxy 中移除
    // 加这个判断之后，就不会重复打印，保证打印的堆栈最底下是没有释放的对象，前边的即父对象都是已经释放了的
    if ([MLeakedObjectProxy isAnyObjectLeakedAtPtrs:[self parentPtrs]]) {
        return;
    }
    [MLeakedObjectProxy addLeakedObject:self];
    
    // *** 核心2：打印堆栈信息（打印 viewStack 这个数组）
    NSString *className = NSStringFromClass([self class]);
    NSLog(@"Possibly Memory Leak.\nIn case that %@ should not be dealloced, override -willDealloc in %@ by returning NO.\nView-ViewController stack: %@", className, className, [self viewStack]);
}

#pragma mark - 用于扩展

- (void)willReleaseObject:(id)object relationship:(NSString *)relationship {
    if ([relationship hasPrefix:@"self"]) {
        relationship = [relationship stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@""];
    }
    NSString *className = NSStringFromClass([object class]);
    className = [NSString stringWithFormat:@"%@(%@), ", relationship, className];
    
    [object setViewStack:[[self viewStack] arrayByAddingObject:className]];
    [object setParentPtrs:[[self parentPtrs] setByAddingObject:@((uintptr_t)object)]];
    [object willDealloc];
}

#pragma mark - 构建堆栈

- (void)willReleaseChild:(id)child {
    if (!child) {
        return;
    }
    
    [self willReleaseChildren:@[ child ]];
}

- (void)willReleaseChildren:(NSArray *)children {
    NSArray *viewStack = [self viewStack];
    NSSet *parentPtrs = [self parentPtrs];
    for (id child in children) {
        NSString *className = NSStringFromClass([child class]);
        [child setViewStack:[viewStack arrayByAddingObject:className]];
        [child setParentPtrs:[parentPtrs setByAddingObject:@((uintptr_t)child)]];
        [child willDealloc];
    }
}

#pragma mark - viewStack

// 这是一个数组，如果取不到，就构造一个只有"自己的类名"这一个元素的数组，并返回
- (NSArray *)viewStack {
    NSArray *viewStack = objc_getAssociatedObject(self, kViewStackKey);
    if (viewStack) {
        return viewStack;
    }
    
    NSString *className = NSStringFromClass([self class]);
    return @[ className ];
}

- (void)setViewStack:(NSArray *)viewStack {
    objc_setAssociatedObject(self, kViewStackKey, viewStack, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - parentPtrs

// 在64位的机器上，intptr_t和uintptr_t分别是long int、unsigned long int的别名；
// 在32位的机器上，intptr_t和uintptr_t分别是int、unsigned int的别名
- (NSSet *)parentPtrs {
    NSSet *parentPtrs = objc_getAssociatedObject(self, kParentPtrsKey);
    if (!parentPtrs) {
        parentPtrs = [[NSSet alloc] initWithObjects:@((uintptr_t)self), nil];
    }
    return parentPtrs;
}

- (void)setParentPtrs:(NSSet *)parentPtrs {
    objc_setAssociatedObject(self, kParentPtrsKey, parentPtrs, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - 白名单

+ (NSMutableSet *)classNamesWhitelist {
    static NSMutableSet *whitelist = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whitelist = [NSMutableSet setWithObjects:
                     @"UIFieldEditor", // UIAlertControllerTextField
                     @"UINavigationBar",
                     @"_UIAlertControllerActionView",
                     @"_UIVisualEffectBackdropView",
                     nil];
        
        // System's bug since iOS 10 and not fixed yet up to this ci.
        NSString *systemVersion = [UIDevice currentDevice].systemVersion;
        if ([systemVersion compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending) {
            [whitelist addObject:@"UISwitch"];
        }
    });
    return whitelist;
}

+ (void)addClassNamesToWhitelist:(NSArray *)classNames {
    [[self classNamesWhitelist] addObjectsFromArray:classNames];
}

#pragma mark - 公用的交换方法

// 因为是单独抽出来的一个交换方法，对于传进来的 originalSEL 我们确实不知道 class 中是否有这个方法，所以才会有了下边比较严谨的判断方法：
// 如果返回 YES，说明添加成功，也就是说，class 里边原来 没有叫 originalSEL 的方法，加了以后，那里比那就是 我们希望的交换的方法实现，那么，接下来，就只需要将 swizzledSEL 方法的实现替换成原方法的实现，即实现了所谓的交换；否则的话，直接交换
+ (void)swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL {
#if _INTERNAL_MLF_ENABLED
    
#if _INTERNAL_MLF_RC_ENABLED
    // Just find a place to set up FBRetainCycleDetector.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [FBAssociationManager hook];
        });
    });
#endif
    
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSEL);
    
    // YES if the method was added successfully, otherwise NO (for example, the class already contains a method implementation with that name).
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
#endif
}

@end
