//
//  PrototypeModel.m
//  IKSecondLifeViewer
//
//  Created by Igor Kamenev on 12/31/12.
//  Copyright (c) 2012 Igor Kamenev. All rights reserved.
//

#import "IKActiveRecord.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSMutableDictionary* _properties;

static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] == '@') {
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        } else {
            return (const char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1] bytes];
        }
    }
    return "@";
}

@implementation IKActiveRecord

+ (void) load {
    _properties = [NSMutableDictionary new];
}

+ (Sqlite*) db {
    Sqlite* maindb = [SqliteManager sqliteHandlerForMainDB];
    return maindb;
}

- (Sqlite*) db {
    Sqlite* maindb = [SqliteManager sqliteHandlerForMainDB];
    return maindb;
}

+ (NSString*) tableName {
    return NSStringFromClass([self class]);
}

- (NSString*) tableName {
    return [[self class] tableName];
}

+ (void) beginTransaction {
    [self.db executeNonQuery:@"BEGIN TRANSACTION"];
}

- (void) beginTransaction {
    [[self class] beginTransaction];
}

+ (void) endTransaction {
    [self.db executeNonQuery:@"END TRANSACTION"];
}

- (void) endTransaction {
    [[self class] endTransaction];
}

+ (NSArray*) properties {
    
    if (![_properties objectForKey:[self tableName]]) {
        
        NSMutableArray* result = [[NSMutableArray alloc] init];
        
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList([self class], &outCount);
        for(i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                const char *propType = getPropertyType(property);
                NSString *propertyName = [NSString stringWithCString:propName encoding:NSUTF8StringEncoding];
                NSString *propertyType = [NSString stringWithCString:propType encoding:NSUTF8StringEncoding];
                
                IKProperty* prop = [[IKProperty alloc] init];
                prop.propertyName = propertyName;
                prop.propertyType = propertyType;
                
                [result addObject: prop];
            }
        }
        free(properties);
        
        NSString* tableName = [self tableName];
        [_properties setObject:result forKey:tableName];
    }
    
    return [_properties objectForKey:[self tableName]];
}

- (NSArray* ) properties {
    
    return [[self class] properties];
}

- (void) deleteFromDB {
    
    if ([[self properties] count] == 0)
        return;

    NSMutableArray* args = [NSMutableArray new];
    NSMutableArray* whereAr = [NSMutableArray new];
    NSString* where = @"";
    
    if ([[[self class] uniqueFields] count] > 0) {
        
        for (NSString* field in [[self class] uniqueFields]) {
            
            id value = [self valueForKey:field];
            if (value) {
                [whereAr addObject: [where stringByAppendingFormat:@"%@=?", field]];
                [args addObject:value];
            }
        }
        
    } else {
        
        for (IKProperty* property in [self properties]) {
            
            NSString* field = property.propertyName;
            
            id value = [self valueForKey:field];
            if (value) {
                [whereAr addObject: [where stringByAppendingFormat:@"%@=?", field]];
                [args addObject:value];
            }
        }
    }
    
    where = [whereAr componentsJoinedByString:@" AND "];
    
    if ([args count] > 0) {
        NSString* query = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", [self tableName], where];
        [self.db executeNonQuery:query arguments:args];
    }
    
}

- (void) insertOrReplace {
    
    NSArray* properties = [self properties];
    
    NSMutableArray* fieldNames = [[NSMutableArray alloc] init];
    NSMutableArray* placeHolders = [[NSMutableArray alloc] init];
    NSMutableArray* values = [[NSMutableArray alloc] init];
    
    for (int i=0; i < [properties count]; i++) {
        
        IKProperty* property = [properties objectAtIndex:i];
        
        id value = [self valueForKey:property.propertyName];
        
        if (nil == value)
            continue;
        
        [fieldNames addObject: [NSString stringWithFormat:@"`%@`", property.propertyName ]];
        [placeHolders addObject:@"?"];
        [values addObject:value];
    }
    
    NSString* query = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) VALUES (%@)", [self tableName], [fieldNames componentsJoinedByString:@","], [placeHolders componentsJoinedByString:@","]];
    
    [self.db executeNonQuery:query arguments:values];
}

