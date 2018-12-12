/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import "NSImage+WebCache.h"
#import <objc/message.h>

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (strong, nonatomic, nullable) SDWebImageDownloadToken *downloadToken;
@property (strong, nonatomic, nullable) NSOperation *cacheOperation;
@property (weak, nonatomic, nullable) SDWebImageManager *manager;

@end

@interface SDWebImageManager ()

@property (strong, nonatomic, readwrite, nonnull) SDImageCache *imageCache;
@property (strong, nonatomic, readwrite, nonnull) SDWebImageDownloader *imageDownloader;
@property (strong, nonatomic, nonnull) NSMutableSet<NSURL *> *failedURLs;
@property (strong, nonatomic, nonnull) dispatch_semaphore_t failedURLsLock; // a lock to keep the access to `failedURLs` thread-safe
@property (strong, nonatomic, nonnull) NSMutableSet<SDWebImageCombinedOperation *> *runningOperations; // SDWebImageCombinedOperation 类的定义在此文件内部
@property (strong, nonatomic, nonnull) dispatch_semaphore_t runningOperationsLock; // a lock to keep the access to `runningOperations` thread-safe

@end

@implementation SDWebImageManager

+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (nonnull instancetype)init {
    SDImageCache *cache = [SDImageCache sharedImageCache];
    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    return [self initWithCache:cache downloader:downloader];
}

- (nonnull instancetype)initWithCache:(nonnull SDImageCache *)cache downloader:(nonnull SDWebImageDownloader *)downloader {
    if ((self = [super init])) {
        _imageCache = cache;
        _imageDownloader = downloader;
        _failedURLs = [NSMutableSet new];
        _failedURLsLock = dispatch_semaphore_create(1);
        _runningOperations = [NSMutableSet new];
        _runningOperationsLock = dispatch_semaphore_create(1);
    }
    return self;
}

- (nullable UIImage *)scaledImageForKey:(nullable NSString *)key image:(nullable UIImage *)image {
    return SDScaledImageForKey(key, image);
}

#pragma mark - *** 查询缓存(异步)，取消了 3.x.x 版本中的2个同步查询方法

// 利用 image 的 url 生成一个缓存时需要的 key，其中 _cacheKeyFilter 是一个自定义 key 生成过则的 block
- (nullable NSString *)cacheKeyForURL:(nullable NSURL *)url {
    if (!url) {
        return @"";
    }
    
    if (self.cacheKeyFilter) {
        return self.cacheKeyFilter(url);
    } else {
        return url.absoluteString;
    }
}

// 查询：内存 + 磁盘（如果内存缓存了，就不再查询磁盘）
- (void)cachedImageExistsForURL:(nullable NSURL *)url
                     completion:(nullable SDWebImageCheckCacheCompletionBlock)completionBlock {
    
    NSString *key = [self cacheKeyForURL:url];
    
    // 1.查 内存缓存
    BOOL isInMemoryCache = ([self.imageCache imageFromMemoryCacheForKey:key] != nil);
    if (isInMemoryCache) {
        // 在主线程执行 completionBlock
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionBlock) {
                completionBlock(YES);
            }
        });
        return;
    }
    
    // 2.查 磁盘缓存
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // 因为 imageCache 的这个方法始终是在主线程调用，所以此处不需要再切回主线程的操作
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

// 查询：仅查询磁盘
- (void)diskImageExistsForURL:(nullable NSURL *)url
                   completion:(nullable SDWebImageCheckCacheCompletionBlock)completionBlock {
    NSString *key = [self cacheKeyForURL:url];
    
    [self.imageCache diskImageExistsWithKey:key completion:^(BOOL isInDiskCache) {
        // 因为 imageCache 的这个方法始终是在主线程调用，所以此处不需要再切回主线程的操作
        if (completionBlock) {
            completionBlock(isInDiskCache);
        }
    }];
}

#pragma mark - *** 核心方法

