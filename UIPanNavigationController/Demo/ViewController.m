//
//  ViewController.m
//
//  Created by Mathematix on 3/12/13.
//  Copyright (c) 2013 BadPanda. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize titleLabel;
@synthesize tableView = _tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.canCancelContentTouches = YES;
    [self.view addSubview:_tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.titleLabel.text = [NSString stringWithFormat:@"count: %d",self.navigationController.viewControllers.count];
    self.title = [NSString stringWithFormat:@"Level: %d",self.navigationController.viewControllers.count];
}

- (BOOL)isSupportPanPop {
    return YES;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"1";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = BP_AUTORELEASE([[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier]);
        cell.multipleTouchEnabled = false;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d",indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.navigationController.topViewController == self) {
        [self push:nil];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)push:(id)sender {
    ViewController *vc = [[ViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    BP_RELEASE(vc);
}


- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
