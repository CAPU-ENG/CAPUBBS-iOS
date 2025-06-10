//
//  ListViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListViewController : CustomTableViewController {
    ActionPerformer *performer;
    ActionPerformer *performerReply;
    NSMutableArray *data;
    NSInteger globalTopCount;
    MBProgressHUD *hud;
    MBProgressHUD *hudSofa;
    NSInteger page;
    int failCount;
    BOOL isFirstTime;
    BOOL isLast;
    BOOL isRobbingSofa;
    BOOL isFastRobSofa;
    NSString *sofaContent;
    NSString *oriTitle;
    NSInteger selectedRow;
}

@property NSString *bid;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonViewOnline;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonSearch;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonBack;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonForward;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonJump;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonAction;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonCompose;

@end
