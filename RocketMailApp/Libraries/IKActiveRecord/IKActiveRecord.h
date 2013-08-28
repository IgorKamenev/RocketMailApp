//
//  PrototypeModel.h
//  IKSecondLifeViewer
//
//  Created by Igor Kamenev on 12/31/12.
//  Copyright (c) 2012 Igor Kamenev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IKProperty.h"
#import "SqliteManager.h"

#define ObjectValueOrNil(obj) ((obj && obj != [NSNull null]) ? obj : nil)

@interface IKActiveRecord : NSObject

+ (NSArray* ) properties;

+ (Sqlite*) db;
- (Sqlite*) db;

+ (NSString*) tableName;
+ (void) createTableIfNotExists;
+ (void) initializeTable;
+ (void) beginTransaction;
- (void) beginTransaction;
+ (void) endTransaction;
- (void) endTransaction;

+ (id) objectByDict: (NSDictionary*) dict;
- (void) fillAdditionalInfoFromDictionary:(NSDictionary*)dictionary;

+ (NSMutableArray*) findAll;
+ (NSMutableArray*) findAllByFieldName: (NSString*) fieldName equalTo: (id) value;
+ (NSMutableArray*) findAllByFieldName:(NSString *)fieldName equalTo:(id)value orderBy: (NSString*) orderBy;
+ (NSMutableArray*) findAllWithLimit:(NSUInteger)limit;
+ (NSMutableArray*) findByExpression:(NSString*)expression arguments:(NSArray*)arguments limit:(NSUInteger)limit;
+ (instancetype) findOneByExpression:(NSString*)expression arguments:(NSArray*)arguments;
+ (instancetype) findOneByFieldName: (NSString*) fieldName equalTo: (id) value;
+ (instancetype) findAny;

+ (NSArray*) findByQuery: (NSString*) query arguments: (NSArray*) arguments;

+ (NSString*) defaultSelect;
+ (NSString*) defaultWhere;
+ (NSString*) defaultOrderBy;
+ (NSMutableArray*) defaultQueryArguments;

+ (void) truncate;

- (void) save;
- (void) deleteFromDB;

+ (NSMutableArray*) runQueryWithSelect:(NSString*)select
                                 where:(NSString*)where
                               orderBy:(NSString*)orderBy
                                  args:(NSArray*)args
                                offset:(NSUInteger)offset
                                 limit:(NSUInteger)limit;

+ (NSArray*) uniqueFields;
+ (NSArray*) indexedFields;

@end
