//
//  ViewController.m
//  HHAFNetworkingStudy
//
//  Created by hehai on 2018/8/10.
//  Copyright © 2018 hehai. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking/AFNetworking.h>

#define unsplash_ENDPOINT_HOST      @"https://api.unsplash.com/"
#define unsplash_ENDPOINT_POPULAR   @"photos?order_by=popular"
#define unsplash_CONSUMER_KEY_PARAM @"&client_id=3b99a69cee09770a4a0bbb870b437dbda53efb22f6f6de63714b71c4df7c9642"

static NSString * const cellID = @"tableViewCell";

@interface ViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;

@end

@implementation ViewController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSStringFromClass([self class]);
    
    [self.view addSubview:self.tableView];
}

#pragma mark - load data

- (void)startLoadData {
    
    NSString *urlString          = [[unsplash_ENDPOINT_HOST stringByAppendingString:unsplash_ENDPOINT_POPULAR] stringByAppendingString:unsplash_CONSUMER_KEY_PARAM];
    NSUInteger nextPage          = 1;
    NSString *imageSizeParam     = @"&image_size=600";
    NSString *urlAdditions       = [NSString stringWithFormat:@"&page=%lu&per_page=%d%@", (unsigned long)nextPage, 10, imageSizeParam];
    NSString *URLString = [urlString stringByAppendingString:urlAdditions];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLRequest *request        = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request
                                                   uploadProgress:nil
                                                 downloadProgress:nil
                                                completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error)
                                      {
                                          if (error) {
                                              NSLog(@"-----> 失败：%@", error.domain);
                                          } else {
                                              NSLog(@"=====> 成功：%@", responseObject);
                                          }
                                      }];
    [dataTask resume];
}

- (void)loadDataWithGET {
    
    NSString *urlString          = [[unsplash_ENDPOINT_HOST stringByAppendingString:unsplash_ENDPOINT_POPULAR] stringByAppendingString:unsplash_CONSUMER_KEY_PARAM];
    NSUInteger nextPage          = 1;
    NSString *imageSizeParam     = @"&image_size=600";
    NSString *urlAdditions       = [NSString stringWithFormat:@"&page=%lu&per_page=%d%@", (unsigned long)nextPage, 10, imageSizeParam];
    NSString *URLString = [urlString stringByAppendingString:urlAdditions];
    
    [[AFHTTPSessionManager manager] GET:URLString parameters:urlAdditions progress:^(NSProgress * _Nonnull downloadProgress) {
        NSLog(@"=====> 进行中...：%@", downloadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"=====> 成功：%@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"-----> 失败原因：%@", error.domain);
        }
    }];
}

#pragma mark - tableView delegate & datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    if (indexPath.row < self.dataArr.count) {
        cell.textLabel.text = self.dataArr[indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
            [self loadDataWithGET];
            break;
            
        default:
            break;
    }
}

#pragma mark - setter & getter

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [@[@"GET"] mutableCopy];
    }
    return _dataArr;
}

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
