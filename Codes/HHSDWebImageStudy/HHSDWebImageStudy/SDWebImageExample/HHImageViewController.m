//
//  HHImageViewController.m
//  HHSDWebImageStudy
//
//  Created by hehai on 2018/7/17.
//  Copyright © 2018 hehai. All rights reserved.
//

#import "HHImageViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
// loading 动画
#import <SDWebImage/UIView+WebCache.h>
// 第一种方法使用
#import <SDWebImage/FLAnimatedImageView+WebCache.h>
// 第二种方法使用
#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/UIImage+WebP.h>
#import <SDWebImage/NSData+ImageContentType.h>
// 第三种方法使用
#import "HHImageView.h"

#define kScreenW [UIScreen mainScreen].bounds.size.width

#define URL_Normal          [NSURL URLWithString:@"https://img.zcool.cn/community/01c81558a2723ca801219c77a1e34e.jpg"]
#define URL_WebP_Normal     [NSURL URLWithString:@"http://img13.360buyimg.com/da/jfs/t3235/166/1498646940/160921/956b798f/57ce3564N8f9b9fb5.jpg.webp"]
#define URL_WebP_Dynamic    [NSURL URLWithString:@"https://raw.githubusercontent.com/qq2225936589/ImageDemos/master/demo01.webp"]
#define URL_GIF             [NSURL URLWithString:@"https://f.sinaimg.cn/tech/transform/551/w315h236/20181022/qZm6-hmuuiyv6918494.gif"]

@interface HHImageViewController ()

/// 用于展示兼容图片的 imageView
@property (nonatomic, strong) UIImageView *imgView;

@end

@implementation HHImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSStringFromClass([self class]);
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)setType:(HHImageVCType)type {
    
    _type = type;
    
    switch (type) {
        case HHImageVCTypeA:
            [self methodA];
            break;
        case HHImageVCTypeB:
            [self methodB];
            break;
        case HHImageVCTypeC:
            [self methodC];
            break;
        default:
            break;
    }
}

- (void)methodA {
    
    // 普通静态图
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:CGRectMake(125, 70, 160, 160)];
    imgV.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:imgV];
    [imgV sd_setShowActivityIndicatorView:YES]; // 设置显示加载的小菊花🌺
    [imgV sd_setImageWithURL:URL_Normal];
    
    // WebP
    UIImageView *imgVB = [[UIImageView alloc] initWithFrame:CGRectMake(125, 70+160+10, 160, 160)];
    imgVB.backgroundColor = [UIColor lightGrayColor];
    imgVB.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:imgVB];
    [imgVB sd_setShowActivityIndicatorView:YES];
    // WebP 静态图
//    [imgVB sd_setImageWithURL:URL_WebP_Normal];
    // WebP 动态图
    [imgVB sd_setImageWithURL:URL_WebP_Dynamic];
    
    // GIF - SDWebImage4.0 以后，如果继续使用 UIImageView 将只展示 gif 的第一帧，可以使用推荐的 FLAnimatedImageView 替换 UIImageView
    FLAnimatedImageView *imgView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(125, 70+160+10+160+10, 160, 200)];
    imgView.backgroundColor = [UIColor lightGrayColor];
    imgView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:imgView];
    [imgView sd_setShowActivityIndicatorView:YES];
    [imgView sd_setImageWithURL:URL_GIF
               placeholderImage:[UIImage imageNamed:@"placeholder"]
                        options:1];
}

- (void)methodB {
    
    UIImageView *gifView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 70+160+10, kScreenW-20, 200)];
    gifView.backgroundColor = [UIColor lightGrayColor];
    gifView.contentMode = UIViewContentModeScaleAspectFit;
    [gifView sd_setShowActivityIndicatorView:YES];
    [self.view addSubview:gifView];
    self.imgView = gifView;
    
    SDWebImageManager *mgr = [SDWebImageManager sharedManager];
    __weak typeof(self) weakSelf = self;
    [mgr loadImageWithURL:URL_GIF
                  options:1
                 progress:nil
                completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL)
     {
         if (!data) {
             weakSelf.imgView.image = image;
             return;
         }

         SDImageFormat format = [NSData sd_imageFormatForImageData:data];
         switch (format) {
             case SDImageFormatGIF:
                 weakSelf.imgView.image = [UIImage sd_animatedGIFWithData:data];
                 break;
             case SDImageFormatWebP:
                 weakSelf.imgView.image = [UIImage sd_imageWithWebPData:data];
                 break;
             case SDImageFormatPNG:
             case SDImageFormatJPEG:
                 weakSelf.imgView.image = image;
                 break;
             default:
                 break;
         }
     }];
}

- (void)methodC {
    
    // 自定义 ImageView，重写 init 方法时，为 SDWebImageCodersManager 添加 SDWebImageGIFCoder
    HHImageView *customView = [[HHImageView alloc] initWithFrame:CGRectMake(10, 70+160+10, kScreenW-20, 200)];
    customView.backgroundColor = [UIColor lightGrayColor];
    customView.contentMode = UIViewContentModeScaleAspectFit;
    [customView sd_setShowActivityIndicatorView:YES];
    [self.view addSubview:customView];
    
    // 静态图
    //    [customView sd_setImageWithURL:URL_Normal];
    // WebP 动图
    //    [customView sd_setImageWithURL:URL_WebP_Dynamic];
    // WebP 静态图
    //    [customView sd_setImageWithURL:URL_WebP_Normal];
    // GIF
        [customView sd_setImageWithURL:URL_GIF];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // iOS7的话需要释放一下内存😎
}

@end

/** 补充 **/

/**
 * iOS展示gif图的原理：
 * 1.将gif图的每一帧导出为一个UIImage，将所有导出的UIImage放置到一个数组
 * 2.用上面的数组作为构造参数，使用animatedImage开头的方法创建UIImage，此时创建的UIImage的images属性值就是刚才的数组，duration值是它的一次播放时长。
 * 3.将UIImageView的image设置为上面的UIImage时，gif图会自动显示出来。(也就是说关键是那个数组，用尺寸相同的图片创建UIImage组成数组也是可以的)
 */

/**
 * iOS展示WebP的原理：
 * 需要利用WebP的解析库libwebp完成WebP图片的二进制数据转为UIImage的工作
 * libwebp需要翻墙下载，因为是Google的😓
 * SDWebImage 里边已经添加了相关方法，所以 pod install 之后，按照静态图的方式加载就行
 */
