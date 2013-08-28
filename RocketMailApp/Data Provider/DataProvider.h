//
//  DataProvider.h
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMMail.h"
#import "AFNetworking.h"

@interface DataProvider : NSObject

+ (DataProvider*) sharedInstance;

- (NSArray*) mailByPage: (int) page withType: (RMMailType) type successBlock:(void (^)(NSMutableArray* emails))success;
- (NSMutableArray*) emailsFromDBWithType: (RMMailType) mailType;

- (void) removeAllEmails;

@end
