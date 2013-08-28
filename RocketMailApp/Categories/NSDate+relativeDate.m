//
//  NSDate+relativeDate.m
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/29/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "NSDate+relativeDate.h"

@implementation NSDate (relativeDate)

- (NSString*) relativeDate
{
    
    NSDate* now = [NSDate new];
    
    CGFloat daysFromToday = [now timeIntervalSince1970] - [self timeIntervalSince1970] / 86400;
    
    if (daysFromToday < 1) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm"];
        return [formatter stringFromDate:self];
    }
        
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"d MMM"];
    return [formatter stringFromDate:self];
    
}

+ (NSDate *)parseRFC3339Date:(NSString *)dateString
{
    NSDateFormatter *rfc3339TimestampFormatterWithTimeZone = [[NSDateFormatter alloc] init];
    [rfc3339TimestampFormatterWithTimeZone setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [rfc3339TimestampFormatterWithTimeZone setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
     
    
    NSDate *theDate;
    NSError *error = nil;
    
    if (![rfc3339TimestampFormatterWithTimeZone getObjectValue:&theDate forString:dateString range:nil error:&error]) {
        NSLog(@"Date '%@' could not be parsed: %@", dateString, error);
    }
    
    return theDate;
}


@end
