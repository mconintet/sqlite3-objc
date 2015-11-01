//
//  macros.h
//  kiwi
//
//  Created by mconintet on 10/8/15.
//  Copyright © 2015 mconintet. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define DLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DLOG(...)
#endif

#define int2NSNumber(i) [NSNumber numberWithInt:i]

#ifdef DEBUG
#define DLOG_NSData(d)                                                   \
    do {                                                                 \
        NSMutableString* log = [NSMutableString stringWithString:@"[ "]; \
        NSUInteger len = [d length];                                     \
        uint8_t* byts = (uint8_t*)[d bytes];                             \
        for (NSUInteger i = 0; i < len; i++) {                           \
            [log appendFormat:@"%x ", byts[i]];                          \
        }                                                                \
        [log appendString:@"]\n"];                                       \
        NSLog(@"%@", log);                                               \
    } while (0);
#else
#define DLOG_NSData(...)
#endif

#define O_IS_T(v, ID) ([v isKindOfClass:[ID class]])

#define mustOverride() @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%s must be overridden in a subclass/category", __PRETTY_FUNCTION__] userInfo:nil]
#define methodNotImplemented() mustOverride()

#define raiseException(EXP_TYPE, REASON) @throw [NSException exceptionWithName:EXP_TYPE reason:[NSString stringWithFormat:@"%s %@", __PRETTY_FUNCTION__, REASON] userInfo:nil];

#define SuppressPerformSelectorLeakWarning(Stuff)                                                                   \
    do {                                                                                                            \
        _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") Stuff; \
        _Pragma("clang diagnostic pop")                                                                             \
    } while (0)
