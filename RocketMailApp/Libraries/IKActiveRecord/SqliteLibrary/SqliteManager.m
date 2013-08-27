//
//  SqliteManager.m
//  DashBoard
//
//  Created by Igor Kamenev on 12-05-04.
//  Copyright (c) 2012 Touch Soft, LLC. All rights reserved.
//

#import "SqliteManager.h"

@implementation SqliteManager

static NSMutableDictionary* sqliteHandlers = nil;

static Sqlite* _mainDbHandler;

+ (NSString*) pathForMainDB {

    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString* mainDbPath = [[documentsPath stringByAppendingPathComponent:@"Main"] stringByAppendingPathExtension:@"sqlite"];

    return mainDbPath;
}

+ (Sqlite*) sqliteHandlerForMainDB {

    if (_mainDbHandler)
        return _mainDbHandler;
    
    _mainDbHandler = [self sqliteHandlerForPath: [self pathForMainDB]];
    
    return _mainDbHandler;
}


+ (Sqlite*) sqliteHandlerForPath: (NSString*) path {

    if (!sqliteHandlers)
        sqliteHandlers = [[NSMutableDictionary alloc] init];

    if (![sqliteHandlers objectForKey:path]) {

        Sqlite* sqlite = [[Sqlite alloc] init];
        if (![sqlite open:path]) {

            NSLog(@"Can not open database file: '%@'", path);
            return nil;
        }

        [sqliteHandlers setObject:sqlite forKey:path];
        return sqlite;
    }

    return [sqliteHandlers objectForKey:path];
}

@end
