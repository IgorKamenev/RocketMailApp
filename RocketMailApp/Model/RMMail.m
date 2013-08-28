//
//  RMMail.m
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "RMMail.h"

@implementation RMMail

+(void)load
{
    [RMMail createTableIfNotExists];
}

+ (NSArray*) uniqueFields
{
    return @[@"ID"];
}

+ (NSString*) tableName {
    return @"RMMail";
}

+ (RMMail*) mailByDict: (NSDictionary*) dict
{
    
    RMMail* mail = [RMMail findOneByFieldName:@"ID" equalTo:dict[@"id"]];
    
    if (!mail) {
        mail = [RMMail new];
        mail.ID = [dict[@"id"] intValue];
    }
    
    mail.from = dict[@"from"];
    mail.to = dict[@"to"];
    mail.subject = dict[@"subject"];
    mail.body = dict[@"body"];
    mail.starred = [dict[@"starred"] boolValue];
    mail.messages = [dict[@"messages"] intValue];

    mail.receivedAt = [NSDate parseRFC3339Date:dict[@"received_at"]];

    return mail;
}

@end
