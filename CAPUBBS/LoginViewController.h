//
//  LoginViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface LoginViewController : UIViewController<UIAlertViewDelegate, UITableViewDelegate>{
    MBProgressHUD *hud;
    NSArray *news;
    NSString *title;
    ActionPerformer *performer;
    ActionPerformer *performerInfo;
    ActionPerformer *performerUser;
    UIRefreshControl *control;
    NSString *newVerURL;
    BOOL userInfoRefreshing;
}
@property (weak, nonatomic) IBOutlet UITextField *textUid;
@property (weak, nonatomic) IBOutlet UITextField *textPass;
@property (weak, nonatomic) IBOutlet AsyncImageView *iconUser;
@property (weak, nonatomic) IBOutlet UIButton *buttonLogin;
@property (weak, nonatomic) IBOutlet UIButton *buttonRegister;
@property (weak, nonatomic) IBOutlet UIButton *buttonEnter;
@property (weak, nonatomic) IBOutlet UIButton *buttonAddNews;
@property (weak, nonatomic) IBOutlet UITableView *tableview;

+ (void)updateIDSaves;

@end
