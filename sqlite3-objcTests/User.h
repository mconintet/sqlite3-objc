//
//  User.h
//  sqlite3-objc
//
//  Created by mconintet on 10/17/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import "S3OModel.h"

@interface User : S3OModel
@property (nonatomic, strong) NSNumber* _id;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSNumber* age;
@end
