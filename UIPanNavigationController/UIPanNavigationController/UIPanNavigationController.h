//
//  UIPanNavigationController.h
//
//  Created by Mathematix on 2/22/13.
//  Copyright (c) 2013 BadPanda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIPanPopDelegate <NSObject>

- (BOOL)isSupportPanPop;// default is NO;

@end

@interface UIPanNavigationController : UINavigationController

+ (NSString *)snapshotCachePath;

@end
