//
//  RegisterViewController.h
//  CAPUBBS
//
//  Created by 熊典 on 14-2-20.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface RegisterViewController : UITableViewController<UIAlertViewDelegate>{
    ActionPerformer *performer;
    ActionPerformer *performerPsd;
    MBProgressHUD *hud;
    NSString *iconURL;
    id firstResp;
}

@property BOOL isEdit;
@property (weak, nonatomic) IBOutlet UITextField *textUid;
@property (weak, nonatomic) IBOutlet UIImageView *imageUidAvailable;
@property (weak, nonatomic) IBOutlet UILabel *labelUidGuide;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellUidGuide;
@property (weak, nonatomic) IBOutlet UILabel *labelPsdGuide;
@property (weak, nonatomic) IBOutlet UITextField *textPsd;
@property (weak, nonatomic) IBOutlet UITextField *textPsdSure;
// @property (weak, nonatomic) IBOutlet UITextField *textCode;
@property (weak, nonatomic) IBOutlet AsyncImageView *icon;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentSex;
@property (weak, nonatomic) IBOutlet UITextField *textQQ;
@property (weak, nonatomic) IBOutlet UITextField *textEmail;
@property (weak, nonatomic) IBOutlet UITextField *textFrom;
@property (weak, nonatomic) IBOutlet UITextField *textHobby;
@property (weak, nonatomic) IBOutlet UITextView *textIntro;
@property (weak, nonatomic) IBOutlet UITextView *textSig;
@property (weak, nonatomic) IBOutlet UITextView *textSig2;
@property (weak, nonatomic) IBOutlet UITextView *textSig3;
+ (BOOL)isValidateEmail:(NSString *)email;

@end
