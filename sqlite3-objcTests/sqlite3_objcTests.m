//
//  sqlite3_objcTests.m
//  sqlite3-objcTests
//
//  Created by mconintet on 10/18/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "User.h"
#import "macros.h"

@interface sqlite3_objcTests : XCTestCase

@end

@implementation sqlite3_objcTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testModel
{
    User* user = [[User alloc] initWithPKValue:[NSNumber numberWithInt:1]];
    XCTAssertTrue([user._id intValue] == 1);

    user = [[User alloc] initWithWhereCondition:@"name=:name" bindParams:@{ @":name" : @"name" }];
    XCTAssertTrue([user.name isEqualToString:@"name"]);

    NSNumber* newAge = [NSNumber numberWithInt:[user.age intValue] + 1];
    user.age = newAge;
    [user save];

    user = [[User alloc] initWithPKValue:[NSNumber numberWithInt:1]];
    XCTAssertTrue([user.age isEqualToNumber:newAge]);

    NSArray* users = [User newModelsWithWhereCondition:@"name=:name"
                                            bindParams:@{ @":name" : @"name" }
                                               orderBy:nil
                                                   asc:true
                                                 limit:0
                                                offset:0];
    XCTAssertTrue([users count] == 1);
    user = [users objectAtIndex:0];
    XCTAssertTrue([user.age isEqualToNumber:newAge]);

    users = [User newModelsWithWhereCondition:@"1=1"
                                   bindParams:nil
                                      orderBy:@"_id"
                                          asc:false
                                        limit:2
                                       offset:0];
    XCTAssertTrue([users count] == 2);
    user = [users objectAtIndex:0];
    XCTAssertTrue([user._id intValue] == 3);

    user = [[User alloc] initWithPKValue:[NSNumber numberWithInt:10]];
    DLOG(@"%ld", (long)[user._id integerValue]);
    DLOG(@"%d", (int)([user.name isEqualToString:@""]));
}

//- (void)testPerformanceExample
//{
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