- (void) save {
    
    NSArray* properties = [self properties];
    
    if ([properties count] == 0)
        return;
    
    [self insertOrReplace];
}

+ (id) objectByDict: (NSDictionary*) dict {
    
    id object = [[[self class] alloc] init];
    
    NSArray* properties = [self properties];
    
    for (int i=0; i < [[self properties] count]; i++) {
        
        IKProperty* property = [properties objectAtIndex:i];
        
        id value;
        
        value = [dict objectForKey:property.propertyName];
        
        if ([property.propertyType isEqualToString:@"NSDate"]) {
            
            value = [NSDate dateWithTimeIntervalSince1970:[value floatValue]];
        }
        
        if (!value) {
            value = [dict objectForKey:[property.propertyName lowercaseString]];
        }
        
        if (value) {
            [object setValue:value forKey:property.propertyName];
        }
    }
    
    if ([object respondsToSelector:@selector(fillAdditionalInfoFromDictionary:)]) {
        [object performSelector:@selector(fillAdditionalInfoFromDictionary:) withObject:dict];
    }
    
    return object;
}

- (void) fillAdditionalInfoFromDictionary:(NSDictionary*)dictionary
{
    
}

+ (NSMutableArray*) runQueryWithSelect:(NSString*)select where:(NSString*)where orderBy:(NSString*)orderBy args:(NSArray*)args
offset:(NSUInteger)offset limit:(NSUInteger)limit
{
    NSMutableString* query = [NSMutableString stringWithString:(select ?: [self defaultSelect])];
    
    if (where.length > 0) {
        [query appendFormat:@" WHERE (%@)", where];
    }
    
    if (orderBy.length > 0) {
        [query appendFormat:@" ORDER BY %@", orderBy];
    }
    
    if (limit > 0 && limit < NSUIntegerMax) {
        [query appendFormat:@" LIMIT %d", limit];
    }

    if (offset > 0 && offset < NSUIntegerMax) {
        [query appendFormat:@" OFFSET %d", offset];
    }
    
    NSArray* dbItems = [self.db executeQuery:query arguments:args];
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:dbItems.count];
    
    for (NSDictionary* dbItem in dbItems)
    {
        [result addObject:[self objectByDict:dbItem]];
    }
    
    return result;
}

+ (NSArray*) findByQuery: (NSString*) query arguments: (NSArray*) arguments {
    
    NSArray* dbItems = [self.db executeQuery:query arguments:arguments];
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:dbItems.count];
    
    for (NSDictionary* dbItem in dbItems)
    {
        [result addObject:[self objectByDict:dbItem]];
    }
    
    return result;
}


+ (NSString*) defaultSelect {
    return [NSString stringWithFormat:@"SELECT * FROM %@", [self tableName]];
}

+ (NSString*) defaultWhere {
    return nil;
}

+ (NSString*) defaultOrderBy {
    
    if ([[self properties] count] == 0)
        return nil;
    
    NSArray* uniqueFields = [self uniqueFields];
    if ([uniqueFields count] > 0)
        return [uniqueFields objectAtIndex:0];

    NSArray* indexedFields = [self indexedFields];
    if ([indexedFields count] > 0)
        return [indexedFields objectAtIndex:0];
    
    return nil;
}

+ (NSMutableArray*) defaultQueryArguments
{
    return [NSMutableArray array];
}

+ (NSMutableArray*) findByExpression:(NSString*)expression arguments:(NSArray*)arguments limit:(NSUInteger)limit
{
    NSMutableArray* defaultArguments = [self defaultQueryArguments];
    
    if (arguments.count > 0) {
        [defaultArguments addObjectsFromArray:arguments];
    }
    
    return [self runQueryWithSelect:[self defaultSelect]
                              where:expression
                            orderBy:[self defaultOrderBy]
                               args:defaultArguments
                             offset:0
                              limit:limit];
}

+ (instancetype) findOneByExpression:(NSString*)expression arguments:(NSArray*)arguments
{
    NSArray* items = [self findByExpression:expression arguments:arguments limit:1];
    return (items.count > 0 ? items[0] : nil);
}