- (id <SDWebImageOperation>)loadImageWithURL:(nullable NSURL *)url
                                     options:(SDWebImageOptions)options
                                    progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                                   completed:(nullable SDInternalCompletionBlock)completedBlock
{
    // 0.校验参数
    
    // Invoking this method without a completedBlock is pointless
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");

    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, Xcode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }

    // 1.创建 operation (SDWebImageCombinedOperation)
    
    SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    operation.manager = self; // 肯定是 weak 属性

    // 2.再次校验 url
    
    // self.failedURLs 是一个保存曾经失败过的 URL 的数组，用于检测当前 URL 是不是曾经请求失败过的URL.另外，搜索一个个元素的时候，NSSet 比 NSArray 查询更快。
    BOOL isFailedUrl = NO;
    if (url) {
        LOCK(self.failedURLsLock);
        isFailedUrl = [self.failedURLs containsObject:url];
        UNLOCK(self.failedURLsLock);
    }

    // 若出现以下两种情况就不再往下走了，直接执行 CompletionBlock：① URL 是空的；② 此 URL 是曾经请求失败的 URL，并且规定不允许重新请求曾经失败的 URL。
    if (url.absoluteString.length == 0
        || (!(options & SDWebImageRetryFailed) && isFailedUrl))
    {
        [self callCompletionBlockForOperation:operation
                                   completion:completedBlock
                                        error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorFileDoesNotExist userInfo:nil]
                                          url:url];
        return operation;
    }

    // 3.将此 operation 添加至 正在执行的 operation 数组中(这里都改用了信号量)
    
    LOCK(self.runningOperationsLock);
    [self.runningOperations addObject:operation];
    UNLOCK(self.runningOperationsLock);
    
    // *** 4.查询缓存
    
    NSString *key = [self cacheKeyForURL:url];
    
    SDImageCacheOptions cacheOptions = 0;
    
    if (options & SDWebImageQueryDataWhenInMemory) cacheOptions |= SDImageCacheQueryDataWhenInMemory;
    
    if (options & SDWebImageQueryDiskSync) cacheOptions |= SDImageCacheQueryDiskSync;
    
    if (options & SDWebImageScaleDownLargeImages) cacheOptions |= SDImageCacheScaleDownLargeImages;
    
    __weak SDWebImageCombinedOperation *weakOperation = operation;
    
    operation.cacheOperation = [self.imageCache queryCacheOperationForKey:key
                                                                  options:cacheOptions
                                                                     done:^(UIImage *cachedImage, NSData *cachedData, SDImageCacheType cacheType)
    {
        // 这个block是查询磁盘缓存结束后的回调，可能查到了，也可能没查到

        __strong __typeof(weakOperation) strongOperation = weakOperation;
        
        // 1.从 self.runningOperations 这个数组中移除当前 operation
        if (!strongOperation || strongOperation.isCancelled) {
            [self safelyRemoveOperationFromRunning:strongOperation];
            return;
        }
        
       /**
        *  2.判断是否需要从网络下载图片，3 个条件需要同时满足：
        *
        *  a.没有设置 SDWebImageFromCacheOnly，则按照默认操作，即查询不到缓存的时候，从网络获取图片
        *  b.没有缓存 或 设置了需要更新缓存
        *  c.如果代理未实现 “决定是否下载指定图片的代理方法” 或者 该代理方法返回 YES(即决定下载指定图片)
        */

        BOOL shouldDownload = (!(options & SDWebImageFromCacheOnly)) // 没要求必须从缓存取 image 数据
            && (!cachedImage || options & SDWebImageRefreshCached) // 本地无缓存 或 需要更新缓存
        && (![self.delegate respondsToSelector:@selector(imageManager:shouldDownloadImageForURL:)] || [self.delegate imageManager:self shouldDownloadImageForURL:url]); // "imageManager:shouldDownloadImageForURL:": Return NO to prevent the downloading of the image on cache misses. If not implemented, YES is implied.
        
        
        
        if (shouldDownload) {
            
// ****** 若需下载：
            
            if (cachedImage && options & SDWebImageRefreshCached) {
                // If image was found in the cache but SDWebImageRefreshCached is provided, notify about the cached image
                // AND try to re-download it in order to let a chance to NSURLCache to refresh it from server.
                [self callCompletionBlockForOperation:strongOperation completion:completedBlock image:cachedImage data:cachedData error:nil cacheType:cacheType finished:YES url:url];
            }

            // download if no image or requested to refresh anyway, and download allowed by delegate
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            if (options & SDWebImageRefreshCached) downloaderOptions |= SDWebImageDownloaderUseNSURLCache;
            if (options & SDWebImageContinueInBackground) downloaderOptions |= SDWebImageDownloaderContinueInBackground;
            if (options & SDWebImageHandleCookies) downloaderOptions |= SDWebImageDownloaderHandleCookies;
            if (options & SDWebImageAllowInvalidSSLCertificates) downloaderOptions |= SDWebImageDownloaderAllowInvalidSSLCertificates;
            if (options & SDWebImageHighPriority) downloaderOptions |= SDWebImageDownloaderHighPriority;
            if (options & SDWebImageScaleDownLargeImages) downloaderOptions |= SDWebImageDownloaderScaleDownLargeImages;
            
            if (cachedImage && options & SDWebImageRefreshCached) {
                // force progressive off if image already cached but forced refreshing
                downloaderOptions &= ~SDWebImageDownloaderProgressiveDownload;
                // ignore image read from NSURLCache if image if cached but force refreshing
                downloaderOptions |= SDWebImageDownloaderIgnoreCachedResponse;
            }
            
            // ****** 发送请求：
            
            // `SDWebImageCombinedOperation` -> `SDWebImageDownloadToken` -> `downloadOperationCancelToken`, which is a `SDCallbacksDictionary` and retain the completed block below, so we need weak-strong again to avoid retain cycle
            __weak typeof(strongOperation) weakSubOperation = strongOperation;
            strongOperation.downloadToken = [self.imageDownloader downloadImageWithURL:url
                                                                               options:downloaderOptions
                                                                              progress:progressBlock
                                                                             completed:^(UIImage *downloadedImage, NSData *downloadedData, NSError *error, BOOL finished)
            {
                // ********* 请求结束 (^_^) 并不一定成功 (^_^)
                
                __strong typeof(weakSubOperation) strongSubOperation = weakSubOperation;
                if (!strongSubOperation || strongSubOperation.isCancelled) {
                    
                    // 如果 operation 已经被取消，什么都不做。
                    
                    // Do nothing if the operation was cancelled
                    // See #699 for more details
                    // if we would call the completedBlock, there could be a race condition between this block and another completedBlock for the same object, so if this one is called second, we will overwrite the new data
                } else if (error) {
                    
                    // 如果失败：
                    
                    // 1.执行完成回调，传递 error
                    [self callCompletionBlockForOperation:strongSubOperation completion:completedBlock error:error url:url];
                    
                    BOOL shouldBlockFailedURL;
                    // Check whether we should block failed url
                    if ([self.delegate respondsToSelector:@selector(imageManager:shouldBlockFailedURL:withError:)]) {
                        shouldBlockFailedURL = [self.delegate imageManager:self shouldBlockFailedURL:url withError:error];
                    } else {
                        shouldBlockFailedURL = (   error.code != NSURLErrorNotConnectedToInternet
                                                && error.code != NSURLErrorCancelled
                                                && error.code != NSURLErrorTimedOut
                                                && error.code != NSURLErrorInternationalRoamingOff
                                                && error.code != NSURLErrorDataNotAllowed
                                                && error.code != NSURLErrorCannotFindHost
                                                && error.code != NSURLErrorCannotConnectToHost
                                                && error.code != NSURLErrorNetworkConnectionLost);
                    }
                    // 2.将此 URL 加入失败的 URL 数组
                    if (shouldBlockFailedURL) {
                        LOCK(self.failedURLsLock);
                        [self.failedURLs addObject:url];
                        UNLOCK(self.failedURLsLock);
                    }
                    
                } else {
                    
                    // 如果成功
                    
                    // 1.如过设置了失败重发，则需要将此URL从失败的URL数组中移除
                    if ((options & SDWebImageRetryFailed)) {
                        LOCK(self.failedURLsLock);
                        [self.failedURLs removeObject:url];
                        UNLOCK(self.failedURLsLock);
                    }
                    
                    // 是否需要磁盘缓存 --- 存盘时使用
                    BOOL cacheOnDisk = !(options & SDWebImageCacheMemoryOnly);
                    
                    // 2.如果使用户自定义的manager，执行单独的缩放操作
                    if (self != [SDWebImageManager sharedManager]
                        && self.cacheKeyFilter
                        && downloadedImage)
                    {
                        downloadedImage = [self scaledImageForKey:key image:downloadedImage];
                    }


                    if (options & SDWebImageRefreshCached && cachedImage && !downloadedImage) {
                        
                        // 需要更新缓存，但是未下载到图片，且缓存中本来有值的情况下，什么也不做，因为下载之前早已经缓存数据返回了
                        
                    } else if (downloadedImage
                               && (!downloadedImage.images || (options & SDWebImageTransformAnimatedImage)) // 不是动图，或者即使是动图也需要 transform 的时候
                               && [self.delegate respondsToSelector:@selector(imageManager:transformDownloadedImage:withURL:)])
                    {
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                            
                            UIImage *transformedImage = [self.delegate imageManager:self
                                                           transformDownloadedImage:downloadedImage
                                                                            withURL:url];

                            if (transformedImage && finished) {
                                
                                BOOL imageWasTransformed = ![transformedImage isEqual:downloadedImage];
                                NSData *cacheData;
                                // pass nil if the image was transformed, so we can recalculate the data from the image
                                if (self.cacheSerializer) {
                                    cacheData = self.cacheSerializer(transformedImage, (imageWasTransformed ? nil : downloadedData), url);
                                } else {
                                    cacheData = (imageWasTransformed ? nil : downloadedData);
                                }
                                
                                // *** 存盘：注意是存的 imageData
                                [self.imageCache storeImage:transformedImage
                                                  imageData:cacheData
                                                     forKey:key
                                                     toDisk:cacheOnDisk
                                                 completion:nil];
                            }
                            
                            [self callCompletionBlockForOperation:strongSubOperation
                                                       completion:completedBlock
                                                            image:transformedImage
                                                             data:downloadedData
                                                            error:nil
                                                        cacheType:SDImageCacheTypeNone
                                                         finished:finished
                                                              url:url];
                        });
                        
                    } else {
                        
                        if (downloadedImage && finished) {
                            
                            if (self.cacheSerializer) {
                                
                               // 异步存盘
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                    
                                    NSData *cacheData = self.cacheSerializer(downloadedImage, downloadedData, url);
                                    
                                    // *** 存盘：注意是存的 imageData
                                    [self.imageCache storeImage:downloadedImage
                                                      imageData:cacheData
                                                         forKey:key
                                                         toDisk:cacheOnDisk
                                                     completion:nil];
                                });
                            } else {
                                
                                // *** 存盘：注意是存的 imageData
                                [self.imageCache storeImage:downloadedImage
                                                  imageData:downloadedData
                                                     forKey:key
                                                     toDisk:cacheOnDisk
                                                 completion:nil];
                            }
                        }
                        
                        [self callCompletionBlockForOperation:strongSubOperation
                                                   completion:completedBlock
                                                        image:downloadedImage
                                                         data:downloadedData
                                                        error:nil
                                                    cacheType:SDImageCacheTypeNone
                                                     finished:finished
                                                          url:url];
                    }
                }

                if (finished) {
                    [self safelyRemoveOperationFromRunning:strongSubOperation];
                }
                
            }];
            
        } else if (cachedImage) {
            
// *** 如果取到了缓存
            
            [self callCompletionBlockForOperation:strongOperation
                                       completion:completedBlock
                                            image:cachedImage
                                             data:cachedData
                                            error:nil
                                        cacheType:cacheType
                                         finished:YES
                                              url:url];
            
            [self safelyRemoveOperationFromRunning:strongOperation];
            
        } else {
           
// *** 没取到缓存 && 不允许下载
            
            // Image not in cache and download disallowed by delegate
            [self callCompletionBlockForOperation:strongOperation
                                       completion:completedBlock
                                            image:nil
                                             data:nil
                                            error:nil
                                        cacheType:SDImageCacheTypeNone
                                         finished:YES
                                              url:url];
            
            [self safelyRemoveOperationFromRunning:strongOperation];
        }
    }];

    return operation;
}

