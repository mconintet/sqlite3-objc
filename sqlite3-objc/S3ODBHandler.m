//
//  S3ODBHandler.m
//  sqlite3-objc
//
//  Created by mconintet on 10/17/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "S3ODBHandler.h"
#import "macros.h"
#import "objc/runtime.h"

@interface S3ODBHandler ()
@property (nonatomic, assign) sqlite3* dbh;
@end

@implementation S3ODBHandler

- (instancetype)initWithDBFilePath:(NSString*)dbFilePath
{
    self = [super init];
    if (self) {
        BOOL result = sqlite3_open([dbFilePath UTF8String], &_dbh);

        if (result != SQLITE_OK) {
            NSString* reason = [NSString stringWithFormat:@"cannot open DB: %@", dbFilePath];
            raiseException(NSInvalidArgumentException, reason);
        }
    }
    return self;
}

- (void)close
{
    if (_dbh != nil) {
        sqlite3_close(_dbh);
        _dbh = nil;
    }
}

- (NSInteger)errCode
{
    if (_dbh != nil) {
        sqlite3_errcode(_dbh);
    }
    return -1;
}

- (NSString*)errMsg
{
    if (_dbh != nil) {
        return [NSString stringWithUTF8String:sqlite3_errmsg(_dbh)];
    }
    return nil;
}

- (S3OStatement*)newStmtWithString:(NSString*)stmtStr
{
    sqlite3_stmt* stmt = nil;
    BOOL ok = sqlite3_prepare_v2(_dbh, [stmtStr UTF8String], -1, &stmt, NULL);
    if (ok == SQLITE_OK) {
        return [[S3OStatement alloc] initWithS3Stmt:stmt dbHandler:self];
    }
    DLOG(@"errCode: %ld errMsg: %@", (long)[self errCode], [self errMsg]);
    return nil;
}

- (UInt64)lastInsertRowID
{
    return sqlite3_last_insert_rowid(_dbh);
}

- (NSInteger)totalChanges
{
    return sqlite3_total_changes(_dbh);
}

+ (NSString*)quoteStr:(NSString*)str
{
    return [NSString stringWithFormat:@"`%@`", str];
}

+ (NSArray*)quoteStrArr:(NSArray*)strArr
{
    NSMutableArray* ret = [NSMutableArray arrayWithCapacity:[strArr count]];
    for (NSString* str in strArr) {
        [ret addObject:[self quoteStr:str]];
    }
    return ret;
}

+ (NSString*)selectStrWithColumns:(NSArray*)columns tableName:(NSString*)tableName
{
    NSString* format = @"SELECT %@ FROM %@ ";
    NSString* cols = nil;
    if (columns != nil) {
        cols = [[self quoteStrArr:columns] componentsJoinedByString:@","];
    }
    else {
        cols = @"*";
    }
    NSString* ret = [NSString stringWithFormat:format, cols, [self quoteStr:tableName]];
    return ret;
}

+ (NSString*)insertStrWithColumns:(NSArray*)columns tableName:(NSString*)tableName
{
    NSString* format = @"INSERT INTO %@ (%@) VALUES(%@) ";
    NSString* cols = [[self quoteStrArr:columns] componentsJoinedByString:@","];
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (NSString* col in columns) {
        [array addObject:[NSString stringWithFormat:@":%@", col]];
    }
    NSString* pns = [array componentsJoinedByString:@","];
    NSString* ret = [NSString stringWithFormat:format, [self quoteStr:tableName], cols, pns];
    return ret;
}

+ (NSString*)updateStrWithColumns:(NSArray*)columns tableName:(NSString*)tableName
{
    NSString* format = @"UPDATE %@ SET %@ ";
    NSMutableArray* kv = [[NSMutableArray alloc] init];
    for (NSString* col in columns) {
        [kv addObject:[NSString stringWithFormat:@"`%@`=:%@", col, col]];
    }
    NSString* pns = [kv componentsJoinedByString:@","];
    NSString* ret = [NSString stringWithFormat:format, [self quoteStr:tableName], pns];
    return ret;
}