+ (NSMutableArray*) findAll
{
    return [self findAllWithLimit:0];
}

+ (NSMutableArray*) findAllWithLimit:(NSUInteger)limit
{
    return [self runQueryWithSelect:[self defaultSelect]
                              where:[self defaultWhere]
                            orderBy:[self defaultOrderBy]
                               args:[self defaultQueryArguments]
                             offset:0
                              limit:limit];
}

+ (instancetype) findAny {
    NSArray* res = [self findByExpression:@"" arguments:@[] limit:1];
    return (res.count > 0 ? res[0] : nil);
}

+ (NSMutableArray*) findAllByFieldName: (NSString*) fieldName equalTo: (id) value
{
    if (!value) {
        return [NSMutableArray array];
    }
    
    return [self findByExpression:[NSString stringWithFormat:@"%@=?", fieldName] arguments:@[value] limit:0];
}

+ (instancetype) findOneByFieldName: (NSString*) fieldName equalTo: (id) value {
    
    if (!value) {
        return nil;
    }
    
    NSArray* res = [self findByExpression:[NSString stringWithFormat:@"%@=?", fieldName] arguments:@[value] limit:1];
    
    if ([res count] == 0) {
        return nil;
    }
    
    return res[0];
}

+ (void) createTableIfNotExists {
    
    NSArray* result = [self.db executeQuery:@"SELECT * FROM sqlite_master WHERE type='table' AND name=?", [self tableName]];
    
    if ([result count] > 0)
        return; // table already exists
    
    NSMutableArray* fields = [[NSMutableArray alloc] init];
    NSArray* properties = [self properties];
    
    for (IKProperty* property in properties)
    {
        NSString* type = @"INTEGER";
        
        if ([property.propertyType isEqualToString:@"NSString"])
            type = @"VARCHAR";
        
        if ([property.propertyType isEqualToString:@"d"])
            type = @"REAL";
        
        NSString* field = [NSString stringWithFormat:@"`%@` %@", property.propertyName, type];
        
        [fields addObject:field];
    }
    
    NSString* query = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", [self tableName], [fields componentsJoinedByString:@","]];
    
    [self.db executeNonQuery:query];
    
    [self initializeTable];
}

// вызывается в случае если табличку создали
// для наполнения дефолтными записями, например
// или для создания индексов

+ (void) initializeTable {
    
    [self createUniqueIndexes];
    [self createIndexes];
}

+ (NSArray*) uniqueFields {
    return @[];
}

+ (NSArray*) indexedFields {
    return @[];
}

+ (void) createUniqueIndexes {
    
    NSArray* uniqueFields = [self uniqueFields];

    if ([uniqueFields count] <= 0)
        return;
        
    NSMutableArray* fieldsAr = [NSMutableArray new];
    
    for (NSString* field in uniqueFields) {

        [fieldsAr addObject: [NSString stringWithFormat:@"`%@` ASC", field]];
    }

    NSString* fields = [fieldsAr componentsJoinedByString:@","];
    
    NSString* query = [NSString stringWithFormat:@"CREATE UNIQUE INDEX IF NOT EXISTS `main`.`%@_UniqueIdx` ON `%@` (%@)", [self tableName], [self tableName], fields];
    [self.db executeNonQuery:query];
}

+ (void) createIndexes {

    NSArray* indexedFields = [self indexedFields];
    
    if ([indexedFields count] <= 0)
        return;
    
    for (NSString* field in indexedFields) {
        
        NSString* query = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS `main`.`%@_%@Idx` ON `%@` (`%@` ASC)", [self tableName], field, [self tableName],field];
        [self.db executeNonQuery:query];
    }
    
}

+ (void) truncate {
    
    NSString* query = [NSString stringWithFormat:@"DELETE FROM `main`.`%@`", [self tableName]];
    [self.db executeNonQuery:query];
}


- (NSString*) description {
    
    NSString* description = [super description];
    
    for (IKProperty* property in [self properties]) {
        
        description = [description stringByAppendingFormat:@" \n\t %@='%@',", property.propertyName, [self valueForKey:property.propertyName]];
    }

    return description;
}

@end
