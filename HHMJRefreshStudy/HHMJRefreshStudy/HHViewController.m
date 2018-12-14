//
//  HHViewController.m
//  HHMJRefreshStudy
//
//  Created by hehai on 2018/12/13.
//  Copyright © 2018 hehai. All rights reserved.
//

#import "HHViewController.h"
#import <MJRefresh/MJRefresh.h>

static NSString * const cellID = @"UITableViewCell";

@interface HHViewController ()
<
UITableViewDataSource,
UITableViewDelegate
>

/// 列表
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation HHViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey];
    
    [self.view addSubview:self.tableView];
}



#pragma mark - delegate & dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
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

@end