+ (NSString*)whereStrWithConditions:(NSArray*)conditions
{
    NSString* format = @"WHERE %@ ";
    NSMutableArray* kv = [[NSMutableArray alloc] init];
    for (NSString* cd in conditions) {
        [kv addObject:[NSString stringWithFormat:@"`%@`=:%@", cd, cd]];
    }
    NSString* cds = [kv componentsJoinedByString:@" AND "];
    NSString* ret = [NSString stringWithFormat:format, cds];
    return ret;
}

+ (NSString*)whereNotStrWithConditions:(NSArray*)conditions
{
    NSString* format = @"WHERE %@ ";
    NSMutableArray* kv = [[NSMutableArray alloc] init];
    for (NSString* cd in conditions) {
        [kv addObject:[NSString stringWithFormat:@"`%@`!=:%@", cd, cd]];
    }
    NSString* cds = [kv componentsJoinedByString:@"AND"];
    NSString* ret = [NSString stringWithFormat:format, cds];
    return ret;
}

@end

@implementation S3OStatement

- (instancetype)initWithS3Stmt:(sqlite3_stmt*)stmt dbHandler:(S3ODBHandler*)dbHandler
{
    self = [super init];
    if (self) {
        _stmt = stmt;
        _dbHandler = dbHandler;
    }
    return self;
}

- (void)finalize
{
    if (_stmt != nil) {
        sqlite3_finalize(_stmt);
        _stmt = nil;
    }
}

- (void)dealloc
{
    if (_stmt != nil) {
        sqlite3_finalize(_stmt);
        _stmt = nil;
    }
}

- (void)bindParamWithIdx:(NSUInteger)paramIdx value:(id)value
{
    if (value == nil) {
        DLOG(@"sqlite3_bind_null idx:%d", (int)paramIdx);
        sqlite3_bind_null(_stmt, (int)paramIdx);
        return;
    }

    if (O_IS_T(value, NSString)) {
        DLOG(@"sqlite3_bind_text idx:%d", (int)paramIdx);
        NSString* s = (NSString*)value;
        sqlite3_bind_text(_stmt, (int)paramIdx, [s UTF8String], -1, SQLITE_TRANSIENT);
        return;
    }

    if (O_IS_T(value, NSNumber)) {
        NSNumber* n = (NSNumber*)value;
        switch (CFNumberGetType((CFNumberRef)n)) {
        case kCFNumberSInt8Type:
        case kCFNumberSInt16Type:
        case kCFNumberSInt32Type:
        case kCFNumberCharType:
        case kCFNumberShortType:
        case kCFNumberLongType:
        case kCFNumberIntType:
        case kCFNumberNSIntegerType:
        case kCFNumberCFIndexType:
            DLOG(@"sqlite3_bind_int idx:%d", (int)paramIdx);
            sqlite3_bind_int(_stmt, (int)paramIdx, [n intValue]);
            break;

        case kCFNumberLongLongType:
        case kCFNumberSInt64Type:
            DLOG(@"sqlite3_bind_int64 idx:%d", (int)paramIdx);
            sqlite3_bind_int64(_stmt, (int)paramIdx, [n longLongValue]);
            break;

        case kCFNumberFloat32Type:
        case kCFNumberFloatType:
        case kCFNumberDoubleType:
        case kCFNumberCGFloatType:
        case kCFNumberFloat64Type:
            DLOG(@"sqlite3_bind_double idx:%d", (int)paramIdx);
            sqlite3_bind_double(_stmt, (int)paramIdx, [n doubleValue]);
            break;
        default:
            DLOG(@"unknown");
            break;
        }
        return;
    }

    if (O_IS_T(value, NSData)) {
        NSData* d = (NSData*)value;
        sqlite3_bind_blob(_stmt, (int)paramIdx, [d bytes], (int)[d length], SQLITE_TRANSIENT);
        return;
    }
}