// 保存图片至磁盘
- (void)saveImageToCache:(nullable UIImage *)image forURL:(nullable NSURL *)url {
    if (image && url) {
        NSString *key = [self cacheKeyForURL:url];
        [self.imageCache storeImage:image forKey:key toDisk:YES completion:nil];
    }
}

// 取消所有操作
- (void)cancelAll {
    LOCK(self.runningOperationsLock);
    NSSet<SDWebImageCombinedOperation *> *copiedOperations = [self.runningOperations copy];
    UNLOCK(self.runningOperationsLock);
    [copiedOperations makeObjectsPerformSelector:@selector(cancel)]; // This will call `safelyRemoveOperationFromRunning:` and remove from the array
}

// 判断是否还有 operation 在运行
- (BOOL)isRunning {
    BOOL isRunning = NO;
    LOCK(self.runningOperationsLock);
    isRunning = (self.runningOperations.count > 0);
    UNLOCK(self.runningOperationsLock);
    return isRunning;
}

// 从 self.runningOperations 中移除 operation，比如下载完成的时候
- (void)safelyRemoveOperationFromRunning:(nullable SDWebImageCombinedOperation*)operation {
    if (!operation) {
        return;
    }
    LOCK(self.runningOperationsLock);
    [self.runningOperations removeObject:operation];
    UNLOCK(self.runningOperationsLock);
}

