//
//  UIPanNavigationController.m
//
//  Created by Mathematix on 2/22/13.
//  Copyright (c) 2013 BadPanda. All rights reserved.
//

#import <objc/message.h>
#import <objc/runtime.h>

#import "UIPanNavigationController.h"
#import "UIImage+GenerateFromView.h"
#import "NSObject+AssociativeObject.h"
#import <QuartzCore/QuartzCore.h>

#define CACHE_IN_MEMORY         1
#define kPushAnimationDuration  0.4
#define kOverlayViewAlpha       0.5
#define kTransformScale         0.95
#define kBoundaryWidthRatio     0.25
#define kMinThreshold           100


static NSString *const snapShotKey = @"snapShotKey";
static NSString *const snapShotViewKey = @"snapShotViewKey";

@interface UIPanNavigationController ()<UIGestureRecognizerDelegate>

@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UIView *overlayView;
@property (nonatomic, retain) UIImageView *leftSnapshotView;
@property (nonatomic, retain) UIImageView *centerSnapshotView;


- (BOOL)isNeedPanResponse;
- (void)shresholdJudge;

- (NSString *)snapshotPathForController:(UIViewController *)controller;

- (void)touchesBegan;
- (void)touchesEnded;
- (void)touchesMovedWithPanGesture:(UIPanGestureRecognizer *)gestureRecognizer;

- (IBAction)handlePan:(UIPanGestureRecognizer *)gestureRecognizer;

@end

@implementation UIPanNavigationController

@synthesize backgroundView = _backgroundView;
@synthesize overlayView = _overlayView;
@synthesize leftSnapshotView = _leftSnapshotView;
@synthesize centerSnapshotView = _centerSnapshotView;

+ (NSString *)snapshotCachePath {
    return [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/PopSnapshots"];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.maximumNumberOfTouches = 1;
    panGesture.minimumNumberOfTouches = 1;
    panGesture.cancelsTouchesInView = YES;
    panGesture.delegate = self;
    [self.view addGestureRecognizer:panGesture];
    BP_RELEASE(panGesture);
}


- (void)loadView {
    [super loadView];
    
    _backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _backgroundView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_backgroundView];
    
    _overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    _overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _overlayView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_overlayView];
    
    _leftSnapshotView = [[UIImageView alloc] initWithFrame:self.view.frame];
    _leftSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:_leftSnapshotView];
    
    _centerSnapshotView = [[UIImageView alloc] initWithFrame:self.view.frame];
    _centerSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _centerSnapshotView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_centerSnapshotView.bounds cornerRadius:0.0f].CGPath;
    _centerSnapshotView.layer.shadowColor = [UIColor blackColor].CGColor;
    _centerSnapshotView.layer.shadowOpacity = 0.65f;
    _centerSnapshotView.layer.shadowRadius = 5.0f;
    _centerSnapshotView.layer.shadowOffset = CGSizeMake(0.0f, 0);
    _centerSnapshotView.clipsToBounds = NO;
    [self.view addSubview:_centerSnapshotView];
    [self hideMaskViews:YES];
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {

    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan)
    {
        [self.view endEditing:YES];
        [self touchesBegan];
    }
    else if ([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        [self touchesMovedWithPanGesture:gestureRecognizer];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded
               || gestureRecognizer.state == UIGestureRecognizerStateFailed
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled
               || gestureRecognizer.state == UIGestureRecognizerStateCancelled)
    {
        [self touchesEnded];
    }
    
}

#pragma mark -
#pragma mark - Push Action
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self.viewControllers count]> 0 && [viewController respondsToSelector:@selector(isSupportPanPop)]) {
        BOOL returnValue = ((BOOL (*)(id, SEL))objc_msgSend)(viewController, @selector(isSupportPanPop));
        if (returnValue) {
            UIImage *image = nil;
			if (self.tabBarController != nil) {
				image = [UIImage imageFromUIView:self.tabBarController.view];
			}
			else {
				image = [UIImage imageFromUIView:self.view];
            }
            //every controller should maintain its own snapshot
            [self saveSnapshot:image forViewController:self.topViewController];
        }
    }
    
    [super pushViewController:viewController animated:animated];
}


- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    [self removeSnapshotForViewController:self.topViewController];
    UIViewController* controller = [super popViewControllerAnimated:animated];
    [self removeSnapshotForViewController:controller];
    return controller;
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray *popedController = [super popToViewController:viewController animated:animated];
    for (UIViewController *vc in popedController) {
        [self removeSnapshotForViewController:vc];
    }
    [self removeSnapshotForViewController:self.topViewController];
    return popedController;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray *popedController = [super popToRootViewControllerAnimated:animated];
    for (UIViewController *vc in popedController) {
        [self removeSnapshotForViewController:vc];
    }
    [self removeSnapshotForViewController:self.topViewController];
    return popedController;
}


#pragma mark - 
#pragma mark - Touch Action
- (void)touchesBegan {
    NSInteger topControllerIndex = [self.viewControllers indexOfObject:self.topViewController];
    if (topControllerIndex == 0)
        return;
    
    [self.topViewController.view setHidden:YES];
    
    UIViewController* leftController = [self.viewControllers objectAtIndex: topControllerIndex-1];
    UIImage* leftImage = [self snapshotForViewController:leftController];
    UIImage* centerImage = [self snapshotForViewController:self.topViewController];
    
    [self showMaskViewsWithImageLeft:leftImage imageCenter:centerImage];
    [self maskViewConfigWithScale:kTransformScale left:0 alpha:kOverlayViewAlpha];
}

- (void)touchesEnded {
    
    [self.topViewController.view setHidden:NO];
    
    if (![self isNeedPanResponse])
        return;
    
    [self shresholdJudge];
}

- (void)touchesMovedWithPanGesture:(UIPanGestureRecognizer *)gestureRecognizer {

    CGPoint point = [gestureRecognizer translationInView:self.view];
    CGRect frame = _centerSnapshotView.frame;
    frame.origin.x = point.x > 0 ? point.x : 0;
    CGFloat scale = kTransformScale + (1 - kTransformScale) / self.view.frame.size.width * frame.origin.x;
    CGFloat alpha = kOverlayViewAlpha - kOverlayViewAlpha / self.view.frame.size.width * frame.origin.x;
    
    _centerSnapshotView.frame = frame;
    _overlayView.alpha = alpha;
    _leftSnapshotView.transform = CGAffineTransformMakeScale(scale, scale);
}


#pragma mark -
- (void)maskViewConfigWithScale:(CGFloat)scale
                           left:(CGFloat)left
                          alpha:(CGFloat)alpha {
    CGRect frame = _centerSnapshotView.frame;
    frame.origin.x = left;
    
    _leftSnapshotView.transform = CGAffineTransformMakeScale(scale, scale);
    _centerSnapshotView.frame = frame;
    _overlayView.alpha = alpha;
}

- (void)showMaskViewsWithImageLeft:(UIImage *)imageLeft imageCenter:(UIImage *)imageCenter {
    _leftSnapshotView.image = imageLeft;
    _centerSnapshotView.image = imageCenter;
    
    [self hideMaskViews:NO];
    [self.view bringSubviewToFront:_backgroundView];
    [self.view bringSubviewToFront:_leftSnapshotView];
    [self.view bringSubviewToFront:_overlayView];
    [self.view bringSubviewToFront:_centerSnapshotView];
}

- (void)hideMaskViews:(BOOL)hide {
    _backgroundView.hidden = hide;
    _overlayView.hidden = hide;
    _leftSnapshotView.hidden = hide;
    _centerSnapshotView.hidden = hide;
    
    if (hide)
    {
        _leftSnapshotView.image = nil;
        _centerSnapshotView.image = nil;
    }
}

