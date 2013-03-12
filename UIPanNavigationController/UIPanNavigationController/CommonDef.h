//
//  CommonDef.h
//  
//  Created by Mathematix on 2/22/13.
//  Copyright (c) 2013 BadPanda. All rights reserved.
//

#import <UIKit/UIKit.h>

// define some macros
#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#define BP_ARC_ENABLED 1
#endif // __has_feature(objc_arc)

#if BP_ARC_ENABLED
#define BP_RETAIN(xx) (xx)
#define BP_RELEASE(xx)  xx = nil
#define BP_AUTORELEASE(xx)  (xx)
#else
#define BP_RETAIN(xx)           [xx retain]
#define BP_RELEASE(xx)          [xx release], xx = nil
#define BP_AUTORELEASE(xx)      [xx autorelease]
#endif

#ifndef BPRSLog
#if DEBUG
# define BPRSLog(fmt, ...) NSLog((@"%s [Line %d] " fmt),__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define BPRSLog(fmt, ...)
#endif
#endif

#define BPSystemVersionGreaterOrEqualThan(version) ([[[UIDevice currentDevice] systemVersion] floatValue] >= version)
