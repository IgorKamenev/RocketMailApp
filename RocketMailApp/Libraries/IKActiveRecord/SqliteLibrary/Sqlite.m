//
//  Created by Matteo Bertozzi on 11/22/08.
//  Copyright 2008 Matteo Bertozzi. All rights reserved.
//

#import "Sqlite.h"

/* ============================================================================
 */
@interface Sqlite (PRIVATE)
- (BOOL)executeStatament:(sqlite3_stmt *)stmt;
- (BOOL)prepareSql:(NSString *)sql inStatament:(sqlite3_stmt **)stmt;
- (void) bindObject:(id)obj toColumn:(int)idx inStatament:(sqlite3_stmt *)stmt;

- (BOOL)hasData:(sqlite3_stmt *)stmt;
- (id)columnData:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index;
- (NSString *)columnName:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index;
@end

@implementation Sqlite

@synthesize busyRetryTimeout;
@synthesize filePath;


+ (NSString *)createUuid {
    
    unsigned char str[37];
    str[36] = 0;
    
    uuid_generate(str);

    return [NSString stringWithCString:(const char*) str encoding:NSASCIIStringEncoding];
}

+ (NSString *)version {
	return [NSString stringWithFormat:@"%s", sqlite3_libversion()];
}

- (id)init {
	if ((self = [super init])) {
		busyRetryTimeout = 1;
		filePath = nil;
		_db = nil;
	}

	return self;
}

- (id)initWithFile:(NSString *)dbFilePath {
	if (self = [super init]) {
		[self open:dbFilePath];
	}

	return self;
}

- (void)dealloc {
	[self close];

}

int collationUTF8CI(void *arg1, int str1Length, const void *str1, int 
                     str2Length, const void *str2) {
    
    NSString* strA = [NSString stringWithUTF8String:str1];
    NSString* strB = [NSString stringWithUTF8String:str2];

    int result = [strA localizedCaseInsensitiveCompare:strB];
    
    NSLog(@"collationUTF8CI %d %@ %@", result, strA, strB); 
    
    return result;    
    
//    NSString *strA = [NSString hexStringWithData:str1 ofLength:1];
//    NSString *strB = [NSString hexStringWithData:str2 ofLength:1];
//    int striA;
//    sscanf([strA cString], "%x", &striA);
//    int striB;
//    sscanf([strB cString], "%x", &striB);
//    
//    
//    //convert to accentless
//    //aA with accent to capital A
//    if( (striA >= 192 && striA <= 197) || (striA >= 224 && striA <= 229) ){
//        striA = 65;
//    }
//    //çÇ to C
//    if( striA == 199 || striA == 231 ){
//        striA = 67;
//    }
//    //eE with accent to capital E
//    if( (striA >= 200 && striA <= 203) || (striA >= 232 && striA <= 235) ){
//        striA = 69;
//    }
//    //iI with accent to capital I
//    if( (striA >= 204 && striA <= 207) || (striA >= 236 && striA <= 239) ){
//        striA = 73;
//    }
//    //oO with accent to capital O
//    if( (striA >= 210 && striA <= 214) || (striA >= 242 && striA <= 246) ){
//        striA = 79;
//    }
//    //uU with accent to capital U
//    if( (striA >= 217 && striA <= 220) || (striA >= 249 && striA <= 252) ){
//        striA = 85;
//    }
//    //a-z to A-Z
//    if( striA >= 97 && striA <= 122 ){
//        striA -= 32;
//    }
//    
//    //convert to accentless
//    //aA with accent to capital A
//    if( (striB >= 192 && striB <= 197) || (striB >= 224 && striB <= 229) ){
//        striB = 65;
//    }
//    //çÇ to C
//    if( striB == 199 || striB == 231 ){
//        striB = 67;
//    }
//    //eE with accent to capital E
//    if( (striB >= 200 && striB <= 203) || (striB >= 232 && striB <= 235) ){
//        striB = 69;
//    }
//    //iI with accent to capital I
//    if( (striB >= 204 && striB <= 207) || (striB >= 236 && striB <= 239) ){
//        striB = 73;
//    }
//    //oO with accent to capital O
//    if( (striB >= 210 && striB <= 214) || (striB >= 242 && striB <= 246) ){
//        striB = 79;
//    }
//    //uU with accent to capital U
//    if( (striB >= 217 && striB <= 220) || (striB >= 249 && striB <= 252) ){
//        striB = 85;
//    }
//    //a-z to A-Z
//    if( striB >= 97 && striB <= 122 ){
//        striB -= 32;
//    }
//    
//    int result = striA - striB;
    
    
    return 1;
}                             

