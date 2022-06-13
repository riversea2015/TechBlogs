//
//  RSWebImageViewController.m
//  HHWebImageDemo
//
//  Created by hehai on 1/18/16.
//  Copyright © 2016 hehai. All rights reserved.
//

#import "HHWebImageViewController.h"
#import "HHWebImageCell.h"
#import "HHWebImageModel.h"

static NSString * const cellID = @"HHWebImageCell";

@interface HHWebImageViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) HHWebImageModel *imageModel;

@property (nonatomic, strong) NSMutableArray *imageArr;

@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) NSMutableDictionary *imagesDic;

@property (nonatomic, strong) NSString *cachesPath;

@end

@implementation HHWebImageViewController

#pragma mark - Life Cycle

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [self.queue cancelAllOperations];
    [self.imagesDic removeAllObjects];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Pictures";
    
    [self.view addSubview:self.tableView];
    
    [self.imageArr addObjectsFromArray:self.imageModel.pictureArr];
}

#pragma mark - tableView DataSource & Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.imageArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HHWebImageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"第%ld行测试用数据", indexPath.row];
    
    [self setImageForCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [HHWebImageCell cellHeight];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.imageArr removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        // 插入/添加 的逻辑
    }
}

#pragma mark - private method

- (void)setImageForCell:(HHWebImageCell *)cell forIndexPath:(NSIndexPath *)indexPath{
    
    UIImage *image = self.imagesDic[self.imageArr[indexPath.row]];
    if (image) { // 1.如果内存（字典）中有数据，则执行
        cell.titleImageView.image = image;
        NSLog(@"hit memory:%@",self.imageArr[indexPath.row]);
    } else { // 2.如果字典中没有数据，则从磁盘中读
        NSString *filePath = [self.cachesPath stringByAppendingPathComponent:[self.imageArr[indexPath.row] lastPathComponent]];
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (data) { // 3.如果磁盘中有数据，则读取
            cell.titleImageView.image = [UIImage imageWithData:data];
            NSLog(@"hit disk:%@",self.imageArr[indexPath.row]);
        } else { // 4.如果磁盘中没有数据，才开始下载
            cell.titleImageView.image = [UIImage imageNamed:@"placeHolder"];
            // 开始下载
            [self downloadImageForIndexPath:indexPath];
        }
    }
    
}

- (void)downloadImageForIndexPath:(NSIndexPath *)indexPath {
    
    __weak typeof(self) weakSelf = self; // 为避免block中的引用循环
    
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        NSString *str = weakSelf.imageArr[indexPath.row];
        NSURL *url = [NSURL URLWithString:str];
        if (!url) { // 判断URL是否生成
            NSLog(@"url有误，请仔细检查");
            return;
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.timeoutInterval = 20;
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSData *iconData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (iconData.length < 1) { // 判断请求是否发送成功，是否返回了数据
            NSLog(@"下载失败，error:%@", error);
            return;
        }
        
        NSLog(@"下载完毕：%@", weakSelf.imageArr[indexPath.row]);
        
        UIImage *image = [UIImage imageWithData:iconData];
        if (image != nil) { // 判断是否能够解析出数据，image是否为空
            weakSelf.imagesDic[weakSelf.imageArr[indexPath.row]] = image;
        }
        
        NSData *data = UIImagePNGRepresentation(image);
        NSString *filePath = [weakSelf.cachesPath stringByAppendingPathComponent:[weakSelf.imageArr[indexPath.row] lastPathComponent]];
        [data writeToFile:filePath atomically:YES];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // 使用回调方法拿到cell，而不是直接把cell传过来，避免了tableViewCell显示时的乱序，因为cell是可以复用的，而indexPath是唯一的（section_row）
            // 回调方法的调用一定要记清楚，[xxx.tableView cellForRowAtIndexPath:indexPath]
            HHWebImageCell *cell = (HHWebImageCell *)[weakSelf.tableView cellForRowAtIndexPath:indexPath];
            NSLog(@"indexPath:%@", indexPath);
            cell.titleImageView.image = [UIImage imageWithData:iconData];
        }];
    }];
    
    [weakSelf.queue addOperation:operation];
}

#pragma mark - setter and getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        
        [_tableView registerNib:[UINib nibWithNibName:cellID bundle:[NSBundle mainBundle]] forCellReuseIdentifier:cellID];
    }
    return _tableView;
}

- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (NSMutableDictionary *)imagesDic {
    if (!_imagesDic) {
        _imagesDic = [NSMutableDictionary new];
    }
    return _imagesDic;
}

- (NSString *)cachesPath {
    if (!_cachesPath) {
        _cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    }
    return _cachesPath;
}

- (NSMutableArray *)imageArr {
    if (!_imageArr) {
        _imageArr = [[NSMutableArray alloc] init];
    }
    return _imageArr;
}

- (HHWebImageModel *)imageModel {
    if (!_imageModel) {
        _imageModel = [[HHWebImageModel alloc] init];
    }
    return _imageModel;
}

@end
