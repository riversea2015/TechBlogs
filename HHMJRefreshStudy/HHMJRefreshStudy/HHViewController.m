//
//  HHViewController.m
//  HHMJRefreshStudy
//
//  Created by hehai on 2018/12/13.
//  Copyright © 2018 hehai. All rights reserved.
//

#import "HHViewController.h"
#import <MJRefresh/MJRefresh.h>
#import "MJChiBaoZiHeader.h"
#import "MJChiBaoZiFooter.h"

static NSString * const cellID = @"UITableViewCell";
static const NSTimeInterval HHDelayTime = 2.0;

@interface HHViewController ()
<
UITableViewDataSource,
UITableViewDelegate
>

/// 列表
@property (nonatomic, strong) UITableView *tableView;
/// 数据源
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation HHViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey];
    [self.view addSubview:self.tableView];
    
    [self exampleA];
    [self exampleB];
}

#pragma mark - Example A

- (void)exampleA
{
    // 1.设置 header
    self.tableView.mj_header = [MJChiBaoZiHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
    // 2.马上进入刷新状态
    [self.tableView.mj_header beginRefreshing];
}

- (void)loadNewData {
    // 3.下载数据的操作
    __weak typeof(self) weakSelf = self;
    [self requestNetDataWithCompletionBlock:^(NSArray *result, BOOL isSuccess) {
        // * 处理数据
        [weakSelf.dataArray removeAllObjects];
        [weakSelf.dataArray addObjectsFromArray:result];
        // 4.刷新表格，并结束刷新状态
        [weakSelf.tableView reloadData];
        // 5.拿到当前的下拉刷新控件，
        [weakSelf.tableView.mj_header endRefreshing];
    }];
}

#pragma mark - Example B

- (void)exampleB
{
    // 1.设置 footer
    self.tableView.mj_footer = [MJChiBaoZiFooter footerWithRefreshingTarget:self
                                                           refreshingAction:@selector(loadMoreData)];
}

- (void)loadMoreData {
    // 2.下载数据的操作
    __weak typeof(self) weakSelf = self;
    [self requestNetDataWithCompletionBlock:^(NSArray *result, BOOL isSuccess) {
        // * 将返回数据追加到表格的数据源
        [weakSelf.dataArray addObjectsFromArray:result];
        // 3.刷新表格，并结束刷新状态
        [weakSelf.tableView reloadData];
        // 4.拿到当前的上拉加载更多控件，
        [weakSelf.tableView.mj_footer endRefreshing];
    }];
}

#pragma mark - Request

- (void)requestNetDataWithCompletionBlock:(void (^)(NSArray *result, BOOL isSuccess))compltionBlock {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HHDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSArray *array = @[@"测试", @"测试", @"测试", @"测试", @"测试", @"测试", @"测试", @"测试", @"测试", @"测试"];
        if (compltionBlock) {
            compltionBlock(array, YES);
        }
    });
}
     
#pragma mark - dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    cell.backgroundColor = indexPath.row % 2 ? [UIColor orangeColor] : [UIColor greenColor];
    cell.textLabel.text = [NSString stringWithFormat:@"NO.%ld", indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

#pragma mark - delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"点击了第 %ld 行", indexPath.row);
}

#pragma mark - setter & getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:cellID];
    }
    
    return _tableView;
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

@end
