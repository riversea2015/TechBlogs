//
//  HHWebImageModel.m
//  HHWebImageDemo
//
//  Created by hehai on 1/18/16.
//  Copyright © 2016 hehai. All rights reserved.
//

#import "HHWebImageModel.h"

@implementation HHWebImageModel

- (NSArray *)pictureArr {
    if (!_pictureArr) {
        _pictureArr = @[@"http://www.egouz.com/uploadfile/2016/0104/20160104020229346.jpg",
                        @"http://www.egouz.com/uploadfile/2016/0104/20160104020242565.jpg",
                        @"http://www.egouz.com/uploadfile/2016/0104/20160104020254928.jpg",
                        @"http://www.egouz.com/uploadfile/2016/0104/20160104020305455.jpg",
                        @"http://www.egouz.com/uploadfile/2016/0104/20160104020314852.jpg",
                        @"http://www.egouz.com/uploadfile/2016/0104/20160104020327516.jpg",
                        @"http://www.egouz.com/uploadfile/2016/0104/20160104020337264.jpg",
                        @"http://www.egouz.com/uploadfile/2016/0104/20160104020347745.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041052930.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041105600.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041119939.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041133265.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041145782.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041159303.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041213219.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041225165.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041237635.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041249762.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041301663.jpg",
                        @"http://www.egouz.com/uploadfile/2013/1224/20131224041312183.jpg"
                        ];
    }
    return _pictureArr;
}

@end
