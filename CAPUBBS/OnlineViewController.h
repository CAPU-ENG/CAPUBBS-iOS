//
//  OnlineViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/5/14.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OnlineViewCell.h"
#import "ActionPerformer.h"
#import "MBProgressHUD.h"

@interface OnlineViewController : UITableViewController {
    NSMutableArray *data;
    MBProgressHUD *hud;
}

@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonViewMore;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonStat;

@end
