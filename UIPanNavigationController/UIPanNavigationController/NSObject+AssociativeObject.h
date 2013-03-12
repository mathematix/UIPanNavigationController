//
//  NSObject+AssociativeObject.h
//
//  Created by Mathematix on 2/22/13.
//  Copyright (c) 2013 BadPanda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (AssociativeObject)

- (id)associativeObjectForKey: (NSString *)key;
- (void)setAssociativeObject: (id)object forKey: (NSString *)key;

@end
