//
//  ChatViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/4/17.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionPerformer.h"
#import "MBProgressHUD.h"
#import "ChatCell.h"

@interface ChatViewController : UITableViewController <UIAlertViewDelegate> {
    ActionPerformer *performer;
    ActionPerformer *performerUser;
    ActionPerformer *performerSend;
    MBProgressHUD *hud;
    AsyncImageView *backgroundView;
    CGFloat width;
    NSArray *data;
    BOOL shouldShowHud;
}

@property NSData *iconData;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonChat;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonInfo;
@property (weak, nonatomic) UITextView *textSend;
@property NSString *ID;
@property BOOL directTalk;
@property BOOL shouldHideInfo;

@end
