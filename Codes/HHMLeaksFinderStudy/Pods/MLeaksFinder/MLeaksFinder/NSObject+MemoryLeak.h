//
//  NSObject+MemoryLeak.h
//  MLeaksFinder
//
//  Created by zeposhe on 12/12/15.
//  Copyright © 2015 zeposhe. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 用于扩展
#define MLCheck(TARGET) [self willReleaseObject:(TARGET) relationship:@#TARGET];

@interface NSObject (MemoryLeak)

- (BOOL)willDealloc;
/// 用于扩展，即 MLCheck(TARGET) 中会用到
- (void)willReleaseObject:(id)object relationship:(NSString *)relationship;

// 用于构造堆栈信息
- (void)willReleaseChild:(id)child;
- (void)willReleaseChildren:(NSArray *)children;

/// 堆栈信息数组，元素是类名
- (NSArray *)viewStack;

/// 添加新类名到白名单
+ (void)addClassNamesToWhitelist:(NSArray *)classNames;

/// 交换方法
+ (void)swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL;

@end
