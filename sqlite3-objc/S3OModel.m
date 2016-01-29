//
//  S3OModel.m
//  sqlite3-objc
//
//  Created by mconintet on 10/17/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "S3OModel.h"
#import "macros.h"

#define DEFAULT_LIMIT 5000

@interface S3OModel ()
@property (nonatomic, strong) NSMutableDictionary* changedPropNames;
@property (nonatomic, assign) BOOL addedObservers;
@end

@implementation S3OModel

+ (NSString*)tableName
{
    methodNotImplemented();
}

+ (NSString*)pk
{
    methodNotImplemented();
}

+ (NSArray*)columns
{
    methodNotImplemented();
}

+ (S3ODBHandler*)newDBHandler
{
    methodNotImplemented();
}

- (void)dealloc
{

    if (_addedObservers) {
        NSArray* cols = [[self class] columns];
        for (NSString* col in cols) {
            [self removeObserver:self forKeyPath:col];
        }
    }
}

- (void)addObservers
{
    if (!_addedObservers) {
        _changedPropNames = [[NSMutableDictionary alloc] init];

        NSArray* cols = [[self class] columns];
        for (NSString* col in cols) {
            [self addObserver:self forKeyPath:col options:0 context:nil];
        }
        _addedObservers = true;
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    DLOG(@"is changed");
    _isChanged = true;
    [_changedPropNames setObject:[NSNull null] forKey:keyPath];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _addedObservers = false;
        [self addObservers];
    }
    return self;
}

- (instancetype)initWithPKValue:(id)pkValue
{
    self = [super init];
    if (self) {
        @autoreleasepool {
            NSString* select = [S3ODBHandler selectStrWithColumns:[[self class] columns]
                                                        tableName:[[self class] tableName]];
            NSString* pk = [[self class] pk];
            NSString* where = [S3ODBHandler whereStrWithConditions:@[ pk ]];

            S3ODBHandler* dbh = [[self class] newDBHandler];
            DLOG(@"%@", dbh);

            NSString* sql = [NSString stringWithFormat:@"%@%@", select, where];
            DLOG(@"sql: %@", sql);

            S3OStatement* stmt = [dbh newStmtWithString:sql];
            [stmt bindParamWithName:[NSString stringWithFormat:@":%@", pk] value:pkValue];
            [stmt fetchRowToObj:self];

            [stmt finalize];
            [dbh close];

            [self addObservers];
        }
    }
    return self;
}

- (instancetype)initWithWhereCondition:(NSString*)condition bindParams:(NSDictionary*)bindParams
{
    self = [super init];
    if (self) {
        @autoreleasepool {
            NSString* select = [S3ODBHandler selectStrWithColumns:[[self class] columns]
                                                        tableName:[[self class] tableName]];
            S3ODBHandler* dbh = [[self class] newDBHandler];
            DLOG(@"%@", dbh);

            NSString* sql = [NSString stringWithFormat:@"%@ WHERE %@", select, condition];
            DLOG(@"sql: %@", sql);

            S3OStatement* stmt = [dbh newStmtWithString:sql];
            for (NSString* paramName in bindParams) {
                [stmt bindParamWithName:paramName value:[bindParams objectForKey:paramName]];
            }
            [stmt fetchRowToObj:self];

            [stmt finalize];
            [dbh close];

            [self addObservers];
        }
    }
    return self;
}

- (BOOL)save
{
    if (!_isChanged) {
        return true;
    }

    BOOL ok = false;
    @autoreleasepool {
        S3ODBHandler* dbh = [[self class] newDBHandler];
        DLOG(@"%@", dbh);

        NSString* pk = [[self class] pk];
        NSObject* pkVal = [self valueForKey:pk];

        // if has pk then update
        if (pkVal) {
            NSString* update = [S3ODBHandler updateStrWithColumns:[_changedPropNames allKeys]
                                                        tableName:[[self class] tableName]];

            NSString* where = [S3ODBHandler whereStrWithConditions:@[ pk ]];

            NSString* sql = [NSString stringWithFormat:@"%@%@", update, where];
            DLOG(@"sql: %@", sql);

            S3OStatement* stmt = [dbh newStmtWithString:sql];
            for (NSString* propName in _changedPropNames) {
                DLOG(@"changed prop: %@", propName);
                NSString* paramName = [NSString stringWithFormat:@":%@", propName];
                [stmt bindParamWithName:paramName value:[self valueForKey:propName]];
            }

            [stmt bindParamWithName:[NSString stringWithFormat:@":%@", pk] value:[self valueForKey:pk]];
            ok = [stmt execute];

#ifdef DEBUG
            if (!ok) {
                DLOG(@"failed to save: %@", [dbh errMsg]);
            }
#endif

            [stmt finalize];
            [dbh close];

            return ok;
        }

        // insert new
        NSString* sql = [S3ODBHandler insertStrWithColumns:[_changedPropNames allKeys]
                                                 tableName:[[self class] tableName]];
        DLOG(@"sql: %@", sql);
        S3OStatement* stmt = [dbh newStmtWithString:sql];
        for (NSString* propName in _changedPropNames) {
            NSString* paramName = [NSString stringWithFormat:@":%@", propName];
            [stmt bindParamWithName:paramName value:[self valueForKey:propName]];
        }

        ok = [stmt execute];

#ifdef DEBUG
        if (!ok) {
            DLOG(@"failed to save: %@", [dbh errMsg]);
        }
#endif

        if (ok) {
            [self setValue:@(dbh.lastInsertRowID) forKey:pk];
        }

        [stmt finalize];
        [dbh close];

        return ok;
    }
}

+ (NSArray*)newModelsWithWhereCondition:(NSString*)condition
                             bindParams:(NSDictionary*)bindParams
                                orderBy:(NSString*)orderBy
                                    asc:(BOOL)asc
                                  limit:(NSUInteger)limit
                                 offset:(NSInteger)offset
{
    NSString* select = [S3ODBHandler selectStrWithColumns:[self columns]
                                                tableName:[self tableName]];
    S3ODBHandler* dbh = [self newDBHandler];
    DLOG(@"%@", dbh);

    NSString* sql = [NSString stringWithFormat:@"%@ WHERE %@ ", select, condition];

    if (orderBy != nil) {
        sql = [NSString stringWithFormat:@"%@ ORDER BY `%@` %@", sql, orderBy, asc ? @"ASC" : @"DESC"];
    }
    sql = [NSString stringWithFormat:@"%@ LIMIT :_limit OFFSET :_offset ", sql];
    DLOG(@"sql: %@", sql);

    S3OStatement* stmt = [dbh newStmtWithString:sql];

    NSNumber* limitNum = [NSNumber numberWithInteger:limit ? limit : DEFAULT_LIMIT];
    NSNumber* offsetNum = [NSNumber numberWithInteger:offset];
    [stmt bindParamWithName:@":_limit" value:limitNum];
    [stmt bindParamWithName:@":_offset" value:offsetNum];

    for (NSString* paramName in bindParams) {
        [stmt bindParamWithName:paramName value:[bindParams objectForKey:paramName]];
    }

    NSArray* ret = [stmt newRawsWithClass:self
                              customSetup:^(id obj) {
                                  S3OModel* model = (S3OModel*)obj;
                                  [model addObservers];
                              }];

    [stmt finalize];
    [dbh close];

    return ret;
}

+ (instancetype)loadByPk:(NSNumber*)pk
{
    return [[self alloc] initWithPKValue:pk];
}

@end
