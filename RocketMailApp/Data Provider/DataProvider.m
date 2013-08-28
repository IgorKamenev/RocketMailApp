//
//  DataProvider.m
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import "DataProvider.h"

@interface DataProvider ()

@end

static NSString* kMailApiURL = @"http://rocket-ios.herokuapp.com/emails.json";

@implementation DataProvider

+ (DataProvider*) sharedInstance {
    
    static DataProvider* _sharedInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[DataProvider alloc] init];
    });
    
    return _sharedInstance;
}

- (NSArray*) mailByPage: (int) page withType: (RMMailType) type successBlock:(void (^)(NSMutableArray* emails))success
{
    
    NSString* urlStr = [NSString stringWithFormat:@"%@?page=%d", kMailApiURL,page];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {

        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

            NSMutableArray* emailsAr = [NSMutableArray new];
            
            NSDictionary* emails = json[@"emails"];
            
            [RMMail beginTransaction];
            for (NSDictionary* email in emails) {
                RMMail* mail = [RMMail mailByDict:email];
                [mail save];
                [emailsAr addObject:mail];
            }
            [RMMail endTransaction];
            success(emailsAr);
        });
        
    } failure:nil];

    [operation start];
    
    return nil;
}

- (NSMutableArray*) emailsFromDBWithType: (RMMailType) mailType
{
    return [RMMail findAllByFieldName:@"type" equalTo: [NSNumber numberWithInt:mailType] orderBy:@"receivedAt DESC"];
}

- (void) removeAllEmails
{
    [RMMail truncate];
}

@end
