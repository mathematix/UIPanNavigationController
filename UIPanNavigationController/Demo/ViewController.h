//
//  ViewController.h
//
//  Created by Mathematix on 3/12/13.
//  Copyright (c) 2013 BadPanda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,retain) IBOutlet UILabel *titleLabel;
@property (nonatomic,retain) IBOutlet UITableView *tableView;

- (IBAction)push:(id)sender;
- (IBAction)pop:(id)sender;

@end
