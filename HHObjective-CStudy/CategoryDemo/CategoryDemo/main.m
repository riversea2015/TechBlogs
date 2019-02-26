//
//  main.m
//  CategoryDemo
//
//  Created by hehai on 2019/2/11.
//  Copyright © 2019 hehai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HHStaff+CateA.h"
#import "HHStaff+CateB.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        HHStaff *staff = [[HHStaff alloc] init];
        [staff methodA1];
        [staff methodB1];
        
    }
    return 0;
}
