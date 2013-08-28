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

- (NSString*) fromDescription {

    NSMutableArray* toPersons = [NSMutableArray new];

    NSArray* persons = [self.to componentsSeparatedByString:@","];
    
    for (NSString* str in persons) {
        
        NSDictionary* personDict = [self parsePersons:str];
        [toPersons addObject:personDict];
    }

    NSDictionary* fromPersonDict = [self parsePersons:self.from];
    
    NSString* from;
    
    if (toPersons.count == 1) {
        
        from = [NSString stringWithFormat:@"%@ & %@", fromPersonDict[@"name"], toPersons[0][@"name"]];
        
    } else {

        from = [NSString stringWithFormat:@"%@ & %d others", fromPersonDict[@"name"], toPersons.count];
    }
    
    return from;
}

- (NSDictionary*) parsePersons: (NSString*) persons
{

    NSString* person = [persons stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *pattern = @"(.*?) <(.*?)>";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    
    NSTextCheckingResult *res = [regex firstMatchInString:person options:0 range:NSMakeRange(0, person.length)];
    
    if (res.numberOfRanges == 0) {
        
        NSString* name = person;
        NSString* email = person;
        
        NSDictionary* dict = @{@"name": name, @"email": email};
        return dict;
        
    } else {
        
        NSString* name = [person substringWithRange:[res rangeAtIndex:1]];
        NSString* email = [person substringWithRange:[res rangeAtIndex:2]];
        
        NSDictionary* dict = @{@"name": name, @"email": email};
        return dict;
    }
    
}


@end