#pragma mark -
- (BOOL)isNeedPanResponse {
    if ([self.topViewController respondsToSelector:@selector(isSupportPanPop)]) {
        BOOL returnValue = ((BOOL (*)(id, SEL))objc_msgSend)(self.topViewController, @selector(isSupportPanPop));
        if (!returnValue)
        {
            return NO;
        }
    }
    
    if (self.viewControllers.count <= 1)
    {
        return NO;
    }
    
    return YES;
}


- (void)shresholdJudge {
    
    BOOL x = CGRectGetMinX(_centerSnapshotView.frame) > kMinThreshold;
    //BOOL x = _centerSnapshotView.frame.origin.x > _leftSnapshotView.frame.size.width * kBoundaryWidthRatio;
    [UIView animateWithDuration:kPushAnimationDuration animations:^{
        CGFloat left  = x ? self.view.frame.size.width : 0;
        CGFloat scale = x ? 1 : kTransformScale;
        CGFloat alpha = x ? 0 : kOverlayViewAlpha;
        [self maskViewConfigWithScale:scale left:left alpha:alpha];
    } completion:^(BOOL finished) {
        [self hideMaskViews:YES];
        if (x)
        {
            [self popViewControllerAnimated:NO];
        }
    }];
}

#pragma mark - 
#pragma mark - snapshot
- (void)saveSnapshot:(UIImage *)image forViewController:(UIViewController *)controller {
#if CACHE_IN_MEMORY
    [controller setAssociativeObject:image forKey:snapShotKey];    
#else
    NSString *snapshotPath = [self snapshotPathForController:controller];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:[UIPanNavigationController snapshotCachePath] isDirectory:NULL]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[UIPanNavigationController snapshotCachePath] withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:snapshotPath atomically:YES];
#endif
}

- (UIImage *)snapshotForViewController:(UIViewController *)controller {
#if CACHE_IN_MEMORY
    return [controller associativeObjectForKey:snapShotKey];
#else
    NSString *snapshotPath = [self snapshotPathForController:controller];
    UIImage *image = [UIImage imageWithContentsOfFile:snapshotPath];
    return image;
#endif

}

- (void)removeSnapshotForViewController:(UIViewController *)controller {
    self.leftSnapshotView.hidden = YES;
    
#if CACHE_IN_MEMORY
    UIImage *image = [controller associativeObjectForKey:snapShotKey];
    if (image) {
        [controller setAssociativeObject:nil forKey:snapShotKey];
    }
#else
    NSString *snapshotPath = [self snapshotPathForController:controller];
    [[NSFileManager defaultManager] removeItemAtPath:snapshotPath error:nil];
#endif

}

- (NSString *)snapshotPathForController:(UIViewController *)controller {
    NSString *snapshotPath = [[UIPanNavigationController snapshotCachePath] stringByAppendingFormat:@"/<%p>.png",controller,nil];
    return snapshotPath;
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (![self isNeedPanResponse]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
    {

        if ([touch.view isKindOfClass:[UITableViewCell class]]) {
            return NO;
        }
        
        if (![self isNeedPanResponse]) {
            return NO;
        }
        
        if ([self.topViewController.view isKindOfClass:[UITableView class]]) {
            UITableView* tableView = (UITableView*) self.topViewController.view;
            if([tableView isDecelerating]||[tableView isDragging])
                return NO;
        }
        
        for (UIView *subview in self.topViewController.view.subviews)
        {
            if ([subview isKindOfClass:[UITableView class]]) {
                UITableView* tableView = (UITableView*) subview;
                if([tableView isDecelerating]||[tableView isDragging])
                    return NO;
            }
        }
        
        UIImage *image = [UIImage imageFromUIView:self.view];
        [self saveSnapshot:image forViewController:self.topViewController];
        
        return YES;
}


#pragma mark -
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
