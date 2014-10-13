//
//  LoginViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-16.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ActionPerformer.h"

@interface LoginViewController : UIViewController<UIAlertViewDelegate>{
    MBProgressHUD *hud;
    NSArray *news;
    NSString *b;
    NSString *see;
    NSString *title;
    ActionPerformer *performer;
    ActionPerformer *performerLink;
    UINavigationController *navi;
    NSString *tempurl;
}
@property (weak, nonatomic) IBOutlet UITextField *textUid;
@property (weak, nonatomic) IBOutlet UITextField *textPass;
- (IBAction)login:(id)sender;
- (IBAction)gotoMain:(id)sender;
- (IBAction)didEndOnExit:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *link1;
@property (weak, nonatomic) IBOutlet UIButton *link2;
@property (weak, nonatomic) IBOutlet UIButton *link3;
@property (weak, nonatomic) IBOutlet UIButton *link4;
@property (weak, nonatomic) IBOutlet UIButton *link5;
@property (weak, nonatomic) IBOutlet UIButton *link6;
@property (weak, nonatomic) IBOutlet UIButton *link7;
@property (weak, nonatomic) IBOutlet UIButton *link8;
@property (weak, nonatomic) IBOutlet UIButton *buttonEnter;

@end