static int _CaseInsensitiveUTF8Compare(void* context, int length1, const void* bytes1, int length2, const void* bytes2) {
    CFStringRef string1 = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, bytes1, length1, kCFStringEncodingUTF8, false, kCFAllocatorNull);
    CFStringRef string2 = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, bytes2, length2, kCFStringEncodingUTF8, false, kCFAllocatorNull);
    CFComparisonResult result = CFStringCompare(string1, string2, kCFCompareCaseInsensitive);

    int i = result;
    
    NSLog(@"%d %@ %@", i, string1, string2);
    
    CFRelease(string2);
    CFRelease(string1);
    
    
    return result;
}

//static void _LIKE(sqlite3_context *context, int argc, sqlite3_value **argv ){
//
//    NSLog(@"LIKE!!");
//    sqlite3_result_int(context, 1);
//}

static void likeFunction(sqlite3_context *p, int argc, sqlite3_value **argv)
{

    const char * str = (const char *) sqlite3_value_text(argv[0]);
    
    NSString* lowerNSString = [[NSString stringWithUTF8String:str] lowercaseString];
    
    const char * lowerString = [lowerNSString cStringUsingEncoding:NSUTF8StringEncoding];
    
    sqlite3_result_text(p, lowerString, 1000, 0);
    
}

- (BOOL)open:(NSString *)path {
	[self close];

	if (sqlite3_open_v2 ([path fileSystemRepresentation], &_db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, NULL) != SQLITE_OK) {
		NSLog(@"SQLite Opening Error: %s", sqlite3_errmsg(_db));
		return NO;
	}

    //	if (sqlite3_open([path fileSystemRepresentation], &_db) != SQLITE_OK) {
    //		NSLog(@"SQLite Opening Error: %s", sqlite3_errmsg(_db));
    //		return NO;
    //	}
    
    sqlite3_create_collation(_db, "IKUTF8CI", SQLITE_UTF8, NULL, _CaseInsensitiveUTF8Compare);
    
    sqlite3_create_function(_db, "lower", 1, SQLITE_UTF8, 0, likeFunction, 0, 0);
    
	filePath = path;
	return YES;
}

- (void)close {
	if (_db == nil) return;

	int numOfRetries = 0;
	int rc;

	do {
		rc = sqlite3_close(_db);
		if (rc == SQLITE_OK)
			break;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy, unable to close: %@", filePath);
				break;
			}
		} else {
			NSLog(@"SQLite %@ Closing Error: %s", filePath, sqlite3_errmsg(_db));
			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	filePath = nil;
	_db = nil;
}

- (NSInteger)errorCode {
	return sqlite3_errcode(_db);
}

- (NSString *)errorMessage {
	return [NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)];
}

- (NSArray *)executeQuery:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);

	NSMutableArray *argsArray = [[NSMutableArray alloc] init];
	NSUInteger i;
	for (i = 0; i < [sql length]; ++i) {
		if ([sql characterAtIndex:i] == '?')
			[argsArray addObject:va_arg(args, id)];
	}

	va_end(args);

	NSArray *result = [self executeQuery:sql arguments:argsArray];

	return result;
}

- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)args {
	sqlite3_stmt *sqlStmt;

	if (![self prepareSql:sql inStatament:(&sqlStmt)])
		return nil;

	int i = 0;
	int queryParamCount = sqlite3_bind_parameter_count(sqlStmt);
	while (i++ < queryParamCount)
		[self bindObject:[args objectAtIndex:(i - 1)] toColumn:i inStatament:sqlStmt];

	NSMutableArray *arrayList = [[NSMutableArray alloc] init];
	int columnCount = sqlite3_column_count(sqlStmt);
	while ([self hasData:sqlStmt]) {
		NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
		for (i = 0; i < columnCount; ++i) {
			id columnName = [self columnName:sqlStmt columnIndex:i];
			id columnData = [self columnData:sqlStmt columnIndex:i];
            if (columnData)
                [dictionary setObject:columnData forKey:columnName];
		}
		[arrayList addObject:dictionary];
	}

	sqlite3_finalize(sqlStmt);

	return arrayList;
}

- (BOOL)executeNonQuery:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);

	NSMutableArray *argsArray = [[NSMutableArray alloc] init];
	NSUInteger i;
	for (i = 0; i < [sql length]; ++i) {
		if ([sql characterAtIndex:i] == '?')
			[argsArray addObject:va_arg(args, id)];
	}

	va_end(args);

	BOOL success = [self executeNonQuery:sql arguments:argsArray];
//    assert(success);
	return success;
}

- (BOOL)executeNonQuery:(NSString *)sql arguments:(NSArray *)args {
	sqlite3_stmt *sqlStmt;

	if (![self prepareSql:sql inStatament:(&sqlStmt)])
		return NO;

	int i = 0;
	int queryParamCount = sqlite3_bind_parameter_count(sqlStmt);
	while (i++ < queryParamCount)
		[self bindObject:[args objectAtIndex:(i - 1)] toColumn:i inStatament:sqlStmt];

	BOOL success = [self executeStatament:sqlStmt];
//    assert(success);
	sqlite3_finalize(sqlStmt);
	return success;
}