- (void)bindParamWithName:(NSString*)paramName value:(id)value
{
    DLOG(@"bind param with name: %@", paramName);
    int idx = sqlite3_bind_parameter_index(_stmt, [paramName UTF8String]);
    if (idx == 0) {
        NSString* reason = [NSString stringWithFormat:@"no associated idx with name: %@", paramName];
        raiseException(NSInvalidArgumentException, reason);
    }
    [self bindParamWithIdx:idx value:value];
}

- (void)bindParamWithNameDict:(NSDictionary*)dict
{
    for (NSString* n in dict) {
        [self bindParamWithName:n value:[dict objectForKey:n]];
    }
}

- (BOOL)execute
{
    return sqlite3_step(_stmt) == SQLITE_DONE;
}

- (BOOL)executeWithParams:(NSDictionary*)params
{
    for (NSString* pn in params) {
        [self bindParamWithName:pn value:[params objectForKey:pn]];
    }
    return [self execute];
}

- (NSDictionary*)newRow
{
    NSMutableDictionary* ret = nil;
    @autoreleasepool
    {
        int stepRet = sqlite3_step(_stmt);
        DLOG(@"stepRet: %d", stepRet);
        if (stepRet == SQLITE_ROW) {
            int colsCount = sqlite3_column_count(_stmt);
            ret = [[NSMutableDictionary alloc] initWithCapacity:colsCount];

            for (int i = 0; i < colsCount; i++) {
                NSString* colName = [NSString stringWithUTF8String:sqlite3_column_name(_stmt, i)];
                id colValue = [NSNull null];

                int colType = sqlite3_column_type(_stmt, i);
                DLOG(@"colType:%d", colType);

                switch (colType) {
                case SQLITE_INTEGER:
                    colValue = [NSNumber numberWithLongLong:sqlite3_column_int64(_stmt, i)];
                    break;
                case SQLITE_FLOAT:
                    colValue = [NSNumber numberWithDouble:sqlite3_column_double(_stmt, i)];
                    break;
                case SQLITE_BLOB:
                    colValue = [NSMutableData dataWithBytes:sqlite3_column_blob(_stmt, i)
                                                     length:sqlite3_column_bytes(_stmt, i)];
                    break;
                case SQLITE_NULL:
                    break;
                case SQLITE_TEXT:
                    colValue = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(_stmt, i)];
                    break;
                default:
                    break;
                }

                [ret setObject:colValue forKey:colName];
            }
        }
        else {
            DLOG(@"errCode: %ld errMsg: %@", (long)[_dbHandler errCode], [_dbHandler errMsg]);
        }
    }
    return ret;
}

- (BOOL)fetchRowToObj:(NSObject*)obj
{
    NSDictionary* row = [self newRow];
    if (!row) {
        DLOG(@"cannot fetch row");
        return false;
    }

    @autoreleasepool
    {
        unsigned int outCount, i;
        objc_property_t* properties = class_copyPropertyList([obj class], &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char* propRawName = property_getName(property);
            NSString* propName = [NSString stringWithUTF8String:propRawName];
            id propValue = [row objectForKey:propName];

            [obj setValue:propValue forKey:propName];
        }
        free(properties);
    }
    return true;
}

- (id)newRowWithClass:(Class)cls customSetup:(void (^)(id obj))customSetup
{
    NSDictionary* row = [self newRow];
    if (row == nil) {
        DLOG(@"cannot fetch row");
        return nil;
    }

    id ret = nil;
    @autoreleasepool
    {
        ret = [[cls alloc] init];
        unsigned int outCount, i;
        objc_property_t* properties = class_copyPropertyList(cls, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char* propRawName = property_getName(property);
            NSString* propName = [NSString stringWithUTF8String:propRawName];
            id propValue = [row objectForKey:propName];

            [ret setValue:propValue forKey:propName];
        }
        free(properties);

        if (customSetup != nil) {
            customSetup(ret);
        }
    }
    return ret;
}

- (NSArray*)newRawsWithClass:(Class)cls customSetup:(void (^)(id obj))customSetup
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    NSDictionary* row = [self newRowWithClass:cls customSetup:customSetup];
    while (row) {
        [ret addObject:row];
        row = [self newRowWithClass:cls customSetup:customSetup];
    }
    return ret;
}
@end