// 执行完成的回调
- (void)callCompletionBlockForOperation:(nullable SDWebImageCombinedOperation*)operation
                             completion:(nullable SDInternalCompletionBlock)completionBlock
                                  error:(nullable NSError *)error
                                    url:(nullable NSURL *)url {
    [self callCompletionBlockForOperation:operation completion:completionBlock image:nil data:nil error:error cacheType:SDImageCacheTypeNone finished:YES url:url];
}

- (void)callCompletionBlockForOperation:(nullable SDWebImageCombinedOperation*)operation
                             completion:(nullable SDInternalCompletionBlock)completionBlock
                                  image:(nullable UIImage *)image
                                   data:(nullable NSData *)data
                                  error:(nullable NSError *)error
                              cacheType:(SDImageCacheType)cacheType
                               finished:(BOOL)finished
                                    url:(nullable NSURL *)url {
    dispatch_main_async_safe(^{
        if (operation && !operation.isCancelled && completionBlock) {
            completionBlock(image, data, error, cacheType, finished, url);
        }
    });
}

@end

#pragma mark - SDWebImageCombinedOperation 类

@implementation SDWebImageCombinedOperation

- (void)cancel {
    @synchronized(self) {
        self.cancelled = YES;
        if (self.cacheOperation) {
            [self.cacheOperation cancel];
            self.cacheOperation = nil;
        }
        if (self.downloadToken) {
            [self.manager.imageDownloader cancel:self.downloadToken];
        }
        [self.manager safelyRemoveOperationFromRunning:self];
    }
}

@end