- (BOOL)commit {
	return [self executeNonQuery:@"COMMIT TRANSACTION;"];
}

- (BOOL)rollback {
	return [self executeNonQuery:@"ROLLBACK TRANSACTION;"];
}

- (BOOL)beginTransaction {
	return [self executeNonQuery:@"BEGIN EXCLUSIVE TRANSACTION;"];
}

- (BOOL)beginDeferredTransaction {
	return [self executeNonQuery:@"BEGIN DEFERRED TRANSACTION;"];
}

/* ============================================================================
 *  PRIVATE Methods
 */

- (BOOL)prepareSql:(NSString *)sql inStatament:(sqlite3_stmt **)stmt {
	int numOfRetries = 0;
	int rc;

	do {
		rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, stmt, NULL);
		if (rc == SQLITE_OK)
			return YES;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy: %@", filePath);
				break;
			}
		} else {
			NSLog(@"SQLite Prepare Failed: %s", sqlite3_errmsg(_db));
			NSLog(@" - Query: %@", sql);
			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	return NO;
}

- (BOOL)executeStatament:(sqlite3_stmt *)stmt {
	int numOfRetries = 0;
	int rc;

	do {
		rc = sqlite3_step(stmt);
		if (rc == SQLITE_OK || rc == SQLITE_DONE)
			return YES;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy: %@", filePath);
				break;
			}
		} else {
			NSLog(@"SQLite Step Failed: %s", sqlite3_errmsg(_db));
			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	return NO;
}

- (void)bindObject:(id)obj toColumn:(int)idx inStatament:(sqlite3_stmt *)stmt {
        
	if (obj == nil || obj == [NSNull null]) {
		sqlite3_bind_null(stmt, idx);
	} else if ([obj isKindOfClass:[NSData class]]) {
		sqlite3_bind_blob(stmt, idx, [obj bytes], [obj length], SQLITE_STATIC);
	} else if ([obj isKindOfClass:[NSDate class]]) {
		sqlite3_bind_double(stmt, idx, [obj timeIntervalSince1970]);
	} else if ([obj isKindOfClass:[NSNumber class]]) {
		if (!strcmp([obj objCType], @encode(BOOL))) {
			sqlite3_bind_int(stmt, idx, [obj boolValue] ? 1 : 0);
		} else if (!strcmp([obj objCType], @encode(int))) {
			sqlite3_bind_int64(stmt, idx, [obj longValue]);
		} else if (!strcmp([obj objCType], @encode(long))) {
			sqlite3_bind_int64(stmt, idx, [obj longValue]);
		} else if (!strcmp([obj objCType], @encode(float))) {
			sqlite3_bind_double(stmt, idx, [obj floatValue]);
		} else if (!strcmp([obj objCType], @encode(double))) {
			sqlite3_bind_double(stmt, idx, [obj doubleValue]);
		} else {
			sqlite3_bind_text(stmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
		}
	} else {
		sqlite3_bind_text(stmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
	}
}

- (BOOL)hasData:(sqlite3_stmt *)stmt {
	int numOfRetries = 0;
	int rc;

	do {
		rc = sqlite3_step(stmt);
		if (rc == SQLITE_ROW)
			return YES;

		if (rc == SQLITE_DONE)
			break;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy: %@", filePath);
				break;
			}
		} else {
			NSLog(@"SQLite Prepare Failed: %s", sqlite3_errmsg(_db));
			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	return NO;
}

- (id)columnData:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index {
	int columnType = sqlite3_column_type(stmt, index);

	if (columnType == SQLITE_NULL)
		return(nil);

	if (columnType == SQLITE_INTEGER)
		return [NSNumber numberWithLongLong:sqlite3_column_int64(stmt, index)];

	if (columnType == SQLITE_FLOAT)
		return [NSNumber numberWithDouble:sqlite3_column_double(stmt, index)];

	if (columnType == SQLITE_TEXT) {
		const unsigned char *text = sqlite3_column_text(stmt, index);
		return [NSString stringWithCString:(const char *) text encoding:NSUTF8StringEncoding];
	}

	if (columnType == SQLITE_BLOB) {
		int nbytes = sqlite3_column_bytes(stmt, index);
		const char *bytes = sqlite3_column_blob(stmt, index);
		return [NSData dataWithBytes:bytes length:nbytes];
	}

	return nil;
}

- (NSString *)columnName:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index {
	return [NSString stringWithUTF8String:sqlite3_column_name(stmt, index)];
}

- (int) lastInsertedRowId
{
    return sqlite3_last_insert_rowid(_db);
}

@end

