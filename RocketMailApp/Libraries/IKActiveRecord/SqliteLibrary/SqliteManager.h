//
//  SqliteManager.h
//  DashBoard
//
//  Created by Igor Kamenev on 12-05-04.
//  Copyright (c) 2012 Touch Soft, LLC. All rights reserved.
//

#define DB_DIR @"/"

#import <Foundation/Foundation.h>
#import "Sqlite.h"

@class Indicator;

@interface SqliteManager : NSObject {

}

+ (Sqlite*) sqliteHandlerForPath: (NSString*) path;
+ (Sqlite*) sqliteHandlerForMainDB;

@end
