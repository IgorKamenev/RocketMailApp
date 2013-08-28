//
//  NSDate+relativeDate.h
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/29/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (relativeDate)

- (NSString*) relativeDate;
+ (NSDate *)parseRFC3339Date:(NSString *)dateString;

@end
