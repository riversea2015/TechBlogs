//
//  NSDictionary+MTLJSONKeyPath.m
//  Mantle
//
//  Created by Robert Böhnke on 19/03/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "NSDictionary+MTLJSONKeyPath.h"

#import "MTLJSONAdapter.h"

@implementation NSDictionary (MTLJSONKeyPath)

// 比如, 对应 json 的 keyPath 是 person.name.first, 先分解成 person,name,first, 然后一层一层的获取 json[person][name][first],
// 只不过 Mantle 在解析的时候，用了个for循环，来给用户反馈，到底错误在哪里。

- (id)mtl_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error {
	NSArray *components = [JSONKeyPath componentsSeparatedByString:@"."];

	id result = self;
	for (NSString *component in components) {
		// Check the result before resolving the key path component to not
		// affect the last value of the path.
		if (result == nil || result == NSNull.null) break;

		if (![result isKindOfClass:NSDictionary.class]) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON dictionary", @""),
					NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"JSON key path %1$@ could not resolved because an incompatible JSON dictionary was supplied: \"%2$@\"", @""), JSONKeyPath, self]
				};

				*error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
			}

			if (success != NULL) *success = NO;

			return nil;
		}

		result = result[component]; // 注意：此处是在 NSDictionary 的分类里边，所以 self 是 Dictionary！
	}

	if (success != NULL) *success = YES;

	return result;
}

@end
