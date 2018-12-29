//  代码地址: https://github.com/CoderMJLee/MJRefresh
//  代码地址: http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  MJRefreshHeader.h
//  MJRefreshExample
//
//  Created by MJ Lee on 15/3/4.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//  下拉刷新控件:负责监控用户下拉的状态

#import "MJRefreshComponent.h"

@interface MJRefreshHeader : MJRefreshComponent

#pragma mark - 创建 header 的 2 种方式：①block ②target-action

/** 创建 header */
+ (instancetype)headerWithRefreshingBlock:(MJRefreshComponentRefreshingBlock)refreshingBlock;

/** 创建 header */
+ (instancetype)headerWithRefreshingTarget:(id)target refreshingAction:(SEL)action;

#pragma mark -

/** 这个 key 用来存储上一次下拉刷新成功的时间 */
@property (copy, nonatomic) NSString *lastUpdatedTimeKey;

/** 上一次下拉刷新成功的时间 */
@property (strong, nonatomic, readonly) NSDate *lastUpdatedTime;

/** 忽略多少 scrollView 的 contentInset 的 top */
@property (assign, nonatomic) CGFloat ignoredScrollViewContentInsetTop;

@end
