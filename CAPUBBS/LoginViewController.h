//
//  LoginViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnimatedImageView.h"

@interface LoginViewController : CustomViewController<UITableViewDelegate> {
    MBProgressHUD *hud;
    NSArray *news;
    NSString *title;
    ActionPerformer *performer;
    ActionPerformer *performerInfo;
    ActionPerformer *performerUser;
    UIRefreshControl *control;
    BOOL userInfoRefreshing;
    BOOL newsRefreshing;
}
@property (weak, nonatomic) IBOutlet UITextField *textUid;
@property (weak, nonatomic) IBOutlet UITextField *textPass;
@property (weak, nonatomic) IBOutlet AnimatedImageView *iconUser;
@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;
@property (weak, nonatomic) IBOutlet UIButton *buttonRegister;
@property (weak, nonatomic) IBOutlet UIButton *buttonEnter;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddNews;
@property (weak, nonatomic) IBOutlet UITableView *tableview;

+ (void)updateIDSaves;

@end
