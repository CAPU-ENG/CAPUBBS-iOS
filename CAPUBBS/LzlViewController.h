//
//  LzlViewController.h
//  CAPUBBS
//
//  Created by XiongDian on 14/9/21.
//  Copyright (c) 2014年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActionPerformer.h"
#import "MBProgressHUD.h"
#import "LzlCell.h"

@interface LzlViewController : UITableViewController<UIAlertViewDelegate, UITextViewDelegate> {
    ActionPerformer *performer;
    UIImageView *backgroundView;
    NSUserActivity *activity;
    NSArray *data;
    MBProgressHUD *hud;
    NSString *lzlUrl;
    NSString *lzlText;
    NSString *lzlAuthor;
    BOOL shouldShowHud;
}

@property NSString *fid;
@property NSURL *URL;
@property UITextView *textPost;
@property UILabel *labelByte;

@end
