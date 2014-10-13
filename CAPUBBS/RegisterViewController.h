//
//  RegisterViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ActionPerformer.h"

@interface RegisterViewController : UITableViewController<UIAlertViewDelegate>{
    ActionPerformer *performer;
    MBProgressHUD *hud;
    id firstResp;
}
@property (weak, nonatomic) IBOutlet UITextField *textUid;
@property (weak, nonatomic) IBOutlet UITextField *textPsd;
@property (weak, nonatomic) IBOutlet UITextField *textPsdSure;
@property (weak, nonatomic) IBOutlet UITextField *textCode;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentSex;
@property (weak, nonatomic) IBOutlet UITextField *textQQ;
@property (weak, nonatomic) IBOutlet UITextField *textEMail;
@property (weak, nonatomic) IBOutlet UITextField *textFrom;
@property (weak, nonatomic) IBOutlet UITextField *textIntro;
@property (weak, nonatomic) IBOutlet UITextField *textSig;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)didEndOnExit:(id)sender;

@end
