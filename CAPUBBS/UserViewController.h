//
//  UserViewController.h
//  CAPUBBS
//
//  Created by 范志康 on 15/3/15.
//  Copyright (c) 2015年 熊典. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ActionPerformer.h"
#import "MBProgressHUD.h"
#import "AsyncImageView.h"

@interface UserViewController : UITableViewController <UIWebViewDelegate, UIAlertViewDelegate, UIDocumentInteractionControllerDelegate, MFMailComposeViewControllerDelegate> {
    ActionPerformer *performer;
    MBProgressHUD *hud;
    AsyncImageView *backgroundView;
    UIRefreshControl *control;
    NSMutableArray *recentPost;
    NSMutableArray *recentReply;
    NSArray *labels;
    NSArray *webViews;
    NSMutableArray *webData;
    NSString *iconURL;
    NSString *imgPath;
    NSArray *property;
    NSMutableArray *heights;
    UIDocumentInteractionController *dic;
    MFMailComposeViewController *mfc;
}

@property NSString *ID;
@property NSData *iconData;
@property BOOL noRightBarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttoonEdit;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *buttonChat;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *star;
@property (weak, nonatomic) IBOutlet UILabel *rights;
@property (weak, nonatomic) IBOutlet UILabel *sign;
@property (weak, nonatomic) IBOutlet UILabel *hobby;
@property (weak, nonatomic) IBOutlet UILabel *qq;
@property (weak, nonatomic) IBOutlet UIButton *mail;
@property (weak, nonatomic) IBOutlet UILabel *from;
@property (weak, nonatomic) IBOutlet UILabel *regDate;
@property (weak, nonatomic) IBOutlet UILabel *lastDate;
@property (weak, nonatomic) IBOutlet UILabel *post;
@property (weak, nonatomic) IBOutlet UILabel *reply;
@property (weak, nonatomic) IBOutlet UILabel *water;
@property (weak, nonatomic) IBOutlet UILabel *extr;
@property (weak, nonatomic) IBOutlet UIWebView *sig1;
@property (weak, nonatomic) IBOutlet UIWebView *sig2;
@property (weak, nonatomic) IBOutlet UIWebView *sig3;
@property (weak, nonatomic) IBOutlet AsyncImageView *icon;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellReport;
@property (weak, nonatomic) IBOutlet UILabel *labelReport;

@end
