//
//  S3OModel.h
//  sqlite3-objc
//
//  Created by mconintet on 10/17/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "S3ODBHandler.h"

@interface S3OModel : NSObject
+ (NSString*)tableName;
+ (NSString*)pk;
+ (NSArray*)columns;
+ (S3ODBHandler*)newDBHandler;

+ (NSArray*)newModelsWithWhereCondition:(NSString*)condition
                             bindParams:(NSDictionary*)bindParams
                                orderBy:(NSString*)orderBy
                                    asc:(BOOL)asc
                                  limit:(NSUInteger)limit
                                 offset:(NSInteger)offset;

@property (nonatomic, assign) BOOL isChanged;

- (instancetype)initWithPKValue:(id)pkValue;
- (instancetype)initWithWhereCondition:(NSString*)condition bindParams:(NSDictionary*)bindParams;

- (void)addObservers;

- (BOOL)saveThen:(void (^)(UInt64))then;
@end
