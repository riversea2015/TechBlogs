
//
//  HHTestModel.m
//  HHMantleStudy
//
//  Created by hehai on 2019/5/17.
//  Copyright © 2019 hehai. All rights reserved.
//

#import "HHTestModel.h"

@implementation HHTestModel

+ (NSValueTransformer *)assigneeJSONTransformer {
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:GHUser.class];
}

@end
