//
//  ViewController.m
//  HHMantleStudy
//
//  Created by hehai on 2019/5/16.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

@interface ViewController ()

/** */
@property (nonatomic, strong) NSObject *obj;
/** */
@property (nonatomic, copy) NSString *name;
/** */
@property (nonatomic, strong) id mingzi;
/** */
@property (nonatomic, assign) NSUInteger age;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self printCurrentPropertyNames:self.class];
    [self printAllPropertyNames:self.class];
    [self printPropertyAttributes];
    
}

// 当前类的属性名
- (void)printCurrentPropertyNames:(Class)cls {
    
    unsigned int outCount = 0;
    objc_property_t *propertys = class_copyPropertyList(cls, &outCount);
    @try {
        for (int i = 0; i < outCount; ++i) {
            objc_property_t property = propertys[i];
            NSLog(@"%@", @(property_getName(property)));
        }
    } @finally {
        free(propertys);
    }
}

// 当前类及父类的属性名
- (void)printAllPropertyNames:(Class)cls {
    
    while (![cls isKindOfClass:[NSObject class]]) {
        unsigned int outCount = 0;
        objc_property_t *propertys = class_copyPropertyList(cls, &outCount);
        cls = cls.superclass;
        @try {
            for (int i = 0; i < outCount; ++i) {
                objc_property_t property = propertys[i];
                NSLog(@"%@", @(property_getName(property)));
            }
        } @finally {
            free(propertys);
        }
    }
}

// 打印 property 的 attributes
- (void)printPropertyAttributes {
    NSLog(@"%@", @(property_getAttributes(class_getProperty(self.class, @"name".UTF8String))));
    NSLog(@"%@", @(property_getAttributes(class_getProperty(self.class, @"mingzi".UTF8String))));
    NSLog(@"%@", @(property_getAttributes(class_getProperty(self.class, @"age".UTF8String))));
    NSLog(@"%@", @(property_getAttributes(class_getProperty(self.class, @"obj".UTF8String))));
}

@end
