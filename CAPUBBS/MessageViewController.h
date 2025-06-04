//
//  MessageViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageCell.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface MessageViewController : CustomViewController<UITableViewDelegate, UIAlertViewDelegate> {
    ActionPerformer *performer;
    MBProgressHUD *hud;
    UIRefreshControl *control;
    NSArray *data;
    NSInteger page;
    NSInteger maxPage;
    NSString *chatID;
    BOOL isBackground;
    BOOL isVisible;
    BOOL isFirstTime;
    BOOL messageRefreshing;
    long originalSegment;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentType;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *barFreeSpace;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonPrevious;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonAdd;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonNext;


@end
