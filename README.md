## About

A simple toolkit to make sqlite in Objective-C to be little easier.

## Usage

1. Set your class to inherit from `S3OModel`

  ```objc
  @interface User : S3OModel
  // property name is the same as your column name
  @property (nonatomic, strong) NSNumber* _id;
  @property (nonatomic, strong) NSString* name;
  @property (nonatomic, strong) NSNumber* age;
  @end
  ```

2. Imimplement some required methods in your class

  ```objc

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
      return [[S3ODBHandler alloc] initWithDBFilePath:path];
  }

  @end
  ```

### Some examples

```objc
User* user = [[User alloc] initWithPKValue:[NSNumber numberWithInt:1]];

user = [[User alloc] initWithWhereCondition:@"name=:name" bindParams:@{ @":name" : @"name" }];

NSNumber* newAge = [NSNumber numberWithInt:[user.age intValue] + 1];
user.age = newAge;
[user saveThen:nil];

NSArray* users = [User newModelsWithWhereCondition:@"name=:name"
                                        bindParams:@{ @":name" : @"name" }
                                             limit:0
                                            offset:0];
```

## Installation

```
// in your pod file
pod 'sqlite3-objc', :git => 'https://github.com/mconintet/sqlite3-objc.git'
```

```
// command line
pod install
```