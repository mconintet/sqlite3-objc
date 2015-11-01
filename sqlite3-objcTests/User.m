//
//  User.m
//  sqlite3-objc
//
//  Created by mconintet on 10/17/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "User.h"
#import "S3ODBHandler.h"
#import "macros.h"

@implementation User
+ (NSString*)tableName
{
    return @"user";
}

+ (NSString*)pk
{
    return @"_id";
}

+ (NSArray*)columns
{
    return @[
        @"_id",
        @"name",
        @"age"
    ];
}

+ (S3ODBHandler*)newDBHandler
{
    NSBundle* bundle = [NSBundle bundleForClass:[self class]];
    NSString* path = [bundle pathForResource:@"test" ofType:@"sqlite"];
    DLOG(@"db path: %@", path);
    return [[S3ODBHandler alloc] initWithDBFilePath:path];
}

@end
