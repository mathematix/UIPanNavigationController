//
//  UIImage+GenerateFromView.m
//
//  Created by Mathematix on 2/22/13.
//  Copyright (c) 2013 BadPanda. All rights reserved.
//

#import "UIImage+GenerateFromView.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIImage (GenerateFromView)

+ (UIImage *)imageFromUIView:(UIView *)aView {
    CGSize pageSize = aView.frame.size;
    UIGraphicsBeginImageContextWithOptions(pageSize, aView.opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [aView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
