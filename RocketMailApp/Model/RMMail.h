//
//  RMMail.h
//  RocketMailApp
//
//  Created by Igor Kamenev on 8/27/13.
//  Copyright (c) 2013 Igor Kamenev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IKActiveRecord.h"

typedef enum {

    RMMailTypeActual,
    RMMailTypeDone,
    RMMailTypeDeleted,
    
} RMMailType;

@interface RMMail : IKActiveRecord

@property (nonatomic) int ID;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;
@property (nonatomic, strong) NSString* subject;
@property (nonatomic, strong) NSString* body;
@property (nonatomic) BOOL starred;
@property (nonatomic) int messages;
@property (nonatomic, strong) NSDate* receivedAt;
@property (nonatomic) RMMailType type;

+ (RMMail*) mailByDict: (NSDictionary*) dict;

- (NSString*) fromDescription;

@end
