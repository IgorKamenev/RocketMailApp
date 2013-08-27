//
//  IKProperty.m
//  IKSecondLifeViewer
//
//  Created by Igor Kamenev on 12/31/12.
//  Copyright (c) 2012 Igor Kamenev. All rights reserved.
//

#import "IKProperty.h"

@implementation IKProperty

- (NSString*) description {
    
    return [NSString stringWithFormat:@"propertyName: %@, propertyType: %@", self.propertyName, self.propertyType];
}

@end
