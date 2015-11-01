//
//  S3ODBHandler.h
//  sqlite3-objc
//
//  Created by mconintet on 10/17/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class S3OStatement;

@interface S3ODBHandler : NSObject
- (instancetype)initWithDBFilePath:(NSString*)dbFilePath;
- (void)close;

- (S3OStatement*)newStmtWithString:(NSString*)stmtStr;

- (NSInteger)errCode;
- (NSString*)errMsg;

- (UInt64)lastInsertRowID;
- (NSInteger)totalChanges;

+ (NSString*)selectStrWithColumns:(NSArray*)columns
                        tableName:(NSString*)tableName;

+ (NSString*)insertStrWithColumns:(NSArray*)columns
                        tableName:(NSString*)tableName;

+ (NSString*)whereStrWithConditions:(NSArray*)conditions;
+ (NSString*)whereNotStrWithConditions:(NSArray*)conditions;

+ (NSString*)updateStrWithColumns:(NSArray*)columns
                        tableName:(NSString*)tableName;
@end

@interface S3OStatement : NSObject
@property (nonatomic, assign, readonly) sqlite3_stmt* stmt;
@property (nonatomic, weak, readonly) S3ODBHandler* dbHandler;

- (instancetype)initWithS3Stmt:(sqlite3_stmt*)stmt dbHandler:(S3ODBHandler*)dbHandler;
- (void)finalize;

- (BOOL)execute;
- (BOOL)executeWithParams:(NSDictionary*)params;

- (NSDictionary*)newRow;
- (BOOL)fetchRowToObj:(NSObject*)obj;
- (id)newRowWithClass:(Class)cls customSetup:(void (^)(id obj))customSetup;
- (NSArray*)newRawsWithClass:(Class)cls customSetup:(void (^)(id obj))customSetup;

- (void)bindParamWithIdx:(NSUInteger)paramIdx value:(id)value;
- (void)bindParamWithName:(NSString*)paramName value:(id)value;
- (void)bindParamWithNameDict:(NSDictionary*)dict;
@end
